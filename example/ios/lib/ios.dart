
import 'ios_platform_interface.dart';

class Ios {
  Future<String?> getPlatformVersion() {
    return IosPlatform.instance.getPlatformVersion();
  }
}
