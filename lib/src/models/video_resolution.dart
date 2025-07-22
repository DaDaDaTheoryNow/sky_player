import 'package:flutter/foundation.dart';

@immutable
class VideoResolution {
  final String id;
  final int width;
  final int height;
  final int bitrate;

  const VideoResolution({
    required this.id,
    required this.width,
    required this.height,
    required this.bitrate,
  });

  factory VideoResolution.fromJson(Map<String, dynamic> json) {
    return VideoResolution(
      id: json['id'],
      width: json['width'],
      height: json['height'],
      bitrate: json['bitrate'],
    );
  }
}
