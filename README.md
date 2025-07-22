# SkyPlayer

A lightweight yet powerful ExoPlayer-based video player plugin specializing in **network streaming** with **fully customizable UI controls**.

## Current Capabilities ✅

### Core Features

- 🌐 **Network Streaming**  
  Supports HTTP/HTTPS, HLS (`*.m3u8`), MP4, WebM, and other ExoPlayer-compatible formats.

- 🎚️ **Custom UI Control**  
  Fully customizable overlay UI with state-aware builder.

  ```dart
  SkyPlayer.network(
      _videoUrl,
      autoEnterExitFullScreenMode: true,
      overlayBuilder: (context, state, controller) {
        return SizedBox();
      },
  ),
  ```

- 🖥️ **Smart Fullscreen**  
   Auto fullscreen mode with device rotation support.
