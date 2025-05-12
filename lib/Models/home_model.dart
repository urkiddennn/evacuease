import 'dart:ui';

class WeatherData {
  final String location;
  final String weatherCondition;
  final double temperature;
  final String weatherIcon;

  WeatherData({
    required this.location,
    required this.weatherCondition,
    required this.temperature,
    required this.weatherIcon,
  });
}

class RiskArea {
  final String name;
  final String riskLevel;
  final Color riskColor;
  final Map<String, double> hazardScores;
  final Map<String, String> hazardLevels;

  RiskArea({
    required this.name,
    required this.riskLevel,
    required this.riskColor,
    required this.hazardScores,
    required this.hazardLevels,
  });
}
