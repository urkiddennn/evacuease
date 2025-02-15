// lib/Views/Screens/Main/location_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:evacuease/Controllers/location_controller.dart';
import 'package:evacuease/Models/location_model.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final LocationController _controller = LocationController();
  final MapController _mapController = MapController();
  bool _isMapLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller.startCompass((direction) {
      setState(() {
        _controller.facingDirection = direction;
      });
    });
    _controller.getCurrentLocation((isLoading) {
      setState(() {
        _controller.isLoading = isLoading;
      });
      if (_controller.currentLocation != null) {
        _mapController.move(_controller.currentLocation!, 17.0);
        _controller.fetchLocations((isLoading) {
          setState(() {
            _controller.isLoading = isLoading;
          });
          _controller.findNearestLocation();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(0, 0), // Placeholder center
                initialZoom: 10.0, // Default zoom
                onMapReady: () => setState(() => _isMapLoaded = true),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    if (_controller.currentLocation != null)
                      Marker(
                        point: _controller.currentLocation!,
                        width: 50,
                        height: 50,
                        child: Transform.rotate(
                          angle: _controller.facingDirection *
                              (3.14159265359 / 180),
                          child: const Icon(Icons.navigation,
                              color: Colors.blue, size: 50),
                        ),
                      ),
                    ..._controller.locations.map((location) {
                      return Marker(
                        point: LatLng(location.lat, location.lng),
                        width: 100,
                        height: 100,
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return _buildLocationDetails(location);
                              },
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                height: 50,
                                width: 40,
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 3,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    "Cap${location.capacity}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return _buildLocationDetails(location);
                                    },
                                  );
                                },
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.green,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
                // if (_controller.nearestLocation != null)
                //   MarkerLayer(
                //     markers: [
                //       Marker(
                //         point: LatLng(
                //           double.parse(_controller.nearestLocation!['location']!
                //               .split(',')[0]),
                //           double.parse(_controller.nearestLocation!['location']!
                //               .split(',')[1]),
                //         ),
                //         width: 50,
                //         height: 50,
                //         child: const Icon(
                //           Icons.location_pin,
                //           color: Colors.red,
                //           size: 40,
                //         ),
                //       ),
                //     ],
                //   ),
                if (_controller.routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        pattern: StrokePattern.dashed(segments: const [10]),
                        points: _controller.routePoints,
                        color: Colors.red,
                        strokeWidth: 5,
                      ),
                    ],
                  ),
              ],
            ),
            if (_controller.isLoading)
              Container(
                color: Colors.black38,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            await _controller.fetchRoute((isLoading) {
              setState(() {
                _controller.isLoading = isLoading;
              });
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          }
        },
        label: const Text(
          "Find Route",
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(
          Icons.directions,
          color: Colors.white,
        ),
        backgroundColor: Colors.red[400],
      ),
    );
  }

  Widget _buildLocationDetails(LocationModel location) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 21),
                    ),
                    Text(
                      'Capacity: ${location.capacity}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            location.description,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              InkWell(
                onTap: () {},
                child: Container(
                  width: 80,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(width: 1.0, color: Colors.grey),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(Icons.route, size: 15),
                        Text("Routes"),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 80,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(width: 1.0, color: Colors.grey),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(Icons.close, size: 15),
                        Text("Close"),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (location.images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(5.0),
              child: Image.network(
                location.images.first,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}
