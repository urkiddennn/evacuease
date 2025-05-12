import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geocoding/geocoding.dart';
import '../Models/home_model.dart';

class Survey {
  // Placeholder to avoid breaking existing references
}

class HomeController {
  final String apiKey = '6ecafe65255292c779f938f49600c1a1';
  late WeatherFactory weatherFactory;
  Weather? currentWeather;
  Position? currentPosition;
  List<RiskArea> riskAreas = [];
  List<RiskArea> allRiskAreas = [];
  Interpreter? _interpreter;
  List<Map<String, dynamic>> barangays = [];

  HomeController() {
    weatherFactory = WeatherFactory(apiKey);
  }

  WeatherData? get weatherData => null;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      print("Model loaded successfully with tflite_flutter");
    } catch (e) {
      print('Error loading TensorFlow Lite model: $e');
      throw Exception('Failed to load TensorFlow Lite model.');
    }
  }

  Future<void> loadBarangayData() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/barangay_hazard_data.json');
      barangays = List<Map<String, dynamic>>.from(jsonDecode(jsonString));
      print("Loaded ${barangays.length} barangays from JSON");
    } catch (e) {
      print('Error loading barangay data: $e');
      throw Exception('Failed to load barangay data.');
    }
  }

  Future<void> fetchCurrentLocationAndWeather() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('No internet connection. Please check your network.');
      }

      currentPosition = await _determinePosition();
      weatherFactory = WeatherFactory(apiKey);
      currentWeather = await weatherFactory.currentWeatherByLocation(
        currentPosition!.latitude,
        currentPosition!.longitude,
      );

      if (currentWeather == null) {
        throw Exception(
            'Failed to fetch weather data. Please check your API key or network.');
      }

      print("Fetched weather data for current location successfully.");
      await loadBarangayData();
      await predictRiskAreas();
      print("Predicted and ranked risk areas successfully.");
    } catch (e) {
      print('Error fetching location or weather: $e');
      throw Exception('Failed to fetch location or weather data: $e');
    }
  }

  Future<void> predictRiskAreas() async {
    if (_interpreter == null) {
      print("Interpreter is null, cannot predict risk areas.");
      throw Exception('TensorFlow Lite model not loaded.');
    }

    List<RiskArea> predictedRiskAreas = [];

    try {
      for (var barangay in barangays) {
        print(
            "Processing barangay: ${barangay["name"]} (Lat: ${barangay["latitude"]}, Lon: ${barangay["longitude"]})");

        final weatherData = await weatherFactory.currentWeatherByLocation(
          barangay["latitude"],
          barangay["longitude"],
        );

        double temperature = weatherData?.temperature?.celsius ?? 25.0;
        double humidity = weatherData?.humidity?.toDouble() ?? 80.0;
        double rainLastHour = weatherData?.rainLastHour?.toDouble() ?? 0.0;

        print(
            "Weather for ${barangay["name"]}: Temp: $temperature°C, Humidity: $humidity%, Rain Last Hour: $rainLastHour mm");

        Map<String, double> hazardScores =
            Map<String, double>.from(barangay["hazardScores"]);
        Map<String, String> hazardLevels =
            Map<String, String>.from(barangay["hazardLevels"]);

        List<double> stormSurgeInput = [
          temperature,
          humidity,
          rainLastHour,
        ];

        var normalizedStormSurgeInput = _normalizeInput(
            stormSurgeInput, [27.5, 75.0, 0.0], [5.0, 15.0, 1.0]);
        var input = [normalizedStormSurgeInput];
        var output = List.filled(1, List.filled(1, 0.0));

        try {
          _interpreter!.run(input, output);
          double stormSurgeScore = output[0][0];
          hazardScores["Storm Surge"] = stormSurgeScore.clamp(1.0, 10.0);
          hazardLevels["Storm Surge"] =
              _mapStormSurgeIntensity(stormSurgeScore);
          print(
              "Storm Surge Score for ${barangay["name"]}: $stormSurgeScore -> Level: ${hazardLevels["Storm Surge"]}");
        } catch (e) {
          print(
              "Error during Storm Surge inference for ${barangay["name"]}: $e");
          hazardScores["Storm Surge"] = 1.0;
          hazardLevels["Storm Surge"] = "Low";
        }

        double overallHazardScore =
            hazardScores.values.reduce((a, b) => a + b) / hazardScores.length;
        String riskLevel = _getRiskLevel(overallHazardScore);
        print(
            "Overall Hazard Score for ${barangay["name"]}: $overallHazardScore -> Risk Level: $riskLevel");

        predictedRiskAreas.add(RiskArea(
          name: barangay["name"],
          riskLevel: riskLevel,
          riskColor: _getRiskColor(hazardScore: overallHazardScore),
          hazardScores: hazardScores,
          hazardLevels: hazardLevels,
        ));
      }

      predictedRiskAreas.sort((a, b) {
        double avgA = a.hazardScores.values.reduce((x, y) => x + y) /
            a.hazardScores.length;
        double avgB = b.hazardScores.values.reduce((x, y) => x + y) /
            b.hazardScores.length;
        return avgB.compareTo(avgA);
      });

      allRiskAreas = predictedRiskAreas;
      riskAreas = predictedRiskAreas.take(3).toList();

      print(
          "All Risk Areas: ${allRiskAreas.map((area) => "${area.name} (${area.riskLevel}, Avg Score: ${area.hazardScores.values.reduce((a, b) => a + b) / area.hazardScores.length})").toList()}");
      print(
          "Top 3 Ranked Risk Areas: ${riskAreas.map((area) => "${area.name} (${area.riskLevel}, Avg Score: ${area.hazardScores.values.reduce((a, b) => a + b) / area.hazardScores.length})").toList()}");

      if (allRiskAreas.isEmpty) {
        throw Exception(
            'No risk areas could be predicted. Check model, weather data, or input data.');
      }
    } catch (e) {
      print("Error during prediction: $e");
      throw Exception('Failed to predict risk areas: $e');
    }
  }

  List<double> _normalizeInput(
      List<double> input, List<double> means, List<double> stds) {
    return List.generate(input.length,
        (i) => (input[i] - means[i]) / (stds[i] != 0 ? stds[i] : 1));
  }

  String _getRiskLevel(double hazardScore) {
    if (hazardScore >= 3.5) return "High";
    if (hazardScore >= 2.5) return "Medium";
    return "Low";
  }

  Color _getRiskColor({required double hazardScore}) {
    if (hazardScore >= 3.5) return Colors.red;
    if (hazardScore >= 2.5) return Colors.orange;
    return Colors.green;
  }

  String _mapStormSurgeIntensity(double score) {
    if (score < 1.5) return "Low";
    if (score < 2.5) return "Medium";
    return "High";
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'Location services are disabled. Please enable them in settings.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
            'Location permissions are denied. Please grant permission in settings.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied. Please enable them in settings.');
    }

    try {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  Future<WeatherData?> getWeatherData() async {
    if (currentWeather == null || currentPosition == null) return null;

    String location;
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        currentPosition!.latitude,
        currentPosition!.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String barangayCandidate = placemark.subLocality?.isNotEmpty == true
            ? placemark.subLocality!
            : placemark.name?.isNotEmpty == true
                ? placemark.name!
                : "";
        String barangay;
        if (barangayCandidate.contains('+') || barangayCandidate.isEmpty) {
          barangay = _getClosestBarangay(
              currentPosition!.latitude, currentPosition!.longitude);
        } else {
          barangay = barangayCandidate;
        }
        String city = placemark.locality?.isNotEmpty == true
            ? placemark.locality!
            : "Unknown";
        String country = placemark.country?.isNotEmpty == true
            ? placemark.country!
            : "Unknown";
        location = "$barangay, $city, $country";
      } else {
        location = _getClosestBarangay(
                currentPosition!.latitude, currentPosition!.longitude) +
            ", Unknown, Unknown";
      }
    } catch (e) {
      print("Error during geocoding: $e");
      location = _getClosestBarangay(
              currentPosition!.latitude, currentPosition!.longitude) +
          ", Unknown, Unknown";
    }

    String weatherCondition = currentWeather!.weatherMain ?? "Unknown";
    double temperature = currentWeather!.temperature?.celsius ?? 25.0;
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

  String _getClosestBarangay(double latitude, double longitude) {
    if (barangays.isEmpty) return "Unknown Barangay";

    var closest = barangays.reduce((a, b) {
      double distA = _calculateDistance(
          latitude, longitude, a["latitude"], a["longitude"]);
      double distB = _calculateDistance(
          latitude, longitude, b["latitude"], b["longitude"]);
      return distA < distB ? a : b;
    });

    return closest["name"];
  }

  void dispose() {
    _interpreter?.close();
  }
}
