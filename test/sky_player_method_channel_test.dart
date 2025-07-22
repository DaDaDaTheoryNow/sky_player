import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_player/src/version/sky_player_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelSkyPlayerVersion platform = MethodChannelSkyPlayerVersion();
  const MethodChannel channel = MethodChannel('sky_player_channel');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
