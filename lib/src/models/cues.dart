import 'package:flutter/foundation.dart';

@immutable
class Cues {
  final String text;

  const Cues({required this.text});

  factory Cues.fromJson(Map<String, dynamic> json) {
    return Cues(
      text: json['text'],
    );
  }
}
