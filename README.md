# SkyPlayer

<img width="270" height="577" alt="Screenshot_20250818-191148_sky_player_example~2" src="https://github.com/user-attachments/assets/fc45463d-7e0b-4d4b-8964-6520035c88e0" />
<img width="600" height="270" alt="Screenshot_20250818-191240_sky_player_example" src="https://github.com/user-attachments/assets/6d168040-6967-471f-83fa-9c21848b12e8" />
<img width="600" height="270" alt="Screenshot_20250818-191359_sky_player_example" src="https://github.com/user-attachments/assets/7bf38c55-d29b-4622-b475-29d5ffd7d94e" />

A lightweight, ExoPlayer-based video player plugin focused on **network streaming** with **customizable UI controls**, smart fullscreen behavior and a simple API.

---

## Features ✅

- 🌐 **Network streaming** — HLS (`*.m3u8`), MP4, WebM and other ExoPlayer-compatible sources.
- 🎛️ **Custom overlay UI** — provide an `overlayBuilder` to fully control the controls/overlay.
- 📱 **Smart fullscreen / rotation** — auto fullscreen on rotate and ability to open an _external_ fullscreen player via controller.
- 🔧 **Runtime options** — language, aspect mode and other player options available when creating the widget.
- ⚙️ **Controller API** — helper methods like `openFullScreenExternally` and `initLogger` for runtime control and debugging.

_Android Impeller note_ — if the player does not work on some Android devices, try disabling Impeller by adding to `AndroidManifest.xml`:

```xml
<meta-data
    android:name="io.flutter.embedding.android.EnableImpeller"
    android:value="false" />
```

---

## Minimal usage

### 1) Embedded inline player

```dart
import 'package:sky_player/sky_player.dart';

Widget build(BuildContext context) {
  return AspectRatio(
    aspectRatio: 16 / 9,
    child: SkyPlayer.network(
      'https://example.com/video.m3u8',
      autoFullscreenOnRotate: true,
      language: SkyPlayerLanguages.en,
      aspectMode: SkyPlayerAspectMode.auto,
      // overlayBuilder: (context, state, controller) => yourCustomOverlay,
    ),
  );
}
```

**Options shown**

- `autoFullscreenOnRotate: true` — tries to enter fullscreen when the device is rotated.
- `language: SkyPlayerLanguages.en` — sets UI language of the player overlay.
- `aspectMode: SkyPlayerAspectMode.auto` — controls how the video fits the widget.

---

### 2) Open external fullscreen from UI

```dart
import 'package:flutter/material.dart';
import 'package:sky_player/sky_player.dart';

class FullscreenButton extends StatelessWidget {
  final String url;
  const FullscreenButton({required this.url, super.key});

  Future<void> _openFullScreen(BuildContext context) async {
    try {
      await SkyPlayerController().openFullScreenExternally(
        context,
        url: url,
      );
    } catch (e) {
      // Show a simple error to the user if fullscreen couldn't be opened
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open fullscreen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _openFullScreen(context),
      icon: const Icon(Icons.fullscreen),
      label: const Text('Open fullscreen player'),
    );
  }
}
```

**Notes**

- `openFullScreenExternally` is useful when you want the player to be presented by a route/hosted fullscreen UI outside your widget tree (mimics native fullscreen behavior).

---

## API highlights

### `SkyPlayer.network(String url, { ...options })`

Create an inline player widget. Common options:

- `autoFullscreenOnRotate: bool` — automatically enter fullscreen on device rotation.
- `language: SkyPlayerLanguages` — UI language enum (e.g. `SkyPlayerLanguages.en`).
- `aspectMode: SkyPlayerAspectMode` — aspect handling enum (e.g. `auto`, `aspect_16_9`).
- `overlayBuilder: Widget Function(BuildContext context, PlayerState state, SkyPlayerController controller)?` — custom overlay builder for your own controls.
- Other playback options (buffering hints, current position, etc.) available in the `SkyPlayerController`.

### `SkyPlayerController`

Controller utilities for runtime control:

- `SkyPlayerController.initLogger({bool isDebug = false})`
  Enable native logs for debugging (call in `main()` before `runApp()`).

- `SkyPlayerController().openFullScreenExternally(BuildContext context, { required String url })`
  Open a fullscreen player outside the current widget tree.

- `SkyPlayerController().closeFullscreenPlayerWithPop(BuildContext context)`
  Close the fullscreen player.
