// lib/Models/home_model.dart

import 'dart:ui';

class WeatherData {
  final String location;
  final String weatherCondition;
  final double? temperature;
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

  RiskArea({
    required this.name,
    required this.riskLevel,
    required this.riskColor,
  });
}
