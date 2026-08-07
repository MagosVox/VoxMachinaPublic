#!/bin/bash
# ==========================================================================
# TagLib Cross-Compilation for Android arm64-v8a
# Vox Machina Secundus — LGPL 2.1 (elected) build + relink recipe
#
# This script is published to satisfy LGPL 2.1 Section 6(a) for the taglib
# library bundled in the Vox Machina application.
#
# Unlike FFmpeg (which ships UNMODIFIED as its own separate shared objects
# and is therefore discharged under §6(b) by pointing at upstream), the
# taglib copy in Vox Machina is:
#
#   1. MODIFIED — one file, kyant_wrapper/fileref_ext.cpp, carries a Vox
#      Machina patch (see source/taglib/patches/), so upstream alone is no
#      longer the corresponding source; the patch is published alongside.
#   2. STATICALLY archived into a combined shared object,
#      libvoxmachina_taglib.so, that also contains Vox Machina's own JNI
#      bridge. taglib is NOT a separately replaceable .so here.
#
# Because of (2) the discharge is §6(a), not §6(b): this script rebuilds
# taglib from complete corresponding source (upstream v2.3.1 + the Vox
# Machina patch), producing the exact static library the app links. The
# Vox-Machina-authored object code needed to relink the *combined*
# libvoxmachina_taglib.so (the "work that uses the Library") is available
# on request — see source/taglib/README.md.
#
# Prerequisites:
#   - Linux or WSL with: git, make, cmake OR a plain compiler, patch
#   - Android NDK 28+ (set ANDROID_NDK_HOME)
#
# Usage:
#   export ANDROID_NDK_HOME=/path/to/ndk/28.2.13676358
#   ./build_taglib_android.sh
#
# Output:
#   output/arm64-v8a/libvox_taglib_core.a  — static library (as linked by the app)
#
# LGPL 2.1 compliance:
#   - Complete corresponding source: upstream v2.3.1 (pinned below) + the
#     published patch + the published taglib_config.h format surface.
#   - §6(a) relink path: this script + the object-code offer in the README.
#   - LGPL 2.1 elected over the MPL 1.1 half of taglib's dual license.
# ==========================================================================

set -euo pipefail

# --- Configuration ---
# Upstream taglib, RE-PINNED to the latest reachable stable tag. The Kyant0
# fork's own submodule pin is unreachable/pruned from taglib/taglib upstream;
# see source/taglib/README.md "Provenance" for the four-way verification.
TAGLIB_VERSION="v2.3.1"
# taglib's own pinned utf8-cpp dependency (v2.3.1 .gitmodules), reachable.
UTFCPP_COMMIT="819011bb01628fe1aa2f1da9f2c842a48fd5680b"
# Kyant0 Android wrapper (IOStream-constructible FileRef variant); we take
# ONLY fileref_ext.{h,cpp} from it, then apply the Vox Machina patch.
KYANT_VERSION="1.0.6"
KYANT_COMMIT="957fd7c2794457a14c1484fa3e3b58382aca4202"

API_LEVEL=35
ABI="arm64-v8a"
TARGET="aarch64-linux-android"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="${TAGLIB_SRC:-$SCRIPT_DIR/taglib-src}"
OUTPUT_DIR="$SCRIPT_DIR/output/$ABI"
PATCH="$SCRIPT_DIR/source/taglib/patches/0001-voxmachina-format-surface-ifdef-guards.patch"
CONFIG_H="$SCRIPT_DIR/source/taglib/taglib_config.h"

# --- NDK toolchain ---
if [ -z "${ANDROID_NDK_HOME:-}" ]; then
    echo "ERROR: ANDROID_NDK_HOME not set"
    echo "Example: export ANDROID_NDK_HOME=/path/to/ndk/28.2.13676358"
    exit 1
fi
TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64"
CXX="$TOOLCHAIN/bin/${TARGET}${API_LEVEL}-clang++"
AR="$TOOLCHAIN/bin/llvm-ar"
if [ ! -f "$CXX" ]; then
    echo "ERROR: Compiler not found at $CXX"
    echo "Check ANDROID_NDK_HOME and API_LEVEL ($API_LEVEL)"
    exit 1
fi

echo "=== TagLib Android Build (Vox Machina, LGPL 2.1) ==="
echo "NDK:        $ANDROID_NDK_HOME"
echo "API:        $API_LEVEL"
echo "ABI:        $ABI"
echo "taglib:     $TAGLIB_VERSION"
echo "utfcpp:     $UTFCPP_COMMIT"
echo "kyant wrap: $KYANT_VERSION ($KYANT_COMMIT)"
echo ""

# --- Fetch complete corresponding source ---
if [ ! -d "$SRC" ]; then
    echo "Cloning upstream taglib $TAGLIB_VERSION..."
    git clone --depth 1 --branch "$TAGLIB_VERSION" \
        https://github.com/taglib/taglib.git "$SRC"

    echo "Fetching utf8-cpp ($UTFCPP_COMMIT)..."
    git clone https://github.com/nemtrif/utfcpp.git "$SRC/3rdparty/utfcpp"
    git -C "$SRC/3rdparty/utfcpp" checkout --quiet "$UTFCPP_COMMIT"

    echo "Fetching Kyant0 wrapper FileRef variant ($KYANT_VERSION)..."
    RAW="https://raw.githubusercontent.com/Kyant0/taglib/$KYANT_COMMIT/src/main/cpp"
    curl -sSL "$RAW/fileref_ext.h"   -o "$SRC/fileref_ext.h"
    curl -sSL "$RAW/fileref_ext.cpp" -o "$SRC/fileref_ext.cpp"

    echo "Applying Vox Machina format-surface patch..."
    # Patch is a/fileref_ext.cpp ; the file sits at $SRC root here (-p1).
    patch -p1 -d "$SRC" < "$PATCH"

    echo "Installing hand-authored taglib_config.h..."
    cp "$CONFIG_H" "$SRC/taglib_config.h"
fi

# --- Cherry-picked format surface (campaign §6 G5) ---
# Compiled IN : MPEG/ID3v1/ID3v2 (core), Ogg/Vorbis/FLAC/Speex/Opus
#               (WITH_VORBIS), APE/Musepack/WavPack (WITH_APE), MP4 (WITH_MP4).
# Compiled OUT: ASF, DSF/DSDIFF, Matroska, tracker modules, RIFF/WAV/AIFF,
#               Shorten, TrueAudio. Enforced by taglib_config.h (undefined
#               TAGLIB_WITH_* guards) AND by omission from the source list.
T="$SRC/taglib"
SOURCES=(
    # Core (no WITH_ flag)
    tag.cpp fileref.cpp audioproperties.cpp tagunion.cpp tagutils.cpp
    toolkit/tbytevector.cpp toolkit/tbytevectorlist.cpp toolkit/tbytevectorstream.cpp
    toolkit/tdebug.cpp toolkit/tdebuglistener.cpp toolkit/tfile.cpp
    toolkit/tfilestream.cpp toolkit/tiostream.cpp toolkit/tpicturetype.cpp
    toolkit/tpropertymap.cpp toolkit/tstring.cpp toolkit/tstringlist.cpp
    toolkit/tvariant.cpp toolkit/tversionnumber.cpp toolkit/tzlib.cpp
    mpeg/mpegfile.cpp mpeg/mpegheader.cpp mpeg/mpegproperties.cpp mpeg/xingheader.cpp
    mpeg/id3v1/id3v1genres.cpp mpeg/id3v1/id3v1tag.cpp
    mpeg/id3v2/id3v2extendedheader.cpp mpeg/id3v2/id3v2footer.cpp
    mpeg/id3v2/id3v2frame.cpp mpeg/id3v2/id3v2framefactory.cpp
    mpeg/id3v2/id3v2header.cpp mpeg/id3v2/id3v2synchdata.cpp mpeg/id3v2/id3v2tag.cpp
    mpeg/id3v2/frames/attachedpictureframe.cpp mpeg/id3v2/frames/chapterframe.cpp
    mpeg/id3v2/frames/commentsframe.cpp mpeg/id3v2/frames/eventtimingcodesframe.cpp
    mpeg/id3v2/frames/generalencapsulatedobjectframe.cpp mpeg/id3v2/frames/ownershipframe.cpp
    mpeg/id3v2/frames/podcastframe.cpp mpeg/id3v2/frames/popularimeterframe.cpp
    mpeg/id3v2/frames/privateframe.cpp mpeg/id3v2/frames/relativevolumeframe.cpp
    mpeg/id3v2/frames/synchronizedlyricsframe.cpp mpeg/id3v2/frames/tableofcontentsframe.cpp
    mpeg/id3v2/frames/textidentificationframe.cpp mpeg/id3v2/frames/uniquefileidentifierframe.cpp
    mpeg/id3v2/frames/unknownframe.cpp mpeg/id3v2/frames/unsynchronizedlyricsframe.cpp
    mpeg/id3v2/frames/urllinkframe.cpp
    # WITH_VORBIS
    ogg/oggfile.cpp ogg/oggpage.cpp ogg/oggpageheader.cpp ogg/xiphcomment.cpp
    ogg/vorbis/vorbisfile.cpp ogg/vorbis/vorbisproperties.cpp ogg/flac/oggflacfile.cpp
    ogg/speex/speexfile.cpp ogg/speex/speexproperties.cpp
    ogg/opus/opusfile.cpp ogg/opus/opusproperties.cpp
    flac/flacfile.cpp flac/flacmetadatablock.cpp flac/flacpicture.cpp
    flac/flacproperties.cpp flac/flacunknownmetadatablock.cpp
    # WITH_APE (APE tag + Musepack + WavPack)
    ape/apefile.cpp ape/apefooter.cpp ape/apeitem.cpp ape/apeproperties.cpp ape/apetag.cpp
    mpc/mpcfile.cpp mpc/mpcproperties.cpp
    wavpack/wavpackfile.cpp wavpack/wavpackproperties.cpp
    # WITH_MP4
    mp4/mp4atom.cpp mp4/mp4chapter.cpp mp4/mp4coverart.cpp mp4/mp4file.cpp
    mp4/mp4item.cpp mp4/mp4itemfactory.cpp mp4/mp4nerochapterlist.cpp
    mp4/mp4properties.cpp mp4/mp4qtchapterlist.cpp mp4/mp4stem.cpp mp4/mp4tag.cpp
)

INCLUDES=(
    -I"$T" -I"$T/toolkit" -I"$T/mpeg" -I"$T/mpeg/id3v1" -I"$T/mpeg/id3v2"
    -I"$T/mpeg/id3v2/frames" -I"$T/ogg" -I"$T/ogg/vorbis" -I"$T/ogg/flac"
    -I"$T/ogg/speex" -I"$T/ogg/opus" -I"$T/flac" -I"$T/ape" -I"$T/mpc"
    -I"$T/wavpack" -I"$T/mp4" -I"$SRC/3rdparty/utfcpp/source" -I"$SRC"
)

# Compile flags mirror the app's vox_taglib_core target exactly.
CXXFLAGS=(-std=c++17 -O2 -fPIC -fvisibility=hidden -fvisibility-inlines-hidden
          -DHAVE_CONFIG_H -DTAGLIB_STATIC -DHAVE_ZLIB=1)

BUILD="$SCRIPT_DIR/build-$ABI"
rm -rf "$BUILD"; mkdir -p "$BUILD" "$OUTPUT_DIR"

echo "Compiling ${#SOURCES[@]} taglib sources + the patched Kyant0 FileRef variant..."
OBJS=()
compile() {
    local src="$1" obj="$2"
    "$CXX" "${CXXFLAGS[@]}" "${INCLUDES[@]}" -c "$src" -o "$obj"
    OBJS+=("$obj")
}
i=0
for s in "${SOURCES[@]}"; do
    compile "$T/$s" "$BUILD/obj_$((i++)).o"
done
# The single Vox-Machina-patched file (LGPL/MPL, patch published):
compile "$SRC/fileref_ext.cpp" "$BUILD/obj_fileref_ext.o"

echo "Archiving static library..."
"$AR" rcs "$OUTPUT_DIR/libvox_taglib_core.a" "${OBJS[@]}"

echo ""
echo "=== Build Complete ==="
echo "Static library: $OUTPUT_DIR/libvox_taglib_core.a"
ls -lh "$OUTPUT_DIR/libvox_taglib_core.a"
echo ""
echo "This is the exact taglib static library the app archives into"
echo "libvoxmachina_taglib.so. To relink the COMBINED shared object against a"
echo "modified taglib, this .a is linked with the Vox Machina JNI bridge object"
echo "code (the 'work that uses the Library'), available on request per LGPL"
echo "2.1 §6(a) — see source/taglib/README.md."
echo ""
echo "LGPL 2.1 compliance: complete corresponding source published"
echo "  - upstream taglib $TAGLIB_VERSION (pinned, cloned above)"
echo "  - Vox Machina patch: source/taglib/patches/"
echo "  - format surface:    source/taglib/taglib_config.h"
echo "  - relink recipe:     $0"
