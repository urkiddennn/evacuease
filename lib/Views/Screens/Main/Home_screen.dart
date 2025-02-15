// lib/Views/Screens/Main/home_screen.dart

import 'package:flutter/material.dart';
import 'package:evacuease/Controllers/home_controller.dart';
import 'package:evacuease/Views/Screens/risk_analysis_page.dart';
import 'package:evacuease/Models/home_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();

  @override
  void initState() {
    super.initState();
    _controller.fetchCurrentLocationAndWeather().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final weatherData = _controller.getWeatherData();

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
                  child: _buildWeatherInfo(weatherData),
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

  Widget _buildWeatherInfo(WeatherData? weatherData) {
    if (weatherData == null) {
      return const Text(
        'Loading weather...',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey,
        ),
      );
    }

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
              ),
              const SizedBox(height: 4),
              Text(
                weatherData.weatherCondition,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                '${weatherData.temperature?.toStringAsFixed(1) ?? "--"} °C',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Image.asset(
            weatherData.weatherIcon,
            width: 100,
          ),
        ],
      ),
    );
  }

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

  Widget _buildRiskAreaSection() {
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
            .map((area) => _buildRiskAreaItem(area))
            .toList(),
        const SizedBox(height: 10),
        Center(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RiskAnalysisPage(),
                ),
              );
            },
            child: const Text("Show more"),
          ),
        ),
      ],
    );
  }

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
}
