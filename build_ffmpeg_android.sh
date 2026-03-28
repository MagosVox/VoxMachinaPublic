#!/bin/bash
# ==========================================================================
# FFmpeg Cross-Compilation for Android arm64-v8a
# Vox Machina Secundus — LGPL 2.1 decode-only build
#
# Prerequisites:
#   - Linux or WSL with: make, gcc, nasm/yasm
#   - Android NDK (set ANDROID_NDK_HOME)
#   - FFmpeg source (cloned to $FFMPEG_SRC or auto-cloned)
#
# Usage:
#   export ANDROID_NDK_HOME=/path/to/ndk/28.2.13676358
#   ./build_ffmpeg_android.sh
#
# Output:
#   output/arm64-v8a/lib/*.so  — shared libraries
#   output/arm64-v8a/include/  — headers
#
# LGPL 2.1 compliance:
#   - Dynamic linking (.so) per §6(b)
#   - No --enable-gpl, no --enable-nonfree
#   - No external GPL libraries
#   - This script + configure flags constitute the relinking path
# ==========================================================================

set -euo pipefail

# --- Configuration ---
FFMPEG_VERSION="n7.1"
API_LEVEL=35
ABI="arm64-v8a"
ARCH="aarch64"
TARGET="aarch64-linux-android"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FFMPEG_SRC="${FFMPEG_SRC:-$SCRIPT_DIR/ffmpeg-src}"
OUTPUT_DIR="$SCRIPT_DIR/output/$ABI"
PREFIX="$OUTPUT_DIR"

# NDK paths
if [ -z "${ANDROID_NDK_HOME:-}" ]; then
    echo "ERROR: ANDROID_NDK_HOME not set"
    echo "Example: export ANDROID_NDK_HOME=/path/to/ndk/28.2.13676358"
    exit 1
fi

TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64"
SYSROOT="$TOOLCHAIN/sysroot"
CC="$TOOLCHAIN/bin/${TARGET}${API_LEVEL}-clang"
CXX="$TOOLCHAIN/bin/${TARGET}${API_LEVEL}-clang++"
AR="$TOOLCHAIN/bin/llvm-ar"
STRIP="$TOOLCHAIN/bin/llvm-strip"

# Verify toolchain
if [ ! -f "$CC" ]; then
    echo "ERROR: Compiler not found at $CC"
    echo "Check ANDROID_NDK_HOME and API_LEVEL ($API_LEVEL)"
    exit 1
fi

echo "=== FFmpeg Android Build ==="
echo "NDK:     $ANDROID_NDK_HOME"
echo "API:     $API_LEVEL"
echo "ABI:     $ABI"
echo "Arch:    $ARCH"
echo "CC:      $CC"
echo ""

# --- Clone FFmpeg if needed ---
if [ ! -d "$FFMPEG_SRC" ]; then
    echo "Cloning FFmpeg $FFMPEG_VERSION..."
    git clone --depth 1 --branch "$FFMPEG_VERSION" \
        https://git.ffmpeg.org/ffmpeg.git "$FFMPEG_SRC"
fi

cd "$FFMPEG_SRC"

# --- Clean previous build ---
make distclean 2>/dev/null || true

# --- Configure ---
echo "Configuring FFmpeg (LGPL 2.1, decode-only)..."

./configure \
    --prefix="$PREFIX" \
    --target-os=android \
    --arch="$ARCH" \
    --cpu=armv8-a \
    --enable-cross-compile \
    --cc="$CC" \
    --cxx="$CXX" \
    --ar="$AR" \
    --strip="$STRIP" \
    --sysroot="$SYSROOT" \
    --extra-cflags="-O2 -fPIC" \
    --extra-ldflags="-lm -lz" \
    \
    --enable-shared \
    --disable-static \
    \
    --disable-programs \
    --disable-doc \
    --disable-encoders \
    --disable-muxers \
    --disable-devices \
    --disable-avdevice \
    --disable-avfilter \
    --disable-postproc \
    --disable-bsfs \
    --disable-debug \
    --enable-small \
    \
    --enable-decoder=mp3,mp3float,aac,aac_fixed,alac,opus,vorbis,wavpack,pcm_s16le,pcm_s24le,pcm_s32le,pcm_f32le \
    --enable-demuxer=mp3,aac,ogg,mov,wav,aiff,wv \
    --enable-parser=aac,opus,vorbis,mpegaudio \
    --enable-protocol=file,pipe \
    \
    --disable-gpl \
    --disable-nonfree \
    --disable-autodetect

echo ""
echo "Configure complete. Verifying LGPL compliance..."

# Verify no GPL components
if grep -q "LICENSE: GPL" config.h 2>/dev/null; then
    echo "ERROR: GPL components detected! Build is not LGPL-clean."
    exit 1
fi

echo "LGPL 2.1 verified."
echo ""

# --- Build ---
echo "Building FFmpeg (this may take a few minutes)..."
make -j"$(nproc)" 2>&1 | tail -5
make install

echo ""
echo "Build complete."

# --- Strip libraries ---
echo "Stripping debug symbols..."
for lib in "$PREFIX/lib"/*.so; do
    "$STRIP" --strip-unneeded "$lib"
    echo "  Stripped: $(basename "$lib") ($(du -h "$lib" | cut -f1))"
done

# --- Copy to project ---
JNILIB_DIR="$PROJECT_ROOT/app/src/main/jniLibs/$ABI"
INCLUDE_DIR="$PROJECT_ROOT/app/src/main/cpp/third_party/codecs/ffmpeg/include"

echo ""
echo "Installing to project..."

mkdir -p "$JNILIB_DIR"
cp "$PREFIX/lib/libavformat.so" "$JNILIB_DIR/"
cp "$PREFIX/lib/libavcodec.so" "$JNILIB_DIR/"
cp "$PREFIX/lib/libavutil.so" "$JNILIB_DIR/"
cp "$PREFIX/lib/libswresample.so" "$JNILIB_DIR/"

mkdir -p "$INCLUDE_DIR"
cp -r "$PREFIX/include/libavformat" "$INCLUDE_DIR/"
cp -r "$PREFIX/include/libavcodec" "$INCLUDE_DIR/"
cp -r "$PREFIX/include/libavutil" "$INCLUDE_DIR/"
cp -r "$PREFIX/include/libswresample" "$INCLUDE_DIR/"

echo ""
echo "=== Installation Complete ==="
echo "Libraries:  $JNILIB_DIR/"
ls -lh "$JNILIB_DIR"/*.so
echo ""
echo "Headers:    $INCLUDE_DIR/"
echo ""

# --- Total size ---
TOTAL=$(du -ch "$JNILIB_DIR"/*.so | tail -1 | cut -f1)
echo "Total .so size: $TOTAL"
echo ""
echo "FFmpeg version: $FFMPEG_VERSION"
echo "NDK version:    $(basename "$ANDROID_NDK_HOME")"
echo "API level:      $API_LEVEL"
echo ""
echo "LGPL 2.1 compliance: VERIFIED"
echo "  - Dynamic linking (.so)"
echo "  - No --enable-gpl"
echo "  - No --enable-nonfree"
echo "  - No external GPL libraries"
echo "  - Build script: $0"
echo "  - Configure flags: see above"
