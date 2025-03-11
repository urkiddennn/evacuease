import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:evacuease/Controllers/location_controller.dart';
import 'package:evacuease/Models/location_model.dart';

class LocationScreen extends StatefulWidget {
  final bool triggerEmergencyRoute;
  const LocationScreen({Key? key, this.triggerEmergencyRoute = false})
      : super(key: key);

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final LocationController _controller = LocationController();
  final MapController _mapController = MapController();
  bool _isMapLoaded = false;
  String? _selectedHazardType;
  late Timer _locationRefreshTimer;

  static const String mapboxAccessToken =
      "pk.eyJ1IjoidXJraWRkZW4iLCJhIjoiY20zdG9sdWdoMGJlODJscTJuZ2sxcWM0ayJ9.F3FIfrwfoq-Xl5aWMiXM9w";

  @override
  void initState() {
    super.initState();
    _initializeLocationAndMap();
    _startLocationAutoRefresh();
    if (widget.triggerEmergencyRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleEmergencyRoute();
      });
    }
  }

  void _initializeLocationAndMap() async {
    _controller.startCompass((direction) {
      if (mounted) {
        setState(() {
          _controller.facingDirection = direction;
        });
      }
    });

    try {
      await _controller.getCurrentLocation((isLoading) {
        if (mounted) {
          setState(() {
            _controller.isLoading = isLoading;
          });
        }
      }).timeout(const Duration(seconds: 10), onTimeout: () {
        print("Location fetch timed out");
        setState(() => _controller.isLoading = false);
      });

      if (_controller.currentLocation != null) {
        print("Moving map to: ${_controller.currentLocation}");
        _mapController.move(_controller.currentLocation!, 17.0);

        await _controller.fetchLocations((isLoading) {
          if (mounted) {
            setState(() {
              _controller.isLoading = isLoading;
            });
          }
        });
        _controller.findNearestLocation();
        setState(() {});
      } else {
        print("No current location, falling back to default");
        _mapController.move(LatLng(37.7749, -122.4194), 10.0); // San Francisco
      }
    } catch (e) {
      print("Initialization error: $e");
      setState(() => _controller.isLoading = false);
    }
  }

  void _startLocationAutoRefresh() {
    _locationRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _controller.fetchLocations((isLoading) {
        if (mounted) {
          setState(() {
            _controller.isLoading = isLoading;
          });
        }
      });
      _controller.findNearestLocation();
      setState(() {});
      print("Locations refreshed: ${_controller.locations.length}");
    });
  }

  Future<void> _handleEmergencyRoute() async {
    final int? familySize = await _showFamilySizeDialog();
    if (familySize != null) {
      try {
        await _controller.fetchRouteWithCapacity(familySize, (isLoading) {
          if (mounted) {
            setState(() {
              _controller.isLoading = isLoading;
            });
          }
        });
        if (_controller.routePoints.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Route is too short to display.")),
          );
        } else if (_controller.nearestLocation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No suitable evacuation site found.")),
          );
        } else {
          setState(() {});
          _mapController.move(_controller.nearestLocationLatLng!, 17.0);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error finding route: $e")),
        );
      }
    }
  }

  void _scrollToCurrentLocation() {
    if (_controller.currentLocation != null) {
      _mapController.move(_controller.currentLocation!, 17.0);
      print("Scrolled to current location: ${_controller.currentLocation}");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Current location not available.")),
      );
    }
  }

  @override
  void dispose() {
    _locationRefreshTimer.cancel();
    _controller.dispose();
    super.dispose();
  }

  List<LocationModel> _getFilteredLocations() {
    if (_selectedHazardType == null) return _controller.locations;
    return _controller.locations
        .where((location) => location.hazardType == _selectedHazardType)
        .toList();
  }

  Future<int?> _showFamilySizeDialog() async {
    return showDialog<int>(
      context: context,
      builder: (context) => const FamilySizeDialog(),
    );
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
                initialCenter: _controller.currentLocation ??
                    LatLng(37.7749, -122.4194),
                initialZoom: _controller.currentLocation != null ? 20.0 : 15.0,
                onMapReady: () {
                  print("Map is ready");
                  setState(() => _isMapLoaded = true);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/tiles/{z}/{x}/{y}?access_token=$mapboxAccessToken',
                  additionalOptions: {
                    'accessToken': mapboxAccessToken,
                    'id': 'mapbox/satellite-streets-v12',
                  },
                  userAgentPackageName: 'com.example.evacuease',
                  errorImage:
                      const NetworkImage('https://via.placeholder.com/256'),
                ),
                MarkerLayer(
                  markers: [
                    if (_controller.currentLocation != null)
                      Marker(
                        point: _controller.currentLocation!,
                        width: 50,
                        height: 50,
                        child: Transform.rotate(
                          angle: _controller.facingDirection * (3.14159 / 180),
                          child: const Icon(Icons.navigation,
                              color: Colors.blue, size: 50),
                        ),
                      ),
                    ..._getFilteredLocations().map((location) {
                      return Marker(
                        point: LatLng(location.lat, location.lng),
                        width: 100,
                        height: 100,
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) =>
                                  _buildLocationDetails(location),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                height: 50,
                                width: 40,
                                padding: const EdgeInsets.all(10), // Fixed typo here
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
                              const Icon(Icons.location_on,
                                  color: Colors.green, size: 40),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
                if (_controller.routePoints.isNotEmpty &&
                    _controller.routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        pattern: StrokePattern.dashed(segments: const [10, 10]),
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
                child: const Center(child: CircularProgressIndicator()),
              ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, color: Colors.red[500], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _controller.currentLocationName ??
                            'Fetching location...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 60,
              left: 10,
              right: 10,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  _buildHazardButton("Flood", Colors.blue, Icons.water),
                  _buildHazardButton(
                      "Earthquake", Colors.orange, Icons.vibration),
                  _buildHazardButton("Typhoon", Colors.purple, Icons.storm),
                  _buildHazardButton("Tsunami", Colors.red, Icons.waves),
                  _buildHazardButton("All", Colors.grey, Icons.all_inclusive,
                      isClear: true),
                ],
              ),
            ),
            Positioned(
              bottom: 15,
              left: 20,
              child: FloatingActionButton(
                onPressed: _scrollToCurrentLocation,
                backgroundColor: Colors.red[400],
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final int? familySize = await _showFamilySizeDialog();
          if (familySize != null) {
            try {
              await _controller.fetchRouteWithCapacity(familySize, (isLoading) {
                if (mounted) {
                  setState(() {
                    _controller.isLoading = isLoading;
                  });
                }
              });
              if (_controller.routePoints.length < 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Route is too short to display.")),
                );
              } else if (_controller.nearestLocation == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("No suitable evacuation site found.")),
                );
              } else {
                setState(() {});
                _mapController.move(_controller.nearestLocationLatLng!, 17.0);
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        },
        label: const Text("Find Route", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.directions, color: Colors.white),
        backgroundColor: Colors.red[400],
      ),
    );
  }

  Widget _buildHazardButton(String type, Color color, IconData icon,
      {bool isClear = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedHazardType = isClear ? null : type;
          _controller.routePoints.clear();
        });
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 90),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedHazardType == type ||
                    (isClear && _selectedHazardType == null)
                ? color
                : Colors.grey,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _selectedHazardType == type ||
                      (isClear && _selectedHazardType == null)
                  ? color
                  : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              type,
              style: TextStyle(
                color: _selectedHazardType == type ||
                        (isClear && _selectedHazardType == null)
                    ? color
                    : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDetails(LocationModel location) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    location.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (location.images.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  location.images.first,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                const Icon(Icons.location_pin, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location.locationName,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Capacity: ${location.capacity}',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Contact Person: ${location.contactPersonName ?? "N/A"}',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.visibility, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Visibility: ${location.visibility}',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Hazard Type: ${location.hazardType}',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              location.description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (location.contacts.isNotEmpty) ...[
              const Text(
                'Contacts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              ...location.contacts.map((contact) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            contact,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await _controller.fetchRoute((isLoading) {
                        if (mounted) {
                          setState(() {
                            _controller.isLoading = isLoading;
                          });
                        }
                      });
                      if (_controller.routePoints.length < 2) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Route is too short to display.")),
                        );
                      }
                      setState(() {});
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  icon: const Icon(Icons.directions, color: Colors.white),
                  label: const Text("Directions",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text("Close"),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FamilySizeDialog extends StatefulWidget {
  const FamilySizeDialog({super.key});

  @override
  _FamilySizeDialogState createState() => _FamilySizeDialogState();
}

class _FamilySizeDialogState extends State<FamilySizeDialog> {
  int? selectedSize;
  final TextEditingController personsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Family Size",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select or enter the number of family members:",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPredefinedOption(3),
                _buildPredefinedOption(5),
                _buildPredefinedOption(7),
                _buildPredefinedOption(10),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: personsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Custom number",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                setState(() {
                  selectedSize = null;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text(
            "Cancel",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            int? value;
            if (personsController.text.isNotEmpty) {
              value = int.tryParse(personsController.text.trim());
            } else {
              value = selectedSize;
            }
            if (value == null || value <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Please select or enter a valid number")),
              );
              return;
            }
            Navigator.pop(context, value);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[400],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text(
            "Confirm",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPredefinedOption(int value) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedSize = value;
          print("Selected predefined size: $value");
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selectedSize == value ? Colors.red[400] : Colors.red[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[400]!),
        ),
        child: Center(
          child: Text(
            "$value",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
