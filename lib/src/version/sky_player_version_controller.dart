import 'sky_player_platform_interface.dart';

class SkyPlayerVersionController {
  Future<String?> getPlatformVersion() {
    return SkyPlayerVersionPlatform.instance.getPlatformVersion();
  }
}
