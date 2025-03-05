import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evacuease/Controllers/home_controller.dart';
import 'package:evacuease/Models/home_model.dart';
import '../../../Controllers/language.dart';
import '../../../routes/route_names.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final controller = Provider.of<HomeController>(context, listen: false);
    try {
      await controller.loadModel();
      await controller.fetchCurrentLocationAndWeather();
      while (controller.riskAreas.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      _errorMessage = "Failed to load data: $e";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<Language>(context);
    final controller = Provider.of<HomeController>(context);
    print(
        "Risk Areas in UI: ${controller.riskAreas.map((area) => area.name).toList()}");
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeatherInfoSection(context),
                const SizedBox(height: 15),
                _buildStarterSection(context),
                const SizedBox(height: 15),
                _buildRiskAreaSection(context),
                const SizedBox(height: 15),
                _buildOfflineRiskMapSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Weather Info Section
  Widget _buildWeatherInfoSection(BuildContext context) {
    final controller = Provider.of<HomeController>(context);
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 100,
        maxHeight: MediaQuery.of(context).size.height * 0.150,
      ),
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
        future:
            Future.delayed(Duration.zero, () => controller.getWeatherData()),
        builder: (context, snapshot) {
          return _buildWeatherInfo(context, snapshot);
        },
      ),
    );
  }

  Widget _buildWeatherInfo(
      BuildContext context, AsyncSnapshot<WeatherData?> snapshot) {
    if (_isLoading || snapshot.connectionState == ConnectionState.waiting) {
      return _buildWeatherSkeleton(context);
    }

    if (snapshot.hasData) {
      WeatherData weatherData = snapshot.data!;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Column(
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
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              weatherData.weatherCondition,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${weatherData.temperature?.toStringAsFixed(1) ?? "--"} °C',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Image.asset(
                        weatherData.weatherIcon,
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _buildWeatherSkeleton(context);
  }

  Widget _buildWeatherSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: 22,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.2,
                        height: 14,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.25,
                        height: 26,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Starter Section
  Widget _buildStarterSection(BuildContext context) {
    final language = Provider.of<Language>(context);
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 80,
        maxHeight: MediaQuery.of(context).size.height * 0.15,
      ),
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
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.starter,
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    language.starterMessage,
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_right,
              size: 50,
            ),
          ],
        ),
      ),
    );
  }

  // Risk Areas Section
  Widget _buildRiskAreaSection(BuildContext context) {
    final language = Provider.of<Language>(context);
    final controller = Provider.of<HomeController>(context);
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                language.riskArea,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: null, // Disabled during loading
                child: Text(language.seeAll,
                    style: const TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...List.generate(3, (index) => _buildSkeletonRiskAreaItem(context)),
          const SizedBox(height: 10),
        ],
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }
    if (controller.riskAreas.isEmpty) {
      return Text(
        language.noRiskAreas,
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              language.riskArea,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, RouteNames.riskArea);
              },
              child: Text(language.seeAll,
                  style: const TextStyle(color: Colors.blue)),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ...controller.riskAreas
            .take(5)
            .map((area) => _buildRiskAreaItem(context, area))
            .toList(),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSkeletonRiskAreaItem(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.1,
      decoration: const BoxDecoration(
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
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: 20,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Container(
                  width: MediaQuery.of(context).size.width * 0.2,
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

  Widget _buildRiskAreaItem(BuildContext context, RiskArea area) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.1,
      decoration: const BoxDecoration(
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
                color: area.riskColor,
              ),
            ),
            const SizedBox(width: 15),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    area.riskLevel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Offline Risk Map Section
  Widget _buildOfflineRiskMapSection(BuildContext context) {
    final language = Provider.of<Language>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            language.offlineRiskMap,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 15),
        Center(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildCategoryButton(context, language.flood,
                  "assets/icons/flood.png", "assets/images/flood.jpg"),
              _buildCategoryButton(context, language.tsunami,
                  "assets/icons/weather.png", "assets/images/tsunami.jpg"),
              _buildCategoryButton(context, language.landslide,
                  "assets/icons/tape.png", "assets/images/landslide.jpg"),
              _buildCategoryButton(
                  context,
                  language.earthquake,
                  "assets/icons/earthquake.png",
                  "assets/images/earthquake.jpg"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryButton(BuildContext context, String label,
      String assetPath, String mapImagePath) {
    return GestureDetector(
      onTap: () {
        _showFullMap(context, mapImagePath, label);
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.18,
        height: MediaQuery.of(context).size.width * 0.18,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              assetPath,
              width: 30,
              height: 30,
              fit: BoxFit.contain,
            ),
            Text(
              label,
              style: TextStyle(color: Colors.red[500], fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showFullMap(BuildContext context, String mapImagePath, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black54,
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(0), // Stop at edges
                  minScale: 0.5, // Minimum zoom level (slightly compressed)
                  maxScale: 4.0, // Maximum zoom level
                  child: Center(
                    child: Image.asset(
                      mapImagePath,
                      fit: BoxFit.contain,
                      scale: 1.2, // Slight compression for initial view
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          "Error loading map image",
                          style: TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
