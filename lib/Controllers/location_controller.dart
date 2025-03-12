import 'dart:async';
import 'dart:convert';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import '../Models/location_model.dart';

class LocationController {
  LatLng? currentLocation;
  double facingDirection = 0.0;
  List<LatLng> routePoints = [];
  bool isLoading = false;
  Map<String, String>? nearestLocation;
  LatLng? nearestLocationLatLng;
  StreamSubscription? compassSubscription;
  StreamSubscription<Position>? positionSubscription;
  String? _currentPlaceName;

  List<LocationModel> locations = [];
  int? currentFamilySize; // Track the family size for the current route
  String? currentLocationId; // Track the current evacuation site ID

  String? get currentLocationName => _currentPlaceName;

  void startCompass(void Function(double) onDirectionChanged) {
    compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        onDirectionChanged(event.heading!);
      }
    });
  }

  Future<void> getCurrentLocation(void Function(bool) onLoadingChanged) async {
    onLoadingChanged(true);
    try {
      print("Checking location service...");
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        throw Exception("Please enable location services and try again.");
      }

      print("Checking permissions...");
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        throw Exception(
            "Location permissions permanently denied. Please enable in settings.");
      }

      print("Getting position...");
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentLocation = LatLng(position.latitude, position.longitude);
      print("Current location: $currentLocation");

      await _updateCurrentPlaceName();
      onLoadingChanged(false);
    } catch (e) {
      print("Error getting location: $e");
      _currentPlaceName = "Error fetching location";
      onLoadingChanged(false);
      throw e;
    }
  }

  Future<void> _updateCurrentPlaceName() async {
    if (currentLocation == null) return;
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        currentLocation!.latitude,
        currentLocation!.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String barangay = place.subLocality ?? '';
        String city = place.locality ?? '';
        String country = place.country ?? '';

        List<String> parts = [];
        if (barangay.isNotEmpty) parts.add("Barangay $barangay");
        if (city.isNotEmpty) parts.add(city);
        if (country.isNotEmpty) parts.add(country);

        _currentPlaceName = parts.join(', ').trim();
        if (_currentPlaceName!.isEmpty) {
          _currentPlaceName = "Unknown Location";
        }
        print("Current place name: $_currentPlaceName");
      } else {
        _currentPlaceName = "Unknown Location";
      }
    } catch (e) {
      print("Error reverse geocoding: $e");
      _currentPlaceName = "Unknown Location";
    }
  }

  Future<void> fetchLocations(void Function(bool) onLoadingChanged) async {
    onLoadingChanged(true);
    try {
      final response = await http.get(
        Uri.parse("https://admin-evacu-ease.vercel.app/api/locations"),
      );
      print("Fetch locations response: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          locations = (data['data'] as List)
              .map((location) => LocationModel.fromJson(location))
              .toList();
          print("Locations fetched: ${locations.length}");
        } else {
          throw Exception("Failed to fetch locations: ${data['message']}");
        }
      } else {
        throw Exception("Failed to fetch locations: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching locations: $e");
      rethrow;
    } finally {
      onLoadingChanged(false);
    }
  }

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
        'travel_time': 'Unknown',
      };
      nearestLocationLatLng = LatLng(nearest.lat, nearest.lng);
      print("Nearest location: ${nearestLocation!['location_name']}");
    }
  }

  Future<void> fetchRoute(void Function(bool) onLoadingChanged) async {
    if (currentLocation == null || nearestLocation == null) {
      throw Exception("Current or nearest location not available.");
    }

    onLoadingChanged(true);

    const apiKey = "5b3ce3597851110001cf6248a054cf25d5b943f8a23d1e01143ef5ed";
    final coords = nearestLocation!['location']!.split(',');
    final endLat = coords[0];
    final endLon = coords[1];
    final start = "${currentLocation!.longitude},${currentLocation!.latitude}";
    final end = "$endLon,$endLat";

    try {
      final url =
          "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=$start&end=$end";
      print("Fetching route from: $url");
      final response = await http.get(Uri.parse(url));

      print("Route response status: ${response.statusCode}");
      print("Route response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final geometry = data['features'][0]['geometry']['coordinates'];
          routePoints = geometry
              .map<LatLng>((point) => LatLng(point[1], point[0]))
              .toList();
          print("Route points fetched: ${routePoints.length}");
        } else {
          throw Exception("No route found in response.");
        }
      } else {
        throw Exception(
            "Failed to fetch route: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching route: $e");
      throw Exception("Error fetching route: $e");
    } finally {
      onLoadingChanged(false);
    }
  }

  Future<void> fetchRouteWithCapacity(
      int familySize, void Function(bool) onLoadingChanged) async {
    if (currentLocation == null || locations.isEmpty) {
      throw Exception("Current location or locations list not available.");
    }

    onLoadingChanged(true);

    // Clear previous route data
    routePoints.clear();
    nearestLocation = null;
    nearestLocationLatLng = null;

    double calculateDistance(LatLng a, LatLng b) {
      final Distance distance = Distance();
      return distance.as(LengthUnit.Meter, a, b);
    }

    LocationModel? suitableLocation;
    double? shortestDistance;

    // Find nearest location with sufficient capacity
    for (var location in locations) {
      final distance = calculateDistance(
          currentLocation!, LatLng(location.lat, location.lng));
      if (location.capacity >= familySize &&
          (shortestDistance == null || distance < shortestDistance!)) {
        shortestDistance = distance;
        suitableLocation = location;
      }
    }

    if (suitableLocation == null) {
      onLoadingChanged(false);
      throw Exception("No evacuation site with sufficient capacity found.");
    }

    nearestLocation = {
      'location': '${suitableLocation.lat},${suitableLocation.lng}',
      'location_name': suitableLocation.name,
      'details': suitableLocation.description,
      'image_url': suitableLocation.images.isNotEmpty
          ? suitableLocation.images.first
          : '',
      'travel_time': 'Unknown',
    };
    nearestLocationLatLng = LatLng(suitableLocation.lat, suitableLocation.lng);

    // Store family size and location ID
    currentFamilySize = familySize;
    currentLocationId = suitableLocation.id;

    // Calculate new capacity
    final newCapacity = suitableLocation.capacity - familySize;
    print(
        "Before update - Location: ${suitableLocation.name}, Capacity: ${suitableLocation.capacity}, Family Size: $familySize, New Capacity: $newCapacity");

    // Update capacity on server
    await _updateCapacity(suitableLocation.id, newCapacity);

    const apiKey = "5b3ce3597851110001cf6248a054cf25d5b943f8a23d1e01143ef5ed";
    final start = "${currentLocation!.longitude},${currentLocation!.latitude}";
    final end = "${suitableLocation.lng},${suitableLocation.lat}";

    try {
      final url =
          "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=$start&end=$end";
      print("Fetching route with capacity from: $url");
      final response = await http.get(Uri.parse(url));

      print("Route response status: ${response.statusCode}");
      print("Route response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final geometry = data['features'][0]['geometry']['coordinates'];
          routePoints = geometry
              .map<LatLng>((point) => LatLng(point[1], point[0]))
              .toList();
          print("Route points fetched: ${routePoints.length}");

          // Start monitoring arrival
          _monitorArrival();
        } else {
          throw Exception("No route found in response.");
        }
      } else {
        throw Exception(
            "Failed to fetch route: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      // Revert capacity on failure
      await _updateCapacity(suitableLocation.id, suitableLocation.capacity);
      print("Error fetching route with capacity: $e");
      throw Exception("Error fetching route: $e");
    } finally {
      onLoadingChanged(false);
    }
  }

  Future<void> _updateCapacity(String locationId, int newCapacity) async {
    final location = locations.firstWhere((loc) => loc.id == locationId);
    final oldCapacity = location.capacity;
    try {
      final response = await http.put(
        Uri.parse(
            "https://admin-evacu-ease.vercel.app/api/locations/$locationId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"capacity": newCapacity}),
      );
      print(
          "Update capacity response: ${response.statusCode}, Body: ${response.body}");
      if (response.statusCode == 200) {
        location.capacity = newCapacity;
        print("Capacity updated for $locationId: $newCapacity");
      } else {
        throw Exception("Failed to update capacity: ${response.statusCode}");
      }
    } catch (e) {
      location.capacity = oldCapacity; // Rollback on failure
      print("Error updating capacity: $e");
      throw e;
    }
  }

  Future<void> resetCapacity(String locationId) async {
    final location = locations.firstWhere((loc) => loc.id == locationId);
    await _updateCapacity(locationId, location.actualCapacity);
    print("Capacity reset for $locationId to ${location.actualCapacity}");
  }

  void _monitorArrival() {
    if (nearestLocationLatLng == null || currentFamilySize == null || currentLocationId == null) return;

    positionSubscription?.cancel(); // Cancel any existing subscription
    positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      currentLocation = LatLng(position.latitude, position.longitude);
      final distance = Geolocator.distanceBetween(
        currentLocation!.latitude,
        currentLocation!.longitude,
        nearestLocationLatLng!.latitude,
        nearestLocationLatLng!.longitude,
      );

      print("Distance to destination: $distance meters");

      if (distance <= 20) { // User is within 20 meters of the destination
        _onArrival();
      }
    });
  }

  Future<void> _onArrival() async {
    if (currentLocationId != null && currentFamilySize != null) {
      final location = locations.firstWhere((loc) => loc.id == currentLocationId!);
      final newCapacity = location.capacity + currentFamilySize!;
      print(
          "User arrived at ${location.name}, restoring capacity: ${location.capacity} + $currentFamilySize = $newCapacity");

      await _updateCapacity(currentLocationId!, newCapacity);
      positionSubscription?.cancel(); // Stop monitoring
      routePoints.clear();
      nearestLocation = null;
      nearestLocationLatLng = null;
      currentFamilySize = null;
      currentLocationId = null;
    }
  }

  void dispose() {
    compassSubscription?.cancel();
    positionSubscription?.cancel();
  }
}
