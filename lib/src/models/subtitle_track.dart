import 'package:flutter/foundation.dart';

@immutable
class SubtitleTrack {
  final String id;
  final String? language;
  final String label;

  const SubtitleTrack({
    required this.id,
    required this.language,
    required this.label,
  });

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) {
    return SubtitleTrack(
      id: json['id'],
      language: json['language'],
      label: json['label'],
    );
  }
}
