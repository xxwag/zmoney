import 'package:auto_localization/auto_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zmoney/fukk_widgets/translator.dart';

final translator =
    Translator(currentLanguage: 'en'); // Set initial language as needed

class LanguageSelectorWidget extends StatefulWidget {
  final Function(String) onLanguageChanged;
  final Color? dropdownColor; // Color of the dropdown background
  final Color? textColor; // Color of the text
  final Color? iconColor; // Color of the dropdown icon
  final Color? underlineColor; // Color of the underline

  const LanguageSelectorWidget({
    super.key,
    required this.onLanguageChanged,
    this.dropdownColor,
    this.textColor,
    this.iconColor,
    this.underlineColor,
  });

  @override
  State<LanguageSelectorWidget> createState() => _LanguageSelectorWidgetState();
}

class _LanguageSelectorWidgetState extends State<LanguageSelectorWidget> {
  bool _isLocked = false;

  void updateLanguage(String languageCode) async {
    if (!_isLocked) {
      setState(() {
        _isLocked = true; // Lock the language selector
      });

      // Update the language in AutoLocalization
      await AutoLocalization.init(
        appLanguage: 'en', // Set to default or base language if necessary
        userLanguage: languageCode, // Update to the new user-selected language
      );

      // Update the language in your translator widget, if necessary
      translator.setCurrentLanguage(languageCode);
// Store the language code in SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userLanguage', languageCode);

      // Inform about the language change
      widget.onLanguageChanged(languageCode);

      setState(() {
        _isLocked = false; // Unlock the language selector
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> languages = {
      'en': 'English',
      'cs': 'Czech',
      'fr': 'French',
      'zh-CN': 'Chinese', // Updated for BCP-47
      'zh-TW': 'Chinese-s', // Updated for BCP-47
      'ja': 'Japanese',
      'da': 'Danish',
      'nl': 'Dutch',
      'de': 'German',
      'el': 'Greek',
      'it': 'Italian',

      'lt': 'Lithuanian',
      'nb': 'Norwegian',
      'pl': 'Polish', // Added back as it's widely spoken
      'pt': 'Portuguese',
      'ro': 'Romanian',
      'ru': 'Russian', // Added as it's widely spoken
      'es': 'Spanish',
      'sv': 'Swedish', // Added as it's widely used in Scandinavia
      'tr': 'Turkish', // Added as it's widely spoken
      'ar': 'Arabic', // Added as it's one of the top spoken languages globally
      'hi': 'Hindi', // Added as it's one of the top spoken languages in India
      'ko':
          'Korean', // Added as it's widely used in technology and entertainment
      // Add other supported languages here
    };

    return DropdownButton<String>(
      value: translator.currentLanguage,
      icon: Icon(Icons.arrow_downward, color: widget.iconColor),
      underline: Container(
        height: 2,
        color: widget.underlineColor ?? Theme.of(context).dividerColor,
      ),
      onChanged: _isLocked
          ? null
          : (String? newValue) {
              if (newValue != null) {
                updateLanguage(newValue);
              }
            },
      items: languages.entries.map<DropdownMenuItem<String>>((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(
            entry.value,
            style: TextStyle(color: widget.textColor),
          ),
        );
      }).toList(),
      dropdownColor: widget.dropdownColor,
    );
  }
}
