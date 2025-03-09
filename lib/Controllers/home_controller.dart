import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geocoding/geocoding.dart';
import '../Models/home_model.dart';

class HomeController {
  final String apiKey = '6ecafe65255292c779f938f49600c1a1';
  late WeatherFactory weatherFactory;
  Weather? currentWeather;
  Position? currentPosition;
  List<RiskArea> riskAreas = []; // Top 3 for HomeScreen
  List<RiskArea> allRiskAreas = []; // All barangays for RiskAreaScreen
  Interpreter? _interpreter;

  final List<Map<String, dynamic>> barangays = [
    {
      "name": "Alba",
      "latitude": 8.9674781,
      "longitude": 126.1346125,
      "hazardLevels": [0, 0, 3, 1, 2]
    },
    {
      "name": "Anahao Bag-o",
      "latitude": 8.9632271,
      "longitude": 126.1606863,
      "hazardLevels": [0, 0, 2, 1, 2]
    },
    {
      "name": "Anahao Daan",
      "latitude": 8.9632548,
      "longitude": 126.1719341,
      "hazardLevels": [0, 0, 2, 1, 3]
    },
    {
      "name": "Badong",
      "latitude": 8.9476053,
      "longitude": 126.1011226,
      "hazardLevels": [0, 0, 2, 3, 3]
    },
    {
      "name": "Bajao",
      "latitude": 8.9854513,
      "longitude": 126.1533773,
      "hazardLevels": [0, 0, 2, 1, 3]
    },
    {
      "name": "Bangsud",
      "latitude": 8.9596191,
      "longitude": 126.1464998,
      "hazardLevels": [0, 0, 2, 2, 1]
    },
    {
      "name": "Cabangahan",
      "latitude": 8.9604729,
      "longitude": 126.0946154,
      "hazardLevels": [0, 0, 2, 2, 2]
    },
    {
      "name": "Cagdapao",
      "latitude": 8.9954761,
      "longitude": 126.1558127,
      "hazardLevels": [0, 0, 2, 1, 2]
    },
    {
      "name": "Camagong",
      "latitude": 9.0017070,
      "longitude": 126.1932886,
      "hazardLevels": [0, 0, 2, 1, 3]
    },
    {
      "name": "Caras-an",
      "latitude": 8.8976866,
      "longitude": 126.0926214,
      "hazardLevels": [0, 0, 3, 2, 2]
    },
    {
      "name": "Cayale",
      "latitude": 8.9838246,
      "longitude": 126.1189457,
      "hazardLevels": [0, 0, 2, 2, 1]
    },
    {
      "name": "Dayo-an",
      "latitude": 9.0259144,
      "longitude": 126.1853197,
      "hazardLevels": [0, 0, 2, 1, 2]
    },
    {
      "name": "Gamut",
      "latitude": 9.0046211,
      "longitude": 126.1670673,
      "hazardLevels": [0, 0, 2, 2, 2]
    },
    {
      "name": "Jubang",
      "latitude": 8.9839995,
      "longitude": 126.2262931,
      "hazardLevels": [0, 0, 2, 1, 3]
    },
    {
      "name": "Kinabigtasan",
      "latitude": 8.9783538,
      "longitude": 126.1774005,
      "hazardLevels": [0, 0, 2, 1, 2]
    },
    {
      "name": "Layog",
      "latitude": 8.9177761,
      "longitude": 126.0959676,
      "hazardLevels": [0, 0, 2, 2, 1]
    },
    {
      "name": "Lindoy",
      "latitude": 8.9448407,
      "longitude": 126.1342049,
      "hazardLevels": [0, 0, 2, 3, 1]
    },
    {
      "name": "Mercedes",
      "latitude": 0.0,
      "longitude": 0.0,
      "hazardLevels": [0, 0, 2, 1, 3]
    },
    {
      "name": "Purisima (Pob.)",
      "latitude": 9.0178894,
      "longitude": 126.2335553,
      "hazardLevels": [0, 0, 2, 1, 3]
    },
    {
      "name": "Sumo-sumo",
      "latitude": 8.977167,
      "longitude": 126.238405,
      "hazardLevels": [0, 0, 2, 2, 1]
    },
    {
      "name": "Umbay",
      "latitude": 8.9867111,
      "longitude": 126.2361208,
      "hazardLevels": [0, 0, 2, 1, 3]
    },
    {
      "name": "Unaban",
      "latitude": 8.9949463,
      "longitude": 126.1889326,
      "hazardLevels": [0, 0, 2, 1, 3]
    },
    {
      "name": "Unidos",
      "latitude": 8.9853186,
      "longitude": 126.2020099,
      "hazardLevels": [0, 0, 2, 1, 2]
    },
    {
      "name": "Victoria",
      "latitude": 9.0348458,
      "longitude": 126.2097035,
      "hazardLevels": [0, 0, 2, 1, 3]
    },
  ];

  HomeController() {
    weatherFactory = WeatherFactory(apiKey);
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      print("Model loaded successfully with tflite_flutter");
    } catch (e) {
      print('Error loading TensorFlow Lite model: $e');
      throw Exception('Failed to load TensorFlow Lite model.');
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

        if (!barangay.containsKey("hazardLevels") ||
            !barangay.containsKey("latitude") ||
            !barangay.containsKey("longitude")) {
          print("Invalid barangay data for ${barangay["name"]}. Skipping...");
          continue;
        }

        List<double> inputData = [
          ...barangay["hazardLevels"].map((value) => value.toDouble()).toList(),
          temperature,
          humidity,
          rainLastHour,
        ];

        print("Raw Input Data for ${barangay["name"]}: $inputData");

        var normalizedData = _normalizeInput(inputData);
        print("Normalized Input Data for ${barangay["name"]}: $normalizedData");

        if (normalizedData.length != 8) {
          print(
              "Invalid input data length for ${barangay["name"]}: ${normalizedData.length}. Skipping...");
          continue;
        }

        var input = [normalizedData]; // Shape: [1, 8]
        var output = List.filled(1, List.filled(1, 0.0)); // Shape: [1, 1]

        try {
          _interpreter!.run(input, output);
          double hazardScore = output[0][0];
          String riskLevel = _getRiskLevel(hazardScore);
          print(
              "Hazard Score for ${barangay["name"]}: $hazardScore -> Risk Level: $riskLevel");

          predictedRiskAreas.add(RiskArea(
            name: barangay["name"],
            riskLevel: riskLevel,
            riskColor: _getRiskColor(hazardScore),
            hazardScore: hazardScore,
          ));
        } catch (e) {
          print("Error during model inference for ${barangay["name"]}: $e");
          predictedRiskAreas.add(RiskArea(
            name: barangay["name"],
            riskLevel: "Unknown",
            riskColor: Colors.grey,
            hazardScore: 0.0,
          ));
        }
      }

      // Sort by hazardScore numerically (high to low)
      predictedRiskAreas.sort((a, b) => b.hazardScore.compareTo(a.hazardScore));
      // Store all predicted areas
      allRiskAreas = predictedRiskAreas;
      // Limit to top 3 for HomeScreen
      riskAreas = predictedRiskAreas.take(3).toList();

      print(
          "All Risk Areas: ${allRiskAreas.map((area) => "${area.name} (${area.riskLevel}, Score: ${area.hazardScore})").toList()}");
      print(
          "Top 3 Ranked Risk Areas: ${riskAreas.map((area) => "${area.name} (${area.riskLevel}, Score: ${area.hazardScore})").toList()}");

      if (allRiskAreas.isEmpty) {
        throw Exception(
            'No risk areas could be predicted. Check model, weather data, or input data.');
      }
    } catch (e) {
      print("Error during prediction: $e");
      throw Exception('Failed to predict risk areas: $e');
    }
  }

  List<double> _normalizeInput(List<double> input) {
    List<double> means = [1.5, 1.5, 2.5, 1.5, 2.0, 27.5, 75.0, 0.0];
    List<double> stds = [0.5, 0.5, 0.5, 0.5, 0.5, 5.0, 15.0, 1.0];
    return List.generate(input.length, (i) => (input[i] - means[i]) / stds[i]);
  }

  String _getRiskLevel(double hazardScore) {
    if (hazardScore >= 14.7) return "High";
    if (hazardScore >= 12.9) return "Medium";
    return "Low";
  }

  Color _getRiskColor(double hazardScore) {
    if (hazardScore >= 14.7) return Colors.red;
    if (hazardScore >= 12.9) return Colors.orange;
    return Colors.green;
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
