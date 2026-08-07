/* taglib_config.h — Vox Machina hand-authored replacement for CMake's
 * configure_file(taglib_config.h.cmake) step (Rite of the Attested
 * Identity G5, Phase A). We do not run taglib's own CMakeLists.txt (see
 * ../VENDORING.md); this file encodes the SAME cherry-picked format
 * surface that CMakeLists.txt's target_sources() selection encodes for
 * the compiled .cpp list — the two must be kept in lockstep by hand.
 *
 * KEPT (compiled in, guarded by TAGLIB_WITH_* below): Vorbis/FLAC/Ogg/
 * Opus/Speex container family, APE/MPC/WavPack, MP4. Plus MPEG/ID3v1/
 * ID3v2, which upstream taglib compiles unconditionally (no WITH_ flag).
 *
 * FENCED OUT (never #define'd -> upstream's own #ifdef TAGLIB_WITH_*
 * guards in fileref.cpp/tagutils.cpp compile out every include of and
 * reference to these formats; their source files are additionally never
 * copied into upstream/ at all — see VENDORING.md "excluded formats"):
 * ASF, DSF/DSDIFF, Matroska, Tracker modules (MOD/S3M/IT/XM), RIFF/WAV/
 * AIFF, Shorten, TrueAudio.
 */

#ifndef TAGLIB_TAGLIB_CONFIG_H
#define TAGLIB_TAGLIB_CONFIG_H

#define TAGLIB_WITH_APE 1
#define TAGLIB_WITH_MP4 1
#define TAGLIB_WITH_VORBIS 1

/* Deliberately NOT defined — campaign §6 G5 fenced formats:
 * #define TAGLIB_WITH_ASF 1
 * #define TAGLIB_WITH_DSF 1
 * #define TAGLIB_WITH_MATROSKA 1
 * #define TAGLIB_WITH_MOD 1
 * #define TAGLIB_WITH_RIFF 1
 * #define TAGLIB_WITH_SHORTEN 1
 * #define TAGLIB_WITH_TRUEAUDIO 1
 */

#endif
