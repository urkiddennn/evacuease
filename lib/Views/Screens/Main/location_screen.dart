import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  LatLng? _currentLocation;
  double _facingDirection = 0.0; // Facing direction in degrees
  List<LatLng> _routePoints = [];
  final MapController _mapController = MapController();

  bool _isLoading = false;
  bool _isMapLoaded = false;

  List<Map<String, String>> _locations = [
    {
      "location_name": "Tago Municipal Gymnasium",
      "details": "Hello this is the Tago Gymnasium",
      "location": "9.019543, 126.233583"
    },
    {
      "location_name": "Purisima National Highschool",
      "details": "Hello this is the Purisima National Highschool",
      "location": "9.015890, 126.235276"
    },
    {
      "location_name": "Falcon National Highschool",
      "details": "Hello this is the Falcon National Highschool",
      "location": "9.018953, 126.232690"
    },
    {
      "location_name": "Falcon Memorial Elementary School",
      "details": "Hello this is the Falcon Memorial Elementary School",
      "location": "9.021448, 126.232637"
    },
    {
      "location_name": "NEMSU TANDAG",
      "details": "NEMSU TANDAG",
      "location": "9.03863, 126.21497"
    }
  ];

  Map<String, String>? _nearestLocation;
  StreamSubscription? _compassSubscription; // Compass subscription

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel(); // Cancel the subscription
    super.dispose();
  }

  /// Start listening to compass data
  void _startCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        setState(() {
          _facingDirection = event.heading!;
        });
      }
    });
  }

  /// Get the user's current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

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
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Move map to the current location
      if (_currentLocation != null) {
        _mapController.move(_currentLocation!, 14.0); // Zoom level 14
        _findNearestLocation();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  /// Find the nearest location from the list
  void _findNearestLocation() {
    if (_currentLocation == null) return;

    double calculateDistance(LatLng a, LatLng b) {
      final Distance distance = Distance();
      return distance.as(LengthUnit.Meter, a, b);
    }

    double? shortestDistance;
    Map<String, String>? nearest;

    for (var location in _locations) {
      final coords = location['location']!.split(',');
      final lat = double.parse(coords[0]);
      final lon = double.parse(coords[1]);
      final distance = calculateDistance(
        _currentLocation!,
        LatLng(lat, lon),
      );

      if (shortestDistance == null || distance < shortestDistance) {
        shortestDistance = distance;
        nearest = location;
      }
    }

    setState(() {
      _nearestLocation = nearest;
    });
  }

  /// Fetch route to the nearest location
  Future<void> _fetchRoute() async {
    if (_currentLocation == null || _nearestLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to find route.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    const apiKey =
        "5b3ce3597851110001cf6248a054cf25d5b943f8a23d1e01143ef5ed"; // Replace with your API key
    final coords = _nearestLocation!['location']!.split(',');
    final endLat = coords[0];
    final endLon = coords[1];

    try {
      final response = await http.get(
        Uri.parse(
            "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${_currentLocation!.longitude},${_currentLocation!.latitude}&end=$endLon,$endLat"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final geometry = data['features'][0]['geometry']['coordinates'];

        setState(() {
          _routePoints = geometry
              .map<LatLng>((point) => LatLng(point[1], point[0]))
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch route.");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Navigate"),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(0, 0), // Placeholder center
              initialZoom: 2.0, // Default zoom
              onMapReady: () => setState(() => _isMapLoaded = true),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 50,
                      height: 50,
                      child: Transform.rotate(
                        angle: _facingDirection *
                            (3.14159265359 / 180), // Convert to radians
                        child: const Icon(Icons.navigation,
                            color: Colors.blue, size: 50),
                      ),
                    ),
                  ],
                ),
              if (_nearestLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        double.parse(
                            _nearestLocation!['location']!.split(',')[0]),
                        double.parse(
                            _nearestLocation!['location']!.split(',')[1]),
                      ),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on,
                          color: Colors.red, size: 40),
                    ),
                  ],
                ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
            ],
          ),
          if (_isLoading || !_isMapLoaded)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchRoute,
        child: const Icon(Icons.directions),
        tooltip: "Navigate to Nearest Location",
      ),
      bottomSheet: _nearestLocation != null
          ? Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "${_nearestLocation!['location_name']}: ${_nearestLocation!['details']}",
                style: const TextStyle(fontSize: 16),
              ),
            )
          : null,
    );
  }
}
