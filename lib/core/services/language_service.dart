import 'package:flutter/foundation.dart';

class LanguageService extends ChangeNotifier {
  final String _currentLanguage = 'np'; // Always Nepali

  String get currentLanguage => _currentLanguage;
  bool get isNepali => true;
  bool get isEnglish => false;

  LanguageService();

  Future<void> setLanguage(String lang) async {
    // No-op
  }

  Future<void> toggleLanguage() async {
    // No-op
  }
}
