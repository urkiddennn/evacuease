import 'package:flutter/material.dart';

class Language with ChangeNotifier {
  String _currentLanguage = 'en'; // Default to English

  String get currentLanguage => _currentLanguage;

  void setLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }

  // Translations
  Map<String, Map<String, String>> translations = {
    'en': {
      'about': 'About',
      'settings': 'Settings',
      'language': 'Language',
      'logout': 'Logout',
      'feedback': 'Feedback',
      'report_bug': 'Report Bug',
      'send_feedback': 'Send Feedback',
      'home': 'Home',
      'location': 'Location',
      'notification': 'Notification',
      'user': 'User',
      'risk_area': 'Risk Area',
      'offline_risk_map': 'Offline Risk Map',
    },
    'tl': {
      // Tagalog
      'about': 'Tungkol Sa',
      'settings': 'Mga Setting',
      'language': 'Wika',
      'logout': 'Mag-logout',
      'feedback': 'Puna',
      'report_bug': 'Mag-ulat ng Bug',
      'send_feedback': 'Magpadala ng Puna',
      'home': 'Tahanan',
      'location': 'Lokasyon',
      'notification': 'Notipikasyon',
      'user': 'Gumagamit',
      'risk_area': 'Lugar ng Panganib',
      'offline_risk_map': 'Offline na Mapa ng Panganib',
    },
    'ceb': {
      // Bisaya (Cebuano)
      'about': 'Mahitungod Sa',
      'settings': 'Mga Setting',
      'language': 'Pinulongan',
      'logout': 'Logout',
      'feedback': 'Pahayag',
      'report_bug': 'I-report ang Bug',
      'send_feedback': 'Ipadala ang Pahayag',
      'home': 'Balay',
      'location': 'Lokasyon',
      'notification': 'Notipikasyon',
      'user': 'Tiggamit',
      'risk_area': 'Lugar nga Delikado',
      'offline_risk_map': 'Offline nga Mapa sa Delikado',
    },
  };

  String get about => translations[_currentLanguage]!['about']!;
  String get settings => translations[_currentLanguage]!['settings']!;
  String get language => translations[_currentLanguage]!['language']!;
  String get logout => translations[_currentLanguage]!['logout']!;
  String get feedback => translations[_currentLanguage]!['feedback']!;
  String get reportBug => translations[_currentLanguage]!['report_bug']!;
  String get sendFeedback => translations[_currentLanguage]!['send_feedback']!;
  String get home => translations[_currentLanguage]!['home']!;
  String get location => translations[_currentLanguage]!['location']!;
  String get notification => translations[_currentLanguage]!['notification']!;
  String get user => translations[_currentLanguage]!['user']!;
  String get riskArea => translations[_currentLanguage]!['risk_area']!;
  String get offlineRiskMap =>
      translations[_currentLanguage]!['offline_risk_map']!;
}
