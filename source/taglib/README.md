# TagLib — Complete Corresponding Source (LGPL 2.1)

This directory publishes the complete corresponding source for the **taglib**
library bundled in the [Vox Machina](https://play.google.com/store/apps/details?id=com.voxmachinaaudio.player)
Android USB audio engine, together with the recipe to rebuild it.

taglib is dual-licensed **LGPL 2.1 / MPL 1.1**. Vox Machina **elects LGPL 2.1**.

## Why taglib is published here but FFmpeg is not

FFmpeg and Chromaprint ship in Vox Machina **unmodified**, as their own separate
shared objects, dynamically linked. For an unmodified, separately-linked LGPL
library, the upstream source plus the [build script](../../build_ffmpeg_android.sh)
is a complete **§6(b)** discharge — nothing of ours is combined into them.

taglib is different in two ways, which together make its discharge **§6(a)**, not
§6(b):

1. **It is modified.** One file — `fileref_ext.cpp` — carries a small Vox Machina
   patch. Upstream alone is therefore no longer the corresponding source, so the
   patch is published here.
2. **It is statically linked into a combined shared object.** taglib is archived
   into `libvoxmachina_taglib.so`, which also contains Vox Machina's own JNI
   bridge. taglib is not a separately replaceable `.so` in this app.

## The modification

`patches/0001-voxmachina-format-surface-ifdef-guards.patch` is the entire
modification, against the pristine Kyant0 `fileref_ext.cpp` (pin below). It wraps
each **excluded-format** `#include` and file-type dispatch branch (ASF, RIFF/WAV/
AIFF, DSF/DSDIFF, Matroska) in the same `#ifdef TAGLIB_WITH_*` guards that stock
upstream taglib's own `fileref.cpp` already uses. Vox Machina compiles a
cherry-picked format surface (MPEG/ID3, Ogg/Vorbis/FLAC/Speex/Opus, APE/Musepack/
WavPack, MP4) and does not vendor the excluded formats' sources at all, so the
unconditional includes in the Kyant0 fork would not compile. The patch is an
include-guard restoration only — **no logic change** for any supported format. It
is a lawful LGPL 2.1 §2 modification of a taglib-derived (LGPL/MPL) file.

`fileref_ext.h` is **unmodified**.

## Provenance / pins

| Component | Source | Pin |
|---|---|---|
| taglib (base) | https://github.com/taglib/taglib | tag `v2.3.1` |
| utf8-cpp (taglib dep) | https://github.com/nemtrif/utfcpp | `819011bb01628fe1aa2f1da9f2c842a48fd5680b` |
| Kyant0 `fileref_ext.{h,cpp}` | https://github.com/Kyant0/taglib | `1.0.6` (`957fd7c2794457a14c1484fa3e3b58382aca4202`) |
| Vox Machina patch | `patches/` in this directory | — |
| Format surface | `taglib_config.h` in this directory | — |

**Re-pin note.** The Kyant0 fork's own submodule pin to `taglib/taglib` is
unreachable / pruned from upstream (verified via the GitHub REST and git-data
APIs, a full un-shallowed clone, and the Software Heritage archive). Vox Machina
re-pins the underlying taglib to the latest reachable **stable** tag, `v2.3.1`.
The Kyant0 `fileref_ext.{h,cpp}` are taken at the fork's released `1.0.6` pin
(reachable) and call only long-stable public taglib API present unchanged in
`v2.3.1`.

## Rebuilding

```
export ANDROID_NDK_HOME=/path/to/ndk/28.2.13676358
./build_taglib_android.sh      # from the repository root
```

This clones the pinned upstream, fetches the Kyant0 `fileref_ext.{h,cpp}`, applies
the published patch, installs `taglib_config.h`, and compiles the exact source
set the app links — producing `output/arm64-v8a/libvox_taglib_core.a`, the static
taglib library archived into `libvoxmachina_taglib.so`.

## Relinking the combined library (§6(a))

Because taglib is statically archived into `libvoxmachina_taglib.so` alongside Vox
Machina's own JNI bridge, relinking the combined shared object against a modified
taglib also requires the Vox-Machina-authored portion — the "work that uses the
Library." Per LGPL 2.1 §6(a), that portion is available **as object code** on
request (it need not be, and is not, published as source), sufficient to relink
`libvoxmachina_taglib.so` against a taglib you have modified and rebuilt with the
recipe above. Request it via the app's Licenses screen contact, or the repository
owner.

## License

The build script, patch, and `taglib_config.h` in this directory are provided
under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). taglib itself
is licensed under [LGPL 2.1](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html)
(elected) / MPL 1.1.
