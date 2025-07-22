import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sky_player_method_channel.dart';

abstract class SkyPlayerVersionPlatform extends PlatformInterface {
  /// Constructs a SkyPlayerPlatform.
  SkyPlayerVersionPlatform() : super(token: _token);

  static final Object _token = Object();

  static SkyPlayerVersionPlatform _instance = MethodChannelSkyPlayerVersion();

  /// The default instance of [SkyPlayerPlatform] to use.
  ///
  /// Defaults to [MethodChannelSkyPlayer].
  static SkyPlayerVersionPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SkyPlayerPlatform] when
  /// they register themselves.
  static set instance(SkyPlayerVersionPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
