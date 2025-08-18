// example/lib/main.dart
import 'package:flutter/material.dart';
import 'package:sky_player/sky_player.dart';

/// Simple example demonstrating sky_player:
/// - switching between multiple videos with a TabBar
/// - inline and external fullscreen modes
/// - smooth expand/collapse animations
///
/// Copy this file to example/lib/main.dart when preparing your package for pub.dev.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable native logger (useful for example debugging).
  SkyPlayerController.initLogger(isDebug: true);

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sky Player Example',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const PlayerDemoPage(),
    );
  }
}

class VideoItem {
  final String title;
  final String url;

  const VideoItem({required this.title, required this.url});
}

class PlayerDemoPage extends StatefulWidget {
  const PlayerDemoPage({super.key});

  @override
  State<PlayerDemoPage> createState() => _PlayerDemoPageState();
}

class _PlayerDemoPageState extends State<PlayerDemoPage>
    with SingleTickerProviderStateMixin {
  // Demo video list
  final List<VideoItem> _videos = const [
    VideoItem(
      title: 'Elephant Dream (HLS)',
      url:
          'https://playertest.longtailvideo.com/adaptive/elephants_dream_v4/index.m3u8',
    ),
    VideoItem(
      title: 'Anime Example (HLS)',
      url:
          'https://cache.libria.fun/videos/media/ts/7405/1/720/e0909048214719d805ffef7f2fd62e02.m3u8',
    ),
    VideoItem(
      title: 'Kimi no Na wa (MP4)',
      url: 'https://cdn.jsdelivr.net/gh/shiyiya/QI-ABSL@master/o/君の名は.mp4',
    ),
  ];

  late final TabController _tabController;
  late String _currentUrl;
  bool _isPlayerExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = _videos.first.url;
    _tabController = TabController(length: _videos.length, vsync: this);

    // When the tab changes, update URL and collapse inline player.
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final newUrl = _videos[_tabController.index].url;
      _switchVideo(newUrl);
    });
  }

  void _switchVideo(String url) {
    setState(() {
      _currentUrl = url;
      _isPlayerExpanded = false; // reset expanded player
    });
  }

  void _togglePlayerExpanded() {
    setState(() {
      _isPlayerExpanded = !_isPlayerExpanded;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Open external fullscreen via SkyPlayerController
  Future<void> _openExternalFullScreen(BuildContext context) async {
    try {
      await SkyPlayerController().openFullScreenExternally(
        context,
        url: _currentUrl,
      );
    } catch (e) {
      // Simple error handling — show SnackBar if something goes wrong
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open fullscreen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _videos.map((v) => Tab(text: v.title)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sky Player — Tabs Example'),
        centerTitle: true,
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
          isScrollable: true,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _isPlayerExpanded
                  ? _buildExpandedPlayer(context)
                  : _buildCompactControls(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedPlayer(BuildContext context) {
    return Column(
      key: const ValueKey('expanded'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Close button aligned to the right
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _togglePlayerExpanded,
            icon: const Icon(Icons.close),
            label: const Text('Close player'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(12)),
          ),
        ),
        const SizedBox(height: 8),
        // Player with aspect ratio and rounded corners
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SkyPlayer.network(
              _currentUrl,
              autoFullscreenOnRotate: true,
              language: SkyPlayerLanguages.en,
              aspectMode: SkyPlayerAspectMode.auto,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactControls(BuildContext context) {
    return Column(
      key: const ValueKey('compact'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: _togglePlayerExpanded,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Show inline player'),
          style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _openExternalFullScreen(context),
          icon: const Icon(Icons.fullscreen),
          label: const Text('Open fullscreen player'),
          style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
        ),
        const SizedBox(height: 16),
        // Show user which URL is currently selected
        Text(
          'Current video:\n$_currentUrl',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}
