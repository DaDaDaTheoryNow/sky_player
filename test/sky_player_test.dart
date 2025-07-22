import 'package:flutter_test/flutter_test.dart';
import 'package:sky_player/sky_player.dart';
import 'package:sky_player/src/version/sky_player_platform_interface.dart';
import 'package:sky_player/src/version/sky_player_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSkyPlayerPlatform
    with MockPlatformInterfaceMixin
    implements SkyPlayerVersionPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SkyPlayerVersionPlatform initialPlatform =
      SkyPlayerVersionPlatform.instance;

  test('$MethodChannelSkyPlayerVersion is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSkyPlayerVersion>());
  });

  test('getPlatformVersion', () async {
    SkyPlayerVersionController skyPlayerPlugin = SkyPlayerVersionController();
    MockSkyPlayerPlatform fakePlatform = MockSkyPlayerPlatform();
    SkyPlayerVersionPlatform.instance = fakePlatform;

    expect(await skyPlayerPlugin.getPlatformVersion(), '42');
  });
}
