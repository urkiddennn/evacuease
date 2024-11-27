import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:weather/weather.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String apiKey = '6ecafe65255292c779f938f49600c1a1';
  late WeatherFactory weatherFactory;
  Weather? currentWeather;
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    weatherFactory = WeatherFactory(apiKey);
    _fetchCurrentLocationAndWeather();
  }

  Future<void> _fetchCurrentLocationAndWeather() async {
    try {
      // Get current location
      Position position = await _determinePosition();

      setState(() {
        currentPosition = position;
      });

      // Fetch weather for the current location
      Weather weather = await weatherFactory.currentWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      setState(() {
        currentWeather = weather;
      });
    } catch (e) {
      print('Error fetching location or weather: $e');
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get the current position
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Widget _buildWeatherInfo() {
    if (currentWeather == null) {
      return const Text('Loading weather...',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ));
    }

    String weatherCondition = currentWeather!.weatherMain ?? "Unknown";
    double? temperature = currentWeather!.temperature?.celsius;

    IconData weatherIcon;
    Color iconColor;
    double iconSize;
    switch (weatherCondition.toLowerCase()) {
      case 'rain':
        weatherIcon = Icons.water_drop;
        iconColor = Colors.red;
        iconSize = 23;
        break;
      case 'clouds':
        weatherIcon = Icons.cloud;
        iconColor = Colors.red;
        iconSize = 23;
        break;
      case 'clear':
        weatherIcon = Icons.wb_sunny;
        iconColor = Colors.red;
        iconSize = 23;
        break;
      default:
        weatherIcon = Icons.help;
        iconColor = Colors.red;
        iconSize = 23;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(weatherIcon, size: iconSize, color: iconColor),
        const SizedBox(width: 10),
        Text(
          '${temperature?.toStringAsFixed(1) ?? "--"} °C',
          style: const TextStyle(fontSize: 23, color: Colors.red),
        ),
      ],
    );
  }

  Widget _buildCategoryButton(String label, String assetPath) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(assetPath, width: 30),
          Text(label, style: TextStyle(color: Colors.red[500])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
          child: Column(
            children: [
              // Location Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Colors.grey),
                  Text(
                    currentPosition != null
                        ? "Lat: ${currentPosition!.latitude.toStringAsFixed(2)}, Lon: ${currentPosition!.longitude.toStringAsFixed(2)}"
                        : "Fetching location...",
                  ),
                  const Spacer(),
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.red[500],
                    ),
                    child: const Align(
                      alignment: Alignment.center,
                      child: Text(
                        '3',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              // Weather Info
              Container(
                width: double.infinity,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red)),
                child: _buildWeatherInfo(),
              ),
              SizedBox(
                height: 10,
              ),

              // Map Section
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: currentPosition != null
                        ? LatLng(currentPosition!.latitude,
                            currentPosition!.longitude)
                        : LatLng(9.0745, 126.1981),
                    initialZoom: 16.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.app',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Risk Analysis Section
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Center(child: Text("Risk Analysis")),
              ),
              const SizedBox(height: 15),

              // Category Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCategoryButton("Flood", "assets/icons/flood.png"),
                  _buildCategoryButton("Warning", "assets/icons/warning.png"),
                  _buildCategoryButton(
                      "Earthquake", "assets/icons/earthquake.png"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
