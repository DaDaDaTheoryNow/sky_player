import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ios_method_channel.dart';

abstract class IosPlatform extends PlatformInterface {
  /// Constructs a IosPlatform.
  IosPlatform() : super(token: _token);

  static final Object _token = Object();

  static IosPlatform _instance = MethodChannelIos();

  /// The default instance of [IosPlatform] to use.
  ///
  /// Defaults to [MethodChannelIos].
  static IosPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IosPlatform] when
  /// they register themselves.
  static set instance(IosPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
