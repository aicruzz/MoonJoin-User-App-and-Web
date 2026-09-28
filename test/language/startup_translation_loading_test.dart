// Focused tests for Slice A — startup translation loading.
//
// Startup previously read and JSON-decoded all four bundled languages before
// runApp(). It now loads English (the GetX fallbackLocale) plus the saved
// language, and every other language is appended on demand when selected.
//
// These cover the parts that are testable without booting DI: the shared
// loader, the locale key format, the active-language resolution rule used at
// startup, the "never load English twice" guarantee, and the append + fallback
// semantics that runtime switching depends on.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/features/language/controllers/language_controller.dart';
import 'package:moonjoin/features/language/domain/models/language_model.dart';
import 'package:moonjoin/features/language/domain/service/language_service_interface.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:moonjoin/util/messages.dart';

/// The exact resolution used by get_di.init(): resolve the saved code against
/// the supported list, falling back to the first (English) entry.
LanguageModel resolveActive(String? savedCode) {
  final LanguageModel fallback = AppConstants.languages[0];
  final String code = savedCode ?? fallback.languageCode!;
  return AppConstants.languages.firstWhere(
    (LanguageModel language) => language.languageCode == code,
    orElse: () => fallback,
  );
}

/// The exact startup set: English always, plus the active language.
Set<LanguageModel> startupSet(String? savedCode) =>
    <LanguageModel>{AppConstants.languages[0], resolveActive(savedCode)};

/// Records what the controller would persist, so a failed switch can be proven
/// not to save anything.
class RecordingLanguageService implements LanguageServiceInterface {
  final List<Locale> savedLanguages = <Locale>[];
  final List<Locale> headerUpdates = <Locale>[];

  @override
  bool setLTR(Locale locale) => locale.languageCode != 'ar';

  @override
  void updateHeader(Locale locale, int? moduleId) => headerUpdates.add(locale);

  @override
  Locale getLocaleFromSharedPref() => const Locale('en', 'US');

  @override
  int setSelectedIndex(List<LanguageModel> languages, Locale locale) => 0;

  @override
  void saveLanguage(Locale locale) => savedLanguages.add(locale);

  @override
  void saveCacheLanguage(Locale locale) {}

  @override
  Locale getCacheLocaleFromSharedPref() => const Locale('en', 'US');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('all four languages remain supported and selectable', () {
    test('AppConstants still declares en, ar, es, bn with English first', () {
      final List<String?> codes = AppConstants.languages.map((LanguageModel l) => l.languageCode).toList();
      expect(codes, containsAll(<String>['en', 'ar', 'es', 'bn']));
      expect(codes.length, 4);
      // English must be first: it is the fallbackLocale source.
      expect(AppConstants.languages[0].languageCode, 'en');
      expect(AppConstants.languages[0].countryCode, 'US');
    });
  });

  group('shared loader', () {
    test('every bundled language decodes to a non-empty map', () async {
      for (final LanguageModel language in AppConstants.languages) {
        final Map<String, String>? loaded = await loadLanguageTranslations(language.languageCode!);
        expect(loaded, isNotNull, reason: '${language.languageCode} failed to load');
        expect(loaded!.isNotEmpty, isTrue);
      }
    });

    test('a missing or malformed asset returns null instead of throwing', () async {
      expect(await loadLanguageTranslations('zz'), isNull);
      expect(await loadLanguageTranslations(''), isNull);
    });

    test('locale key matches the format .tr looks up', () {
      expect(localeTranslationKey('en', 'US'), 'en_US');
      expect(localeTranslationKey('ar', 'SA'), 'ar_SA');
    });
  });

  group('startup language resolution', () {
    test('a saved supported language resolves to itself', () {
      expect(resolveActive('ar').languageCode, 'ar');
      expect(resolveActive('bn').languageCode, 'bn');
      expect(resolveActive('es').languageCode, 'es');
      expect(resolveActive('en').languageCode, 'en');
    });

    test('unknown, empty or absent saved codes fall back to English', () {
      expect(resolveActive('zz').languageCode, 'en');
      expect(resolveActive('').languageCode, 'en');
      expect(resolveActive(null).languageCode, 'en');
      expect(resolveActive('en_US_garbage').languageCode, 'en');
    });
  });

  group('startup load set', () {
    test('English session loads English once — never twice', () {
      final Set<LanguageModel> set = startupSet('en');
      expect(set.length, 1);
      expect(set.single.languageCode, 'en');
    });

    test('a non-English session loads exactly English + that language', () {
      for (final String code in <String>['ar', 'bn', 'es']) {
        final Set<LanguageModel> set = startupSet(code);
        expect(set.length, 2, reason: 'expected en + $code');
        final List<String?> codes = set.map((LanguageModel l) => l.languageCode).toList();
        expect(codes, containsAll(<String>['en', code]));
      }
    });

    test('an invalid saved code degrades to the English-only set', () {
      expect(startupSet('zz').length, 1);
      expect(startupSet('zz').single.languageCode, 'en');
    });

    test('the unused languages are NOT in the startup set', () {
      final List<String?> codes = startupSet('ar').map((LanguageModel l) => l.languageCode).toList();
      expect(codes.contains('bn'), isFalse);
      expect(codes.contains('es'), isFalse);
    });
  });

  group('a failed switch is abandoned, not half-applied', () {
    setUp(() {
      Get.reset();
      Get.clearTranslations();
      Get.addTranslations(<String, Map<String, String>>{
        'en_US': <String, String>{'greeting': 'Hello'},
      });
      Get.locale = const Locale('en', 'US');
      Get.fallbackLocale = const Locale('en', 'US');
    });
    tearDownAll(() {
      Get.reset();
      Get.clearTranslations();
    });

    test('an unloadable language does not change the locale and is not persisted', () async {
      final RecordingLanguageService service = RecordingLanguageService();
      final LocalizationController controller =
          LocalizationController(languageServiceInterface: service);

      // 'zz' has no bundled asset, so the load must fail.
      await controller.setLanguage(const Locale('zz', 'ZZ'));

      expect(Get.locale, const Locale('en', 'US'), reason: 'locale must not move to a language with no translations');
      expect(controller.locale, const Locale('en', 'US'));
      expect(service.savedLanguages, isEmpty, reason: 'a failed language must never be persisted');
      expect(service.headerUpdates, isEmpty, reason: 'no post-switch side effect should run');
      expect(Get.translations.containsKey('zz_ZZ'), isFalse);
      // The UI still resolves through the language it already had.
      expect('greeting'.tr, 'Hello');
    });
  });

  group('runtime append + fallback semantics', () {
    setUp(() {
      Get.clearTranslations();
      Get.locale = const Locale('en', 'US');
      Get.fallbackLocale = const Locale('en', 'US');
    });
    tearDownAll(Get.clearTranslations);

    test('appendTranslations makes a not-yet-loaded language resolvable', () async {
      Get.addTranslations(<String, Map<String, String>>{
        'en_US': <String, String>{'greeting': 'Hello', 'only_in_english': 'English only'},
      });
      expect(Get.translations.containsKey('ar_SA'), isFalse);

      final Map<String, String>? arabic = await loadLanguageTranslations('ar');
      expect(arabic, isNotNull);
      Get.appendTranslations(<String, Map<String, String>>{'ar_SA': arabic!});

      expect(Get.translations.containsKey('ar_SA'), isTrue);
      expect(Get.translations.containsKey('en_US'), isTrue, reason: 'English must survive the append');
    });

    test('a key missing from the active language falls back to English, not the raw key', () {
      Get.addTranslations(<String, Map<String, String>>{
        'en_US': <String, String>{'only_in_english': 'English only'},
        'ar_SA': <String, String>{'something_else': 'شيء'},
      });
      Get.locale = const Locale('ar', 'SA');

      expect('only_in_english'.tr, 'English only');
    });

    test('an unknown key still returns itself, unchanged behaviour', () {
      Get.addTranslations(<String, Map<String, String>>{
        'en_US': <String, String>{'known': 'Known'},
      });
      expect('totally_unknown_key'.tr, 'totally_unknown_key');
    });
  });
}
