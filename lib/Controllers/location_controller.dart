import 'dart:async';
import 'dart:convert';

import '../Models/location_model.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class LocationController {
  LatLng? currentLocation;
  double facingDirection = 0.0;
  List<LatLng> routePoints = [];
  bool isLoading = false;
  Map<String, String>? nearestLocation;
  StreamSubscription? compassSubscription;

  List<LocationModel> locations = [];

  /// Start listening to compass data
  void startCompass(void Function(double) onDirectionChanged) {
    compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        onDirectionChanged(event.heading!);
      }
    });
  }

  /// Get the user's current location
  Future<void> getCurrentLocation(void Function(bool) onLoadingChanged) async {
    onLoadingChanged(true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            "Location permissions are permanently denied. Please enable them in settings.");
      }

      final position = await Geolocator.getCurrentPosition();
      currentLocation = LatLng(position.latitude, position.longitude);
      onLoadingChanged(false);
    } catch (e) {
      onLoadingChanged(false);
      throw e;
    }
  }

  /// Fetch locations from the API
  Future<void> fetchLocations(void Function(bool) onLoadingChanged) async {
    onLoadingChanged(true);

    try {
      final response = await http.get(
        Uri.parse(
            "https://admin-evacu-ease.vercel.app/api/locations"), // Fix the typo
      );

      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          locations = (data['data'] as List)
              .map((location) => LocationModel.fromJson(location))
              .toList();
        } else {
          throw Exception("Failed to fetch locations.");
        }
      } else {
        throw Exception("Failed to fetch locations.");
      }
    } catch (e) {
      print("Error: $e"); // Log the actual error
      rethrow;
    } finally {
      onLoadingChanged(false);
    }
  }

  /// Find the nearest location from the list
  void findNearestLocation() {
    if (currentLocation == null) return;

    double calculateDistance(LatLng a, LatLng b) {
      final Distance distance = Distance();
      return distance.as(LengthUnit.Meter, a, b);
    }

    double? shortestDistance;
    LocationModel? nearest;

    for (var location in locations) {
      final distance = calculateDistance(
          currentLocation!, LatLng(location.lat, location.lng));

      if (shortestDistance == null || distance < shortestDistance) {
        shortestDistance = distance;
        nearest = location;
      }
    }

    if (nearest != null) {
      nearestLocation = {
        'location': '${nearest.lat},${nearest.lng}',
        'location_name': nearest.name,
        'details': nearest.description,
        'image_url': nearest.images.isNotEmpty ? nearest.images.first : '',
        'travel_time': 'Unknown', // You can calculate this if you have the data
      };
    }
  }

  /// Fetch route to the nearest location
  Future<void> fetchRoute(void Function(bool) onLoadingChanged) async {
    if (currentLocation == null || nearestLocation == null) {
      throw Exception("Unable to find route.");
    }

    onLoadingChanged(true);

    const apiKey =
        "5b3ce3597851110001cf6248a054cf25d5b943f8a23d1e01143ef5ed"; // Replace with your API key
    final coords = nearestLocation!['location']!.split(',');
    final endLat = coords[0];
    final endLon = coords[1];

    try {
      final response = await http.get(
        Uri.parse(
            "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${currentLocation!.longitude},${currentLocation!.latitude}&end=$endLon,$endLat"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final geometry = data['features'][0]['geometry']['coordinates'];

        routePoints = geometry
            .map<LatLng>((point) => LatLng(point[1], point[0]))
            .toList();
        onLoadingChanged(false);
      } else {
        throw Exception("Failed to fetch route.");
      }
    } catch (e) {
      onLoadingChanged(false);
      throw e;
    }
  }

  @override
  void dispose() {
    compassSubscription?.cancel();
  }
}
