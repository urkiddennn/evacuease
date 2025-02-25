import 'package:flutter/material.dart';
import 'package:evacuease/Controllers/home_controller.dart';
import 'package:evacuease/Models/home_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();
  bool _isLoading = true; // Loading state for UI
  String? _errorMessage; // Error message to display

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // Initialize the app by loading the model and fetching weather data
  Future<void> _initializeApp() async {
    try {
      await _controller.loadModel(); // Load TensorFlow Lite model
      await _controller.fetchCurrentLocationAndWeather(); // Fetch weather data

      // Ensure riskAreas is updated before rebuilding
      while (_controller.riskAreas.isEmpty) {
        await Future.delayed(
            Duration(milliseconds: 100)); // Small delay to allow async updates
      }

      setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load data: $e";
      });
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  void dispose() {
    _controller.dispose(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(
        "Risk Areas in UI: ${_controller.riskAreas.map((area) => area.name).toList()}");
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              children: [
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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 3,
                        spreadRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: FutureBuilder<WeatherData?>(
                    future: _controller.getWeatherData(),
                    builder: (context, snapshot) {
                      return _buildWeatherInfo(snapshot);
                    },
                  ),
                ),
                const SizedBox(height: 15),
                _buildStarterSection(),
                const SizedBox(height: 15),
                _buildRiskAreaSection(),
                const SizedBox(height: 15),
                _buildOfflineRiskMapSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Weather Info Widget with Skeleton
  Widget _buildWeatherInfo(AsyncSnapshot<WeatherData?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150,
                  height: 22,
                  color: Colors.grey[300], // Skeleton for location
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 14,
                          color: Colors.grey[300], // Skeleton for condition
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 26,
                          color: Colors.grey[300], // Skeleton for temperature
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300], // Skeleton for icon
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Only proceed if data is available after completion
    if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
      WeatherData weatherData = snapshot.data!;
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weatherData.location,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weatherData.weatherCondition,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${weatherData.temperature.toStringAsFixed(1)} °C',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Image.asset(
                      weatherData.weatherIcon,
                      width: 50,
                      height: 50,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Return an empty container if neither waiting nor done with data
    // This handles initial states or unexpected conditions without showing an error
    return Container();
  }

  // Starter Section
  Widget _buildStarterSection() {
    return Container(
      width: double.infinity,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            spreadRadius: 3,
            offset: const Offset(0, 2),
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
                const Text(
                  "Starter",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Things to prepare when has disaster?",
                  style: TextStyle(color: Colors.grey),
                )
              ],
            ),
            const Icon(
              Icons.arrow_right,
              size: 50,
            )
          ],
        ),
      ),
    );
  }

  // Risk Areas Section with Skeleton Loading
  Widget _buildRiskAreaSection() {
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Risk Area",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 15),
          // Skeleton for 3 items
          ...List.generate(3, (index) => _buildSkeletonRiskAreaItem()),
          const SizedBox(height: 10),
        ],
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }
    if (_controller.riskAreas.isEmpty) {
      return const Text(
        'No risk areas available.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      );
    }

    // Show only top 3 risk areas
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Risk Area",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 15),
        ..._controller.riskAreas
            .take(3)
            .map((area) => _buildRiskAreaItem(area))
            .toList(),
        const SizedBox(height: 10),
      ],
    );
  }

  // Skeleton Risk Area Item
  Widget _buildSkeletonRiskAreaItem() {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 1.0)),
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
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(width: 15),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 20,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 15,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Individual Risk Area Item
  Widget _buildRiskAreaItem(RiskArea area) {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 1.0,
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
                color: area.riskColor,
              ),
            ),
            const SizedBox(width: 15),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  area.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  area.riskLevel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Offline Risk Map Section
  Widget _buildOfflineRiskMapSection() {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Offline Risk Map",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCategoryButton("Flood", "assets/icons/flood.png"),
            _buildCategoryButton("Tsunami", "assets/icons/weather.png"),
            _buildCategoryButton("Landslide", "assets/icons/tape.png"),
            _buildCategoryButton("Earthquake", "assets/icons/earthquake.png"),
          ],
        ),
      ],
    );
  }

  // Category Button for Offline Risk Map
  Widget _buildCategoryButton(String label, String assetPath) {
    return Container(
      width: 60,
      height: 60,
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
}
