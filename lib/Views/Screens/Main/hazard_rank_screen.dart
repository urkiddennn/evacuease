import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evacuease/Controllers/home_controller.dart' as homeController;
import 'package:evacuease/Models/home_model.dart';
import '../../../Controllers/language.dart';

class HazardRankScreen extends StatelessWidget {
  final String hazardType;

  const HazardRankScreen({super.key, required this.hazardType});

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<Language>(context);
    final controller = Provider.of<homeController.HomeController>(context);

    // Sort risk areas by the specific hazard score
    List<RiskArea> sortedAreas = List.from(controller.allRiskAreas)
      ..sort((a, b) {
        double scoreA = a.hazardScores[hazardType] ?? 0.0;
        double scoreB = b.hazardScores[hazardType] ?? 0.0;
        return scoreB.compareTo(scoreA);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text('${language.getHazardLabel(hazardType)} Rankings'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: sortedAreas.isEmpty
            ? Center(
                child: Text(
                  language.noRiskAreas,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: sortedAreas.length,
                itemBuilder: (context, index) {
                  final area = sortedAreas[index];
                  return _buildRankItem(context, area, hazardType);
                },
              ),
      ),
    );
  }

  Widget _buildRankItem(
      BuildContext context, RiskArea area, String hazardType) {
    final score = area.hazardScores[hazardType] ?? 0.0;
    final level = area.hazardLevels[hazardType] ?? 'Unknown';

    // Determine color based on hazard level
    Color levelColor;
    if (level.contains('Low') ||
        level.contains('I') ||
        level.contains('II') ||
        level.contains('Yellow')) {
      levelColor = Colors.green;
    } else if (level.contains('Medium') ||
        level.contains('Moderate') ||
        level.contains('III') ||
        level.contains('IV') ||
        level.contains('Orange') ||
        level.contains('Violet')) {
      levelColor = Colors.orange;
    } else if (level.contains('High') ||
        level.contains('V') ||
        level.contains('VI') ||
        level.contains('VII') ||
        level.contains('VIII') ||
        level.contains('IX') ||
        level.contains('X') ||
        level.contains('Red')) {
      levelColor = Colors.red;
    } else {
      levelColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                color: levelColor, // Use level-based color
              ),
            ),
            const SizedBox(width: 15),
            Flexible(
              child: Column(
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
                    '$hazardType Score: ${score.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      color: levelColor, // Color score text
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$hazardType Level: $level',
                    style: TextStyle(
                      fontSize: 15,
                      color: levelColor, // Color level text
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
}
