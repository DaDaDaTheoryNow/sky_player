import 'package:flutter/material.dart';
import 'package:sky_player/sky_player.dart';

class SubtitlesRendererWidget extends StatelessWidget {
  final SkyPlayerState state;

  const SubtitlesRendererWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    if (state.currentCues.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: true,
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Text(
          state.currentCues.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            height: 1.4,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black87,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
