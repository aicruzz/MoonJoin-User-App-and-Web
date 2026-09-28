import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/language/domain/models/language_model.dart';
import 'package:moonjoin/helper/address_helper.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:moonjoin/util/messages.dart';
import 'package:moonjoin/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/features/language/domain/service/language_service_interface.dart';

class LocalizationController extends GetxController implements GetxService {
  final LanguageServiceInterface languageServiceInterface;
  LocalizationController({required this.languageServiceInterface}){
    loadCurrentLanguage();
  }

  Locale _locale = Locale(AppConstants.languages[0].languageCode!, AppConstants.languages[0].countryCode);
  Locale get locale => _locale;

  bool _isLtr = true;
  bool get isLtr => _isLtr;

  List<LanguageModel> _languages = [];
  List<LanguageModel> get languages => _languages;

  int _selectedLanguageIndex = 0;
  int get selectedLanguageIndex => _selectedLanguageIndex;

  Future<void> setLanguage(Locale locale, {bool fromBottomSheet = false}) async {
    /// Startup loads only English and the saved language, so the language being
    /// selected here may not be in memory yet. Load and append it BEFORE the
    /// locale changes — updating first would render raw keys for a frame.
    ///
    /// If it cannot be loaded, the switch is abandoned rather than half-applied:
    /// the locale is not changed, the failed language is not persisted (so it
    /// cannot survive a restart) and no post-switch side effect runs. The user
    /// simply stays on the language they already had.
    if(!await _ensureTranslationsLoaded(locale)) {
      return;
    }
    Get.updateLocale(locale);
    _locale = locale;
    _isLtr = languageServiceInterface.setLTR(_locale);
    languageServiceInterface.updateHeader(_locale, Get.find<SplashController>().module?.id);

    if(!fromBottomSheet) {
      saveLanguage(_locale);
    }
    
    if(AddressHelper.getUserAddressFromSharedPref() != null && !fromBottomSheet) {
      HomeScreen.loadData(true);
    } else if(ResponsiveHelper.isDesktop(Get.context) && AddressHelper.getUserAddressFromSharedPref() == null){
      Get.find<SplashController>().getLandingPageData();
    }

    if(Get.find<SplashController>().moduleList == null) {
      Get.find<SplashController>().getModules(headers: {'Content-Type': 'application/json; charset=UTF-8', AppConstants.localizationKey: Get.find<LocalizationController>().locale.languageCode});
    }

    update();
  }

  /// Adds a language's translations to the live GetX map if it is not already
  /// there, using the existing `Get.appendTranslations` API — no new cache and
  /// no new localization architecture. A language stays loaded for the rest of
  /// the session.
  ///
  /// Returns whether the language is usable: true when it was already loaded or
  /// has just been appended, false when the asset is missing or malformed. The
  /// caller must not switch to a language this reports false for.
  Future<bool> _ensureTranslationsLoaded(Locale locale) async {
    final String key = localeTranslationKey(locale.languageCode, locale.countryCode);
    if(Get.translations.containsKey(key)) {
      return true;
    }
    final Map<String, String>? translations = await loadLanguageTranslations(locale.languageCode);
    if(translations == null) {
      return false;
    }
    Get.appendTranslations(<String, Map<String, String>>{key: translations});
    return true;
  }

  void loadCurrentLanguage() async {
    _locale = languageServiceInterface.getLocaleFromSharedPref();
    _isLtr = _locale.languageCode != 'ar';
    _selectedLanguageIndex = languageServiceInterface.setSelectedIndex(AppConstants.languages, _locale);
    _languages = [];
    _languages.addAll(AppConstants.languages);
    update();
  }

  void saveLanguage(Locale locale) async {
    languageServiceInterface.saveLanguage(locale);
  }

  void saveCacheLanguage(Locale? locale) {
    languageServiceInterface.saveCacheLanguage(locale ?? languageServiceInterface.getLocaleFromSharedPref());
  }

  void setSelectLanguageIndex(int index) {
    _selectedLanguageIndex = index;
    update();
  }

  Locale getCacheLocaleFromSharedPref() {
    return languageServiceInterface.getCacheLocaleFromSharedPref();
  }

  void searchSelectedLanguage() {
    for (var language in AppConstants.languages) {
      if (language.languageCode!.toLowerCase().contains(_locale.languageCode.toLowerCase())) {
        _selectedLanguageIndex = AppConstants.languages.indexOf(language);
      }
    }
  }

}