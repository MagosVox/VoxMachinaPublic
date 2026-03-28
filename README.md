# Vox Machina — Public Resources

Public-facing resources for the [Vox Machina](https://play.google.com/store/apps/details?id=com.example.voxmachinasecundus) Android USB audio engine.

## Contents

### Privacy Policy

[PRIVACY_POLICY.md](PRIVACY_POLICY.md)

Vox Machina collects no data. Zero analytics, zero telemetry, zero network calls.

### FFmpeg Build Script

[build_ffmpeg_android.sh](build_ffmpeg_android.sh)

Cross-compilation script for FFmpeg 7.1 targeting Android arm64-v8a. LGPL 2.1 decode-only configuration.

This script is published to satisfy LGPL 2.1 Section 6(b) — it provides the complete build configuration and relinking instructions for the FFmpeg shared libraries (.so) bundled in the application.

**To relink FFmpeg against a modified or updated version:**

1. Obtain FFmpeg source from https://ffmpeg.org or `git clone --branch n7.1 https://git.ffmpeg.org/ffmpeg.git`
2. Set `ANDROID_NDK_HOME` to your Android NDK path
3. Run `./build_ffmpeg_android.sh`
4. Replace the `.so` files in `app/src/main/jniLibs/arm64-v8a/`

**Requirements:** Linux or WSL, Android NDK 28+, make, nasm/yasm.

## License

The FFmpeg build script and privacy policy in this repository are provided under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). FFmpeg itself is licensed under [LGPL 2.1](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html).
