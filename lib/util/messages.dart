import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

class Messages extends Translations {
  final Map<String, Map<String, String>>? languages;
  Messages({required this.languages});

  @override
  Map<String, Map<String, String>> get keys {
    return languages!;
  }
}

/// The GetX translation-map key for a locale, e.g. `en_US`. Matches the key
/// `.tr` looks up (`"${languageCode}_${countryCode}"`), so it must not change.
String localeTranslationKey(String languageCode, String? countryCode) => '${languageCode}_$countryCode';

/// Loads and decodes ONE bundled language file.
///
/// Startup previously read and decoded every bundled language before the first
/// frame, even though a session uses one. This is the single loader shared by
/// startup (`get_di.init()`) and runtime switching
/// (`LocalizationController.setLanguage`), so both read the same assets the
/// same way.
///
/// Returns null instead of throwing when the asset is missing or malformed: a
/// bad language must never stop the app reaching `runApp()`, and callers fall
/// back to the existing `en_US` behaviour.
Future<Map<String, String>?> loadLanguageTranslations(String languageCode) async {
  try {
    final String jsonStringValues = await rootBundle.loadString('assets/language/$languageCode.json');
    final Map<String, dynamic> mappedJson = jsonDecode(jsonStringValues);
    final Map<String, String> json = {};
    mappedJson.forEach((key, value) {
      json[key] = value.toString();
    });
    return json;
  } catch (_) {
    return null;
  }
}
