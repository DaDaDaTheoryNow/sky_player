import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sky_player_platform_interface.dart';

/// An implementation of [SkyPlayerPlatform] that uses method channels.
class MethodChannelSkyPlayerVersion extends SkyPlayerVersionPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sky_player_channel');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
