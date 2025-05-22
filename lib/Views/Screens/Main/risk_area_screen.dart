import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evacuease/Controllers/home_controller.dart' as homeController;
import 'package:evacuease/Models/home_model.dart';
import '../../../Controllers/language.dart';

class RiskAreaScreen extends StatefulWidget {
  const RiskAreaScreen({super.key});

  @override
  State<RiskAreaScreen> createState() => _RiskAreaScreenState();
}

class _RiskAreaScreenState extends State<RiskAreaScreen> {
  late String _selectedHazardType;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    _selectedHazardType = args is String ? args : 'Earthquake';
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<Language>(context);
    final controller = Provider.of<homeController.HomeController>(context);

    // Sort barangays by selected hazard score
    List<RiskArea> sortedAreas = List.from(controller.allRiskAreas)
      ..sort((a, b) {
        double scoreA = a.hazardScores[_selectedHazardType] ?? 0.0;
        double scoreB = b.hazardScores[_selectedHazardType] ?? 0.0;
        return scoreB.compareTo(scoreA); // Highest score first
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${language.getHazardLabel(_selectedHazardType)} ${language.riskArea}'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Expanded(
              child: sortedAreas.isEmpty
                  ? Center(
                      child: Text(
                        language.noRiskAreas,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: sortedAreas.length,
                      itemBuilder: (context, index) {
                        return _buildRiskAreaItem(
                            context, sortedAreas[index], index + 1);
                      },
                    ),
            ),
          ],
        ),
      ),
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

  Widget _buildRiskAreaItem(BuildContext context, RiskArea area, int rank) {
    final level = area.hazardLevels[_selectedHazardType] ?? 'Unknown';

    // Determine risk color based on hazard level (same logic as new version)
    Color riskColor;
    if (_selectedHazardType == 'Landslide') {
      if (level == 'Red - High_Susceptibility') {
        riskColor = Colors.red;
      } else if (level.contains('Medium_Susceptibility')) {
        riskColor = Colors.purple; // Violet is approximated as purple
      } else if (level == 'Yellow') {
        riskColor = Colors.yellow;
      } else {
        riskColor = Colors.purple; // Fallback for unexpected levels
      }
    }
    if (_selectedHazardType == "Flood") {
      if (level == 'Red - High') {
        riskColor = Colors.red;
      } else if (level == 'Red_Orange - Medium') {
        riskColor = Colors.deepOrangeAccent; // Violet is approximated as purple
      } else if (level == 'Orange - Low') {
        riskColor = Colors.orange;
      } else {
        riskColor = Colors.yellow; // Fallback for unexpected levels
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
      } else if (level.contains('Orange')) {
        riskColor = Colors.orange;
      } else if (level.contains('Low') ||
          level.contains('I') ||
          level.contains('II') ||
          level.contains('III') ||
          level.contains('IV')) {
        riskColor = Colors.green;
      } else if (level.contains("Very_")) {
        riskColor = Colors.yellow;
      } else if (level.contains('Yellow')) {
        riskColor = Colors.yellow;
      } else if (level.contains('Violet') ||
          level.contains('Medium_Susceptibility')) {
        riskColor = Colors.purple;
      } else {
        riskColor = Colors.grey; // Fallback for unexpected levels
      }
    }

    return HeroControllerScope.none(
      child: Container(
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
                  color: riskColor, // Use riskColor from logic above
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
      ),
    );
  }
}
