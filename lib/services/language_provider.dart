import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('ar');

  Locale get currentLocale => _currentLocale;

  bool get isArabic => _currentLocale.languageCode == 'ar';

  void toggleLanguage() {
    if (_currentLocale.languageCode == 'ar') {
      _currentLocale = const Locale('en');
    } else {
      _currentLocale = const Locale('ar');
    }
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _currentLocale = locale;
    notifyListeners();
  }
}
