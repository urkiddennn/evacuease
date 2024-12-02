import 'package:evacuease/Views/Screens/risk_analysis_page.dart';
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
      return const Text(
        'Loading weather...',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey,
        ),
      );
    }

    String location = "Iran Tago"; // Replace with actual location if available
    String weatherCondition = currentWeather!.weatherMain ?? "Unknown";
    double? temperature = currentWeather!.temperature?.celsius;

    String weatherIcon;
    double iconSize;

    // Assign weather icon based on condition
    switch (weatherCondition.toLowerCase()) {
      case 'rain':
        weatherIcon = "assets/icons/rainy-day.png";

        iconSize = 100;
        break;
      case 'clouds':
        weatherIcon = "assets/icons/cloudy-day.png";

        iconSize = 100;
        break;
      case 'clear':
        weatherIcon = "assets/icons/sun.png";

        iconSize = 100;
        break;
      default:
        weatherIcon = "assets/icons/cloudy-day.png";

        iconSize = 100;
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Location and weather description
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                weatherCondition,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                '${temperature?.toStringAsFixed(1) ?? "--"} °C',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          // Temperature and icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 8),
              Image.asset(
                "${weatherIcon}",
                width: iconSize,
              )
              // Icon(
              // weatherIcon,
              // size: iconSize,
              //color: iconColor,
              // ),
            ],
          ),
        ],
      ),
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

              SizedBox(
                height: 10,
              ),
              // Weather Info
              Container(
                width: double.infinity,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.05), // Shadow color with opacity
                      blurRadius: 3, // Softness of the shadow
                      spreadRadius: 3, // How much the shadow spreads
                      offset: Offset(0, 2), // Position of the shadow (x, y)
                    ),
                  ],
                ),
                child: _buildWeatherInfo(),
              ),
              SizedBox(
                height: 15,
              ),
              Container(
                width: double.infinity,
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.05), // Shadow color with opacity
                      blurRadius: 3, // Softness of the shadow
                      spreadRadius: 3, // How much the shadow spreads
                      offset: Offset(0, 2), // Position of the shadow (x, y)
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Starter",
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Things to prepare when has disaster?",
                            style: TextStyle(color: Colors.grey),
                          )
                        ],
                      ),
                      Icon(
                        Icons.arrow_right,
                        size: 50,
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 15,
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Risk Area",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                height: 15,
              ),

              // Risk Analysis Section
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors
                              .grey, // Change to your desired border color
                          width: 1.0, // Change to your desired border width
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.red),
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Tago Iran",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                                Text(
                                  "Risk High",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.grey),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors
                              .grey, // Change to your desired border color
                          width: 1.0, // Change to your desired border width
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.orange),
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Bangsud",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                                Text(
                                  "Risk mid",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.grey),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors
                              .grey, // Change to your desired border color
                          width: 1.0, // Change to your desired border width
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.yellow),
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Anahao ",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                                Text(
                                  "Risk normal",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.grey),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Center(
                    child: InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RiskAnalysisPage()));
                        },
                        child: Text("Show more")),
                  )
                ],
              ),
              SizedBox(
                height: 15,
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Offline Risk Map",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                height: 15,
              ),

              // Category Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCategoryButton("Flood", "assets/icons/flood.png"),
                  _buildCategoryButton("Tsunami", "assets/icons/weather.png"),
                  _buildCategoryButton("Landslide", "assets/icons/tape.png"),
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
