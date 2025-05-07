import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:evacuease/Controllers/home_controller.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _startSurveyPolling();
  }

  Future<void> _initializeApp() async {
    final controller = Provider.of<HomeController>(context, listen: false);
    try {
      await controller.loadModel();
      await controller.fetchCurrentLocationAndWeather();
      while (controller.riskAreas.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      print("App initialized, WeatherData: ${controller.weatherData}");
    } catch (e) {
      _errorMessage = "Failed to load data: $e";
      print("Error in _initializeApp: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch surveys from the API
  Future<void> _fetchSurveys() async {
    try {
      final response = await http
          .get(Uri.parse('https://admin-evacu-ease.vercel.app/api/survey'));
      print("Survey API Status Code: ${response.statusCode}");
      print("Survey API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print("Parsed API Response: $jsonResponse");

        if (jsonResponse['success'] == true &&
            jsonResponse.containsKey('data')) {
          final List<dynamic> data = jsonResponse['data'];
          final newSurveys = data.map((json) => Survey.fromJson(json)).toList();

          // Sort by createdAt descending (newest first)
          newSurveys.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          print(
              "New Surveys Fetched (sorted): ${newSurveys.map((s) => "${s.title} (${s.createdAt.toIso8601String()})").toList()}");
          print(
              "Existing Surveys: ${_surveys.map((s) => "${s.title} (${s.createdAt.toIso8601String()})").toList()}");

          if (newSurveys.isNotEmpty && _surveys.isNotEmpty) {
            // Skip popup on initial load
            final latestSurvey = newSurveys.first;
            final previousLatest = _surveys.first;
            print(
                "Comparing Latest: ${latestSurvey.title} (${latestSurvey.createdAt.toIso8601String()}) vs Previous: ${previousLatest.title} (${previousLatest.createdAt.toIso8601String()})");
            if (latestSurvey.createdAt.isAfter(previousLatest.createdAt)) {
              print(
                  "New survey detected, showing popup for: ${latestSurvey.title}");
              _showSurveyPopup(latestSurvey);
            } else {
              print("No newer survey found.");
            }
          }

          setState(() {
            _surveys = newSurveys;
            print("Updated _surveys length: ${_surveys.length}");
          });
        } else {
          print("API response invalid: missing 'success' or 'data'");
        }
      } else {
        print(
            "Failed to fetch surveys: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      print("Error fetching surveys: $e");
    }
  }

  // Poll for surveys every 1 minute
  void _startSurveyPolling() {
    _fetchSurveys(); // Initial fetch to populate _surveys, no popup
    _surveyPollingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      print("Polling surveys at ${DateTime.now()}");
      _fetchSurveys();
    });
  }

  void _launchURL(String url) async {
    print("Attempting to launch URL: $url");
    if (url.isEmpty) {
      print("URL is empty");
      return;
    }

    if (await canLaunch(url)) {
      print("URL can be launched");
      await launch(url);
    } else {
      print("Cannot launch URL: $url");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch URL")),
      );
    }
  }

  // Show survey popup
  void _showSurveyPopup(Survey survey) {
    print(
        "Showing popup for survey: ${survey.title}, CreatedAt: ${survey.createdAt}");
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
    print(
        "Building weather section, _isLoading: $_isLoading, WeatherData: ${controller.weatherData}");
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
                        fontSize: 22, fontWeight: FontWeight.bold),
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
                                  fontSize: 14, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${weatherData.temperature?.toStringAsFixed(1) ?? "--"} °C',
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey),
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
            child: Text(_errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16)))
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
                  color: Colors.grey[300]),
              const SizedBox(height: 4),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: MediaQuery.of(context).size.width * 0.2,
                          height: 14,
                          color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Container(
                          width: MediaQuery.of(context).size.width * 0.25,
                          height: 26,
                          color: Colors.grey[300]),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Container(width: 50, height: 50, color: Colors.grey[300]),
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
    const String starterUrl =
        'https://www.facebook.com/share/v/1AW5vij63S/'; // Provided Facebook link

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
              const Icon(Icons.arrow_right, size: 50),
            ],
          ),
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
              Text(language.riskArea,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              TextButton(
                  onPressed: null,
                  child: Text(language.seeAll,
                      style: const TextStyle(color: Colors.grey))),
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
          child: Text(_errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16)));
    }
    if (controller.riskAreas.isEmpty) {
      return Text(language.noRiskAreas,
          style: const TextStyle(fontSize: 16, color: Colors.grey));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(language.riskArea,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, RouteNames.riskArea),
                child: Text(language.seeAll,
                    style: const TextStyle(color: Colors.blue))),
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
          border: Border(bottom: BorderSide(color: Colors.grey, width: 1.0))),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.grey[300])),
            const SizedBox(width: 15),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: 20,
                    color: Colors.grey[300]),
                const SizedBox(height: 8),
                Container(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: 15,
                    color: Colors.grey[300]),
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
          border: Border(bottom: BorderSide(color: Colors.grey, width: 1.0))),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: area.riskColor)),
            const SizedBox(width: 15),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(area.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20),
                      overflow: TextOverflow.ellipsis),
                  Text(area.riskLevel,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.grey),
                      overflow: TextOverflow.ellipsis),
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
          child: Text(language.offlineRiskMap,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
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
      onTap: () => _showFullMap(context, mapImagePath, label),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.18,
        height: MediaQuery.of(context).size.width * 0.18,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.red),
            borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(assetPath, width: 30, height: 30, fit: BoxFit.contain),
            Text(label,
                style: TextStyle(color: Colors.red[500], fontSize: 12),
                overflow: TextOverflow.ellipsis),
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
                        return const Text("Error loading map image",
                            style: TextStyle(color: Colors.white));
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                  top: 10,
                  left: 10,
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold))),
              Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context))),
            ],
          ),
        );
      },
    );
  }
}
