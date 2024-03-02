// ... Rest of your code for PlayGamesService, WelcomeScreen, etc. ...
import 'package:auto_localization/auto_localization.dart';

class Translator {
  static final Map<String, String> _translationsCache = {};
  final String defaultLanguage;
  String currentLanguage;

  Translator({this.defaultLanguage = 'en', this.currentLanguage = 'en'});

  Future<String> translate(String key) async {
    // Check if the translation is in the cache
    String cacheKey = '$currentLanguage:$key';
    if (_translationsCache.containsKey(cacheKey)) {
      return _translationsCache[cacheKey]!;
    }

    // If not in cache, fetch the translation
    // This is a placeholder for fetching the translation. Replace with your actual translation logic.
    String translatedText = await AutoLocalization.translate(key);
    _translationsCache[cacheKey] = translatedText;

    return translatedText;
  }

  void setCurrentLanguage(String language) {
    if (currentLanguage != language) {
      currentLanguage = language;
      _translationsCache
          .clear(); // Clear cache to force fetching new translations
    }
  }
}
