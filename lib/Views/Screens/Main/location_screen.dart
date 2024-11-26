import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
  List<LatLng> _routePoints = [];
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  bool _isLoading = false; // For loading indicator
  bool _isMapLoaded = false; // To track if the map is loaded

  final LatLng _fixedLocation = LatLng(10.3157, 123.8854); // Demo location

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  /// Fetch route from current location to the fixed location
  Future<void> _fetchRoute() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Current location not available."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    const apiKey =
        "5b3ce3597851110001cf6248a054cf25d5b943f8a23d1e01143ef5ed"; // Replace with your API key
    try {
      final response = await http.get(
        Uri.parse(
            "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${_currentLocation!.longitude},${_currentLocation!.latitude}&end=${_fixedLocation.longitude},${_fixedLocation.latitude}"),
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
        title: const Text("OSM Map with Navigation"),
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
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location,
                          color: Colors.blue, size: 40),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _fixedLocation,
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
        tooltip: "Navigate to Fixed Location",
      ),
    );
  }
}
