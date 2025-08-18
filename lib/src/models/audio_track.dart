import 'package:flutter/foundation.dart';

@immutable
class AudioTrack {
  final String id;
  final String? language;
  final String? label;

  const AudioTrack({
    required this.id,
    required this.language,
    required this.label,
  });

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      id: json['id'],
      language: json['language'],
      label: json['label'],
    );
  }
}
