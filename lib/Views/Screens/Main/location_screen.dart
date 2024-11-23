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
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// Get the user's current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permissions are denied.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Location permissions are permanently denied. Please enable them in settings.")),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  /// Handle map tap to select a location
  void _onTap(LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  /// Fetch route from current location to selected location
  Future<void> _fetchRoute() async {
    if (_currentLocation == null || _selectedLocation == null) return;

    const apiKey =
        "5b3ce3597851110001cf6248a054cf25d5b943f8a23d1e01143ef5ed"; // Replace with your API key
    final response = await http.get(
      Uri.parse(
          "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${_currentLocation!.longitude},${_currentLocation!.latitude}&end=${_selectedLocation!.longitude},${_selectedLocation!.latitude}"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final geometry = data['features'][0]['geometry']['coordinates'];

      setState(() {
        _routePoints = geometry
            .map<LatLng>((point) => LatLng(point[1], point[0]))
            .toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch route.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map with Routes")),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              // Use the 'center' property instead of 'initialCenter' to properly set the map's center
              initialCenter: _currentLocation ?? LatLng(0, 0),
              initialZoom: 10.0,
              onTap: (tapPosition, point) => _onTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}",
                additionalOptions: {
                  'accessToken':
                      'pk.eyJ1IjoidXJraWRkZW4iLCJhIjoiY20zdG9sdWdoMGJlODJscTJuZ2sxcWM0ayJ9.F3FIfrwfoq-Xl5aWMiXM9w',
                  'id': 'mapbox/streets-v11',
                },
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
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
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
          if (_selectedLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _fetchRoute,
                    child: const Text("Get Route"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
