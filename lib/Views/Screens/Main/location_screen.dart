import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:evacuease/Controllers/location_controller.dart';
import 'package:evacuease/Models/location_model.dart';

class LocationScreen extends StatefulWidget {
  final bool triggerEmergencyRoute;
  final String? emergencyType;

  const LocationScreen({
    Key? key,
    this.triggerEmergencyRoute = false,
    this.emergencyType,
  }) : super(key: key);

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with WidgetsBindingObserver {
  final LocationController _controller = LocationController();
  final MapController _mapController = MapController();
  bool _isMapLoaded = false;
  String? _selectedHazardType;
  late Timer _locationRefreshTimer;
  bool _isNavigating = false;
  bool _hasArrived = false;

  static const String mapboxAccessToken =
      "pk.eyJ1IjoidXJraWRkZW4iLCJhIjoiY20zdG9sdWdoMGJlODJscTJuZ2sxcWM0ayJ9.F3FIfrwfoq-Xl5aWMiXM9w";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.emergencyType != null) {
      _selectedHazardType = widget.emergencyType;
    }
    _initializeLocationAndMap();
    _startLocationAutoRefresh();
    if (widget.triggerEmergencyRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleEmergencyRoute();
      });
    }
    _controller.onArrival = () {
      if (mounted) {
        setState(() {
          _hasArrived = true;
        });
      }
    };
  }

  void _initializeLocationAndMap() async {
    setState(() => _controller.isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Location services are disabled. Please enable them.")),
        );
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied.")),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Location permission permanently denied. Please enable it in settings."),
          ),
        );
        await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception("Location fetch timed out");
      });

      if (mounted) {
        setState(() {
          _controller.currentLocation =
              LatLng(position.latitude, position.longitude);
          _controller.isLoading = false;
        });

        print("Moving map to: ${_controller.currentLocation}");
        _mapController.move(_controller.currentLocation!, 17.0);

        await _controller.updateCurrentPlaceName();
        await _controller.fetchLocations((isLoading) {
          if (mounted) setState(() => _controller.isLoading = isLoading);
        });
        _controller.findNearestLocation();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _controller.isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to get location: $e")),
        );
        print("Initialization error: $e");
        _mapController.move(const LatLng(37.7749, -122.4194), 10.0);
      }
    }

    _controller.startCompass((direction) {
      if (mounted) {
        setState(() {
          _controller.facingDirection = direction;
          if (_isNavigating) _updateMapRotation();
        });
      }
    });
  }

  void _startLocationAutoRefresh() {
    _locationRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _controller.fetchLocations((isLoading) {
        if (mounted) setState(() => _controller.isLoading = isLoading);
      });
      _controller.findNearestLocation();
      setState(() {});
      print("Locations refreshed: ${_controller.locations.length}");
    });
  }

  void _updateMapRotation() {
    if (_controller.currentLocation != null) {
      _mapController.rotate(_controller.facingDirection * (3.14159 / 180));
    }
  }

  Future<void> _handleEmergencyRoute() async {
    final int? familySize = await _showFamilySizeDialog();
    if (familySize != null) {
      await _startNavigation(familySize);
    }
  }

  Future<void> _startNavigation(int familySize) async {
    try {
      await _controller.fetchRouteWithCapacity(familySize, (isLoading) {
        if (mounted) setState(() => _controller.isLoading = isLoading);
      }, hazardType: _selectedHazardType);

      if (_controller.nearestLocations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No suitable evacuation sites found.")),
        );
        return;
      }

      _showNearestLocationsDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error finding route: $e")),
      );
    }
  }

  void _scrollToCurrentLocation() {
    if (_controller.currentLocation != null) {
      _mapController.move(_controller.currentLocation!, 17.0);
      if (_isNavigating) _updateMapRotation();
      print("Scrolled to current location: ${_controller.currentLocation}");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Current location not available.")),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print("App lifecycle state changed to: $state");
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_isNavigating && _controller.nearestLocationLatLng != null) {
        final locationId = _controller.locations
            .firstWhere((loc) =>
                loc.lat == _controller.nearestLocationLatLng!.latitude &&
                loc.lng == _controller.nearestLocationLatLng!.longitude)
            .id;
        _controller.resetCapacity(locationId);
        print("App exited, capacity reset for location: $locationId");
        setState(() {
          _isNavigating = false;
          _hasArrived = false;
          _controller.routePoints.clear();
          _controller.nearestLocation = null;
          _controller.nearestLocationLatLng = null;
          _controller.nearestLocations.clear();
          _controller.nearestLocationsLatLng.clear();
        });
      }
    }
  }

  @override
  void dispose() {
    _locationRefreshTimer.cancel();
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
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

  void _showNearestLocationsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Nearest Evacuation Sites",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select a safe location to navigate to:",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _controller.nearestLocations.length,
                  itemBuilder: (context, index) {
                    final location = _controller.nearestLocations[index];
                    final locModel = _controller.locations
                        .firstWhere((loc) => loc.id == location['id']);
                    final distance = Geolocator.distanceBetween(
                          _controller.currentLocation!.latitude,
                          _controller.currentLocation!.longitude,
                          locModel.lat,
                          locModel.lng,
                        ) /
                        1000; // Convert to kilometers
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: Colors.green, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    location['location_name']!,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Distance: ${distance.toStringAsFixed(2)} km",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                            Text(
                              "Capacity: ${location['capacity']}/${locModel.actualCapacity}",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                            Text(
                              "Hazard Type: ${location['hazard_type']}",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              location['details']!.length > 100
                                  ? "${location['details']!.substring(0, 100)}..."
                                  : location['details']!,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final previousLocationId =
                                      _controller.currentLocationId;
                                  final previousFamilySize =
                                      _controller.currentFamilySize;
                                  _controller.nearestLocation = location;
                                  _controller.nearestLocationLatLng = LatLng(
                                      double.parse(
                                          location['location']!.split(',')[0]),
                                      double.parse(
                                          location['location']!.split(',')[1]));
                                  _controller.currentLocationId =
                                      location['id'];
                                  try {
                                    // If already navigating, restore capacity of previous location
                                    if (_isNavigating &&
                                        previousLocationId != null &&
                                        previousFamilySize != null) {
                                      await _controller
                                          .resetCapacity(previousLocationId);
                                      print(
                                          "Restored capacity for previous location: $previousLocationId");
                                      // Update capacity for new location
                                      final newLocModel = _controller.locations
                                          .firstWhere((loc) =>
                                              loc.id ==
                                              _controller.currentLocationId);
                                      final newCapacity = newLocModel.capacity -
                                          previousFamilySize;
                                      await _controller.updateCapacity(
                                          _controller.currentLocationId!,
                                          newCapacity);
                                      print(
                                          "Updated capacity for new location: ${_controller.currentLocationId}");
                                    }
                                    await _controller.fetchRoute((isLoading) {
                                      setState(() =>
                                          _controller.isLoading = isLoading);
                                    });
                                    if (_controller.routePoints.length < 2) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Route is too short to display.")),
                                      );
                                    } else {
                                      setState(() {
                                        _isNavigating = true;
                                        _hasArrived = false;
                                      });
                                      _mapController.move(
                                          _controller.currentLocation!, 17.0);
                                      _updateMapRotation();
                                    }
                                  } catch (e) {
                                    // If route fetch fails, revert to previous location if available
                                    if (previousLocationId != null &&
                                        previousFamilySize != null) {
                                      _controller.currentLocationId =
                                          previousLocationId;
                                      _controller.currentFamilySize =
                                          previousFamilySize;
                                      _controller.nearestLocationLatLng = LatLng(
                                          double.parse(_controller.nearestLocations
                                              .firstWhere(
                                                  (loc) =>
                                                      loc['id'] ==
                                                      previousLocationId)[
                                                  'location']!
                                              .split(',')[0]),
                                          double.parse(_controller.nearestLocations
                                              .firstWhere((loc) =>
                                                  loc['id'] ==
                                                  previousLocationId)['location']!
                                              .split(',')[1]));
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text("Error fetching route: $e")),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[400],
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("Select",
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _stopNavigation() {
    if (_controller.nearestLocationLatLng != null &&
        _controller.currentLocationId != null) {
      _controller.resetCapacity(_controller.currentLocationId!);
    }
    setState(() {
      _isNavigating = false;
      _hasArrived = false;
      _controller.routePoints.clear();
      _controller.nearestLocation = null;
      _controller.nearestLocationLatLng = null;
      _controller.nearestLocations.clear();
      _controller.nearestLocationsLatLng.clear();
      _controller.currentFamilySize = null;
      _controller.currentLocationId = null;
    });
  }

  void _cancelNavigation() {
    if (_controller.nearestLocationLatLng != null &&
        _controller.currentLocationId != null) {
      _controller.resetCapacity(_controller.currentLocationId!);
    }
    setState(() {
      _isNavigating = false;
      _hasArrived = false;
      _controller.routePoints.clear();
      _controller.nearestLocation = null;
      _controller.nearestLocationLatLng = null;
      _controller.nearestLocations.clear();
      _controller.nearestLocationsLatLng.clear();
      _controller.currentFamilySize = null;
      _controller.currentLocationId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Navigation cancelled, capacity restored.")),
    );
  }

  void _completeNavigation() {
    if (_controller.nearestLocationLatLng != null &&
        _controller.currentLocationId != null) {
      final locationId = _controller.currentLocationId!;
      final location =
          _controller.locations.firstWhere((loc) => loc.id == locationId);
      print(
          "Navigation completed for location: $locationId, capacity remains ${location.capacity}");
    }
    setState(() {
      _isNavigating = false;
      _hasArrived = false;
      _controller.routePoints.clear();
      _controller.nearestLocation = null;
      _controller.nearestLocationLatLng = null;
      _controller.nearestLocations.clear();
      _controller.nearestLocationsLatLng.clear();
      _controller.currentFamilySize = null;
      _controller.currentLocationId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Navigation completed, capacity unchanged.")),
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
                    const LatLng(37.7749, -122.4194),
                initialZoom: _controller.currentLocation != null ? 17.0 : 10.0,
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
                ),
                MarkerLayer(
                  markers: [
                    if (_controller.currentLocation != null)
                      Marker(
                        point: _controller.currentLocation!,
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.navigation,
                            color: Colors.blue, size: 50),
                      ),
                    ..._getFilteredLocations().map((location) {
                      bool isSelected = _isNavigating &&
                          _controller.nearestLocationLatLng != null &&
                          location.lat ==
                              _controller.nearestLocationLatLng!.latitude &&
                          location.lng ==
                              _controller.nearestLocationLatLng!.longitude;
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
                                padding: const EdgeInsets.all(10),
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
                              Icon(
                                Icons.location_on,
                                color: isSelected ? Colors.red : Colors.green,
                                size: 40,
                              ),
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
                          points: _controller.routePoints,
                          color: Colors.red,
                          strokeWidth: 5),
                    ],
                  ),
              ],
            ),
            if (_controller.isLoading)
              Container(
                color: Colors.black38,
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (_controller.currentLocation == null &&
                !_controller.isLoading)
              Container(
                color: Colors.black38,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Unable to fetch location. Please try again.",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeLocationAndMap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
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
            if (_isNavigating) ...[
              Positioned(
                bottom: 80,
                left: 20,
                child: FloatingActionButton(
                  onPressed: _cancelNavigation,
                  backgroundColor: Colors.grey,
                  child: const Icon(Icons.cancel, color: Colors.white),
                ),
              ),
              if (_hasArrived)
                Positioned(
                  bottom: 145,
                  left: 20,
                  child: FloatingActionButton(
                    onPressed: _completeNavigation,
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                ),
              Positioned(
                bottom: _hasArrived ? 210 : 145,
                left: 20,
                child: FloatingActionButton(
                  onPressed: _stopNavigation,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.stop, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_isNavigating) {
            // If already navigating, allow changing evacuation site
            _showNearestLocationsDialog();
          } else {
            final int? familySize = await _showFamilySizeDialog();
            if (familySize != null) {
              await _startNavigation(familySize);
            } else if (_controller.nearestLocationLatLng != null &&
                _controller.currentLocationId != null) {
              _controller.resetCapacity(_controller.currentLocationId!);
            }
          }
        },
        label: Text(_isNavigating ? "Change Evacuation Site" : "Find Route",
            style: const TextStyle(color: Colors.white)),
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
          _isNavigating = false;
          _hasArrived = false;
          _controller.nearestLocation = null;
          _controller.nearestLocationLatLng = null;
          _controller.nearestLocations.clear();
          _controller.nearestLocationsLatLng.clear();
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black26, blurRadius: 10, offset: Offset(0, -2)),
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
                        color: Colors.black87),
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
                  'Capacity: ${location.capacity}/${location.actualCapacity}',
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
                  color: Colors.black87),
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
                    color: Colors.black87),
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
                    final previousLocationId = _controller.currentLocationId;
                    final previousFamilySize = _controller.currentFamilySize;
                    _controller.nearestLocationLatLng =
                        LatLng(location.lat, location.lng);
                    _controller.currentLocationId = location.id;
                    try {
                      if (_isNavigating &&
                          previousLocationId != null &&
                          previousFamilySize != null) {
                        await _controller.resetCapacity(previousLocationId);
                        print(
                            "Restored capacity for previous location: $previousLocationId");
                        final newCapacity =
                            location.capacity - previousFamilySize;
                        await _controller.updateCapacity(
                            location.id, newCapacity);
                        print(
                            "Updated capacity for new location: ${location.id}");
                      }
                      await _controller.fetchRoute((isLoading) {
                        if (mounted)
                          setState(() => _controller.isLoading = isLoading);
                      });
                      if (_controller.routePoints.length < 2) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Route is too short to display.")),
                        );
                      } else {
                        setState(() {
                          _isNavigating = true;
                          _hasArrived = false;
                        });
                        _mapController.move(_controller.currentLocation!, 17.0);
                        _updateMapRotation();
                      }
                    } catch (e) {
                      if (previousLocationId != null &&
                          previousFamilySize != null) {
                        _controller.currentLocationId = previousLocationId;
                        _controller.currentFamilySize = previousFamilySize;
                        _controller.nearestLocationLatLng = LatLng(
                            double.parse(_controller.nearestLocations
                                .firstWhere((loc) =>
                                    loc['id'] ==
                                    previousLocationId)['location']!
                                .split(',')[0]),
                            double.parse(_controller.nearestLocations
                                .firstWhere((loc) =>
                                    loc['id'] ==
                                    previousLocationId)['location']!
                                .split(',')[1]));
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error fetching route: $e")),
                      );
                    }
                  },
                  icon: const Icon(Icons.directions, color: Colors.white),
                  label: const Text("Directions",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text("Close"),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) => setState(() => selectedSize = null),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
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
          child: const Text("Confirm", style: TextStyle(color: Colors.white)),
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
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
