import 'package:auto_localization/auto_localization.dart';
import 'package:flutter/material.dart';
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
  String _selectedLanguageCode = translator.currentLanguage;
  int _translationVersion = 0;

// Assuming you have a method to update the language in AutoLocalization
  void updateLanguage(String languageCode) async {
    await AutoLocalization.init(
      appLanguage: 'en', // Set to default or base language if necessary
      userLanguage: languageCode, // Update to the new user-selected language
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> languages = {
      'en': 'English',
      'cs': 'Czech',
      'fr': 'French',
      'zh': 'Chinese',
      'da': 'Danish',
      'nl': 'Dutch',
      'de': 'German',
      'el': 'Greek',
      'it': 'Italian',
      'ja': 'Japanese',
      'lt': 'Lithuanian',
      'nb': 'Norwegian',
      // 'pl': 'Polish',
      'pt': 'Portuguese',
      'ro': 'Romanian',
      'es': 'Spanish',
      // Add other supported languages here
    };

    return DropdownButton<String>(
      value: AutoLocalization.userLanguage,
      icon: Icon(Icons.arrow_downward, color: widget.iconColor),
      underline: Container(
        height: 2,
        color: widget.underlineColor ?? Theme.of(context).dividerColor,
      ),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedLanguageCode = newValue;
            translator.setCurrentLanguage(newValue);
          });
          widget.onLanguageChanged(newValue); // Existing callback
          updateLanguage(newValue); // New call to update AutoLocalization
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
