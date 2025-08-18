import 'sky_player_languages.dart';

class SkyPlayerLocalization {
  final SkyPlayerLanguages language;

  const SkyPlayerLocalization({this.language = SkyPlayerLanguages.en});

  static const Map<SkyPlayerLanguages, Map<String, String>> _localizedValues = {
    SkyPlayerLanguages.en: {
      'settings': 'Settings',
      'quality': 'Quality',
      'subtitles': 'Subtitles',
      'audioTrack': 'Audio track',
      'off': 'Off',
      'videoQuality': 'Video quality',
      'auto': 'Auto',
    },
    SkyPlayerLanguages.ru: {
      'settings': 'Настройки',
      'quality': 'Качество',
      'subtitles': 'Субтитры',
      'audioTrack': 'Аудиодорожка',
      'off': 'Выключены',
      'videoQuality': 'Качество видео',
      'auto': 'Авто',
    },
  };

  String _t(String key) {
    return _localizedValues[language]?[key] ??
        _localizedValues[SkyPlayerLanguages.en]![key]!;
  }

  String get settings => _t('settings');
  String get quality => _t('quality');
  String get subtitles => _t('subtitles');
  String get audioTrack => _t('audioTrack');
  String get off => _t('off');
  String get videoQuality => _t('videoQuality');
  String get auto => _t('auto');
}
