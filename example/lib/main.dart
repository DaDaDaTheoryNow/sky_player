import 'package:flutter/material.dart';
import 'package:sky_player/sky_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String _videoUrl =
      'https://playertest.longtailvideo.com/adaptive/elephants_dream_v4/index.m3u8';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Container(
            margin: EdgeInsets.all(16),
            width: double.infinity,
            height: MediaQuery.of(context).size.height / 3,
            child: SkyPlayer.network(
              _videoUrl,
              autoEnterExitFullScreenMode: true,
              isNativeControlsEnabled:
                  true, // if true then it doesn't work with overlayBuilder
              // overlayBuilder: (context, state, controller) {
              //   return SizedBox();
              // },
            ),
          ),
        ),
      ),
    );
  }
}
