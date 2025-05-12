import 'package:flutter/material.dart';

class Language with ChangeNotifier {
  String _currentLanguage = 'en'; // Default to English

  String get currentLanguage => _currentLanguage;

  void setLanguage(String language) {
    // Validate language code, default to 'en' if invalid
    if (!translations.containsKey(language)) {
      _currentLanguage = 'en';
    } else {
      _currentLanguage = language;
    }
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
      'offline_risk_map': 'Offline Image Risk Map',
      'starter': 'Starter',
      'starter_message': 'Things to prepare when has disaster?',
      'flood': 'Flood',
      'tsunami': 'Tsunami',
      'landslide': 'Landslide',
      'earthquake': 'Earthquake',
      'storm_surge': 'Storm Surge',
      'hazard_rankings': 'Hazard Rankings',
      'no_risk_areas': 'No risk areas available.',
      'see_all': 'See All',
    },
    'tl': {
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
      'offline_risk_map': 'Offline Imahi na Mapa ng Panganib',
      'starter': 'Panisimula',
      'starter_message': 'Mga bagay na ihanda kapag may sakuna?',
      'flood': 'Baha',
      'tsunami': 'Tsunami',
      'landslide': 'Pagguho ng Lupa',
      'earthquake': 'Lindol',
      'storm_surge': 'Storm Surge',
      'hazard_rankings': 'Mga Ranggo ng Panganib',
      'no_risk_areas': 'Walang mga lugar ng panganib na magagamit.',
      'see_all': 'Tingnan Lahat',
    },
    'ceb': {
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
      'offline_risk_map': 'Offline pektyor nga Mapa sa Delikado',
      'starter': 'Sugdan',
      'starter_message': 'Mga butang nga iandam kung naay katalagman?',
      'flood': 'Baha',
      'tsunami': 'Tsunami',
      'landslide': 'Lunop',
      'earthquake': 'Linog',
      'storm_surge': 'Storm Surge',
      'hazard_rankings': 'Mga Ranggo sa Delikado',
      'no_risk_areas': 'Walay mga lugar nga delikado nga magamit.',
      'see_all': 'Tan-awa Tanan',
    },
  };

  // Helper method to safely get translations with fallback
  String _getTranslation(String key, {String fallback = 'Unknown'}) {
    final languageMap = translations[_currentLanguage];
    if (languageMap == null) {
      print("Warning: Language '$_currentLanguage' not found, using 'en'");
      return translations['en']![key] ?? fallback;
    }
    return languageMap[key] ?? translations['en']![key] ?? fallback;
  }

  String get about => _getTranslation('about');
  String get settings => _getTranslation('settings');
  String get language => _getTranslation('language');
  String get logout => _getTranslation('logout');
  String get feedback => _getTranslation('feedback');
  String get reportBug => _getTranslation('report_bug', fallback: 'Report Bug');
  String get sendFeedback =>
      _getTranslation('send_feedback', fallback: 'Send Feedback');
  String get home => _getTranslation('home');
  String get location => _getTranslation('location');
  String get notification => _getTranslation('notification');
  String get user => _getTranslation('user');
  String get riskArea => _getTranslation('risk_area', fallback: 'Risk Area');
  String get offlineRiskMap =>
      _getTranslation('offline_risk_map', fallback: 'Offline Image Risk Map');
  String get starter => _getTranslation('starter');
  String get starterMessage => _getTranslation('starter_message');
  String get flood => _getTranslation('flood');
  String get tsunami => _getTranslation('tsunami');
  String get landslide => _getTranslation('landslide');
  String get earthquake => _getTranslation('earthquake');
  String get stormSurge =>
      _getTranslation('storm_surge', fallback: 'Storm Surge');
  String get hazardRankings =>
      _getTranslation('hazard_rankings', fallback: 'Hazard Rankings');
  String get noRiskAreas =>
      _getTranslation('no_risk_areas', fallback: 'No risk areas available.');
  String get seeAll => _getTranslation('see_all', fallback: 'See All');

  String getHazardLabel(String hazardType) {
    switch (hazardType) {
      case 'Earthquake':
        return earthquake;
      case 'Flood':
        return flood;
      case 'Landslide':
        return landslide;
      case 'Storm Surge':
        return stormSurge;
      case 'Tsunami':
        return tsunami;
      default:
        return hazardType;
    }
  }
}
