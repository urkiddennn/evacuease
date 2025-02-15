// lib/Controllers/home_controller.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';
import '../Models/home_model.dart';

class HomeController {
  final String apiKey = '6ecafe65255292c779f938f49600c1a1';
  late WeatherFactory weatherFactory;
  Weather? currentWeather;
  Position? currentPosition;

  List<RiskArea> riskAreas = [
    RiskArea(name: "Tago Iran", riskLevel: "Risk High", riskColor: Colors.red),
    RiskArea(name: "Bangsud", riskLevel: "Risk Mid", riskColor: Colors.orange),
    RiskArea(
        name: "Anahao", riskLevel: "Risk Normal", riskColor: Colors.yellow),
  ];

  Future<void> fetchCurrentLocationAndWeather() async {
    try {
      currentPosition = await _determinePosition();
      weatherFactory = WeatherFactory(apiKey);
      currentWeather = await weatherFactory.currentWeatherByLocation(
        currentPosition!.latitude,
        currentPosition!.longitude,
      );
    } catch (e) {
      print('Error fetching location or weather: $e');
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  WeatherData? getWeatherData() {
    if (currentWeather == null) return null;

    String location = "Iran Tago"; // Replace with actual location if available
    String weatherCondition = currentWeather!.weatherMain ?? "Unknown";
    double? temperature = currentWeather!.temperature?.celsius;

    String weatherIcon;
    switch (weatherCondition.toLowerCase()) {
      case 'rain':
        weatherIcon = "assets/icons/rainy-day.png";
        break;
      case 'clouds':
        weatherIcon = "assets/icons/cloudy-day.png";
        break;
      case 'clear':
        weatherIcon = "assets/icons/sun.png";
        break;
      default:
        weatherIcon = "assets/icons/cloudy-day.png";
    }

    return WeatherData(
      location: location,
      weatherCondition: weatherCondition,
      temperature: temperature,
      weatherIcon: weatherIcon,
    );
  }
}
