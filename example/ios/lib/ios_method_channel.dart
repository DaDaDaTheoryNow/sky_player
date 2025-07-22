import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ios_platform_interface.dart';

/// An implementation of [IosPlatform] that uses method channels.
class MethodChannelIos extends IosPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ios');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
