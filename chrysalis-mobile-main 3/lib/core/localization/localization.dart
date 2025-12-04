import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///All localization functions is handled by Translator class
class Translator {
  static String translate(BuildContext context, String key) {
    if (AppLocalizations.of(context) == null) {
      if (kDebugMode) {
        throw Exception('AppLocalization context was null');
      }
      return key;
    } else {
      return AppLocalizations.of(context)!.translate(key);
    }
  }

  static String translateWithoutContext(String key) {
    return AppLocalizations.staticTranslate(key);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLanguages = [
    Locale('en', 'US'),
    Locale('ar', 'SA'),
  ];
}

///This class is private and not used anywhere in the app except Translator class
class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static late Map<String, String> _localizedStrings;

  Future<bool> load() async {
    final jsonString = await rootBundle.loadString(
      'assets/localization/${locale.languageCode}.json',
    );
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  String translate(String key) {
    if (_localizedStrings[key] == null) {
      // if (kDebugMode) {
      //   throw Exception("Translation for $key was not found in ${locale.languageCode}.json file");
      // }
      return key;
    } else {
      return _localizedStrings[key]!;
    }
  }

  static String staticTranslate(String key) {
    if (_localizedStrings[key] == null) {
      // if (kDebugMode) {
      //   throw Exception("Translation for $key was not found in ${ThemeProvider.appLanguage.languageCode}.json file");
      // }
      return key;
    } else {
      return _localizedStrings[key]!;
    }
  }
}

///This class is private and not used anywhere in the app except Translator class
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return Translator.supportedLanguages.contains(locale);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
