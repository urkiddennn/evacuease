import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:evacuease/Controllers/home_controller.dart' as homeController;
import 'package:evacuease/Models/home_model.dart';
import 'package:evacuease/Models/survey_model.dart';
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
  List<Survey> _surveys = [];
  Timer? _surveyPollingTimer;
  String _selectedHazardType = 'Earthquake'; // Default hazard type

  // Priority map for hazard levels based on provided mapping functions
  static const Map<String, int> _hazardLevelPriority = {
    // Earthquake levels
    'X - Completely devastating': 10,
    'IX - Devastating': 9,
    'VIII - Very destructive': 8,
    'VII - Destructive': 7,
    'VI - Very strong': 6,
    'V - Strong': 5,
    'IV - Moderately weak': 4,
    'III - Weak': 3,
    'II - Slightly felt': 2,
    'I - Scarcely perceptible': 1,
    // Flood levels
    'Red - High': 4,
    'Red_orange - Medium': 3,
    'Orange - Low': 2,
    'Yellow - Very_Low': 1,
    // Landslide levels
    'Red - High_Susceptibility': 3,
    'Violet - Moderate_Susceptibility': 2,
    'Yellow - low_Susceptibility': 1,
    // Storm Surge levels
    'High': 3,
    'Medium': 2,
    'Low': 1,
    // Fallback for any unexpected levels
    'Yellow - High': 3, // From JSON data, treated as Medium/High
    'Yellow - Medium': 2,
    'Yellow - Low': 1,
  };

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _startSurveyPolling();
  }

  Future<void> _initializeApp() async {
    final controller =
        Provider.of<homeController.HomeController>(context, listen: false);
    try {
      await controller.loadModel();
      await controller.loadBarangayData();
      await controller.fetchCurrentLocationAndWeather();
      while (controller.allRiskAreas.isEmpty) {
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

  Future<void> _fetchSurveys() async {
    try {
      final response = await http
          .get(Uri.parse('https://admin-evacu-ease.vercel.app/api/survey'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true &&
            jsonResponse.containsKey('data')) {
          final List<dynamic> data = jsonResponse['data'];
          final newSurveys = data.map((json) => Survey.fromJson(json)).toList();

          newSurveys.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (newSurveys.isNotEmpty && _surveys.isNotEmpty) {
            final latestSurvey = newSurveys.first;
            final previousLatest = _surveys.first;
            if (latestSurvey.createdAt.isAfter(previousLatest.createdAt)) {
              _showSurveyPopup(latestSurvey);
            }
          }

          setState(() {
            _surveys = newSurveys;
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _startSurveyPolling() {
    _fetchSurveys();
    _surveyPollingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _fetchSurveys();
    });
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch URL")),
      );
    }
  }

  void _showSurveyPopup(Survey survey) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  survey.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Take survey: This helps the developer to enhance the app",
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final url = survey.link ?? '';
                        _launchURL(url);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: const Text("Take Survey",
                          style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade300,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child:
                          const Text("Dismiss", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _surveyPollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<Language>(context);
    final controller = Provider.of<homeController.HomeController>(context);
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
    final controller = Provider.of<homeController.HomeController>(context);
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

    return _errorMessage != null
        ? Center(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          )
        : _buildWeatherSkeleton(context);
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
    const String starterUrl = 'https://www.facebook.com/share/v/1AW5vij63S/';
    return GestureDetector(
      onTap: () => _launchURL(starterUrl),
      child: Container(
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
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
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
      ),
    );
  }

  // Risk Areas Section
  Widget _buildRiskAreaSection(BuildContext context) {
    final language = Provider.of<Language>(context);
    final controller = Provider.of<homeController.HomeController>(context);

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
                child: Text(
                  language.seeAll,
                  style: const TextStyle(color: Colors.grey),
                ),
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

    if (controller.allRiskAreas.isEmpty) {
      return Text(
        language.noRiskAreas,
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      );
    }

    // Sort barangays by hazard level priority, then by hazard score
    List<RiskArea> sortedAreas = List.from(controller.allRiskAreas)
      ..sort((a, b) {
        // Get hazard levels
        String levelA = a.hazardLevels[_selectedHazardType] ?? 'Low';
        String levelB = b.hazardLevels[_selectedHazardType] ?? 'Low';

        // Get priority for levels, default to 0 if not found
        int priorityA = _hazardLevelPriority[levelA] ?? 0;
        int priorityB = _hazardLevelPriority[levelB] ?? 0;

        // Compare priorities (descending: higher priority first)
        int priorityComparison = priorityB.compareTo(priorityA);
        if (priorityComparison != 0) {
          return priorityComparison;
        }

        // If priorities are equal, compare scores (descending: higher score first)
        double scoreA = a.hazardScores[_selectedHazardType] ?? 0.0;
        double scoreB = b.hazardScores[_selectedHazardType] ?? 0.0;
        return scoreB.compareTo(scoreA);
      });

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
                Navigator.pushNamed(
                  context,
                  RouteNames.riskArea,
                  arguments: _selectedHazardType,
                );
              },
              child: Text(
                language.seeAll,
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.start,
          children: [
            _buildHazardButton(context, language.earthquake, 'Earthquake'),
            _buildHazardButton(context, language.flood, 'Flood'),
            _buildHazardButton(context, language.landslide, 'Landslide'),
            _buildHazardButton(context, language.stormSurge, 'Storm Surge'),
          ],
        ),
        const SizedBox(height: 15),
        ...sortedAreas
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
    final level = area.hazardLevels[_selectedHazardType] ?? 'Unknown';
    Color riskColor;

    // Handle Landslide susceptibility levels explicitly
    if (_selectedHazardType == 'Landslide') {
      if (level == 'Red - High_Susceptibility') {
        riskColor = Colors.red;
      } else if (level == 'Violet - Moderate_Susceptibility') {
        riskColor = Colors.purple; // Violet is approximated as purple
      } else if (level == 'Yellow - Low_Susceptibility') {
        riskColor = Colors.yellow;
      } else {
        riskColor = Colors.grey; // Fallback for unexpected levels
      }
    } else {
      // Existing logic for other hazard types (Earthquake, Flood, Storm Surge)
      if (level.contains('High') ||
          level.contains('Red') ||
          level.contains('VI') ||
          level.contains('VII') ||
          level.contains('VIII') ||
          level.contains('IX') ||
          level.contains('X')) {
        riskColor = Colors.red;
      } else if (level.contains('Medium') ||
          level.contains('Moderate') ||
          level.contains('Orange') ||
          level.contains('V')) {
        riskColor = Colors.orange;
      } else if (level.contains('Red_orange')) {
        riskColor = Colors.redAccent;
      } else if (level.contains('Low') ||
          level.contains('I') ||
          level.contains('II') ||
          level.contains('III') ||
          level.contains('IV')) {
        riskColor = Colors.green;
      } else if (level.contains('Very_')) {
        riskColor = Colors.yellow;
      } else {
        riskColor = Colors.grey; // Fallback for unexpected levels
      }
    }

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
                color: riskColor,
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
                    level,
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
                  boundaryMargin: const EdgeInsets.all(0),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.asset(
                      mapImagePath,
                      fit: BoxFit.contain,
                      scale: 1.2,
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

  Widget _buildHazardButton(
      BuildContext context, String label, String hazardType) {
    bool isSelected = _selectedHazardType == hazardType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedHazardType = hazardType;
        });
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? Colors.red : Colors.grey),
          borderRadius: BorderRadius.circular(10),
          color: isSelected ? Colors.red.withOpacity(0.1) : Colors.white,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.red : Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
