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
      'starter': 'Starter',
      'starter_message': 'Things to prepare when has disaster?',
      'flood': 'Flood',
      'tsunami': 'Tsunami',
      'landslide': 'Landslide',
      'earthquake': 'Earthquake',
      'no_risk_areas': 'No risk areas available.',
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
      'starter': 'Panisimula',
      'starter_message': 'Mga bagay na ihanda kapag may sakuna?',
      'flood': 'Baha',
      'tsunami': 'Tsunami',
      'landslide': 'Pagguho ng Lupa',
      'earthquake': 'Lindol',
      'no_risk_areas': 'Walang mga lugar ng panganib na magagamit.',
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
      'starter': 'Sugdan',
      'starter_message': 'Mga butang nga iandam kung naay katalagman?',
      'flood': 'Baha',
      'tsunami': 'Tsunami',
      'landslide': 'Lunop',
      'earthquake': 'Linog',
      'no_risk_areas': 'Walay mga lugar nga delikado nga magamit.',
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
  String get starter => translations[_currentLanguage]!['starter']!;
  String get starterMessage =>
      translations[_currentLanguage]!['starter_message']!;
  String get flood => translations[_currentLanguage]!['flood']!;
  String get tsunami => translations[_currentLanguage]!['tsunami']!;
  String get landslide => translations[_currentLanguage]!['landslide']!;
  String get earthquake => translations[_currentLanguage]!['earthquake']!;
  String get noRiskAreas => translations[_currentLanguage]!['no_risk_areas']!;
}
