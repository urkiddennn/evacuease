import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Controllers/home_controller.dart';
import '../../../Controllers/language.dart';
import '../../../Models/home_model.dart';

class RiskAreaScreen extends StatelessWidget {
  const RiskAreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<Language>(context);
    final homeController = Provider.of<HomeController>(context, listen: false);

    // Use allRiskAreas instead of riskAreas
    final allRiskAreas = homeController.allRiskAreas;

    return Scaffold(
      appBar: AppBar(
        title: Text(language.riskArea),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: allRiskAreas.isEmpty
            ? Center(
                child: Text(
                  language.noRiskAreas,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: allRiskAreas.length,
                itemBuilder: (context, index) {
                  return _buildRiskAreaItem(context, allRiskAreas[index]);
                },
              ),
      ),
    );
  }

  Widget _buildRiskAreaItem(BuildContext context, RiskArea area) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.1,
      margin: const EdgeInsets.only(bottom: 8.0),
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
}
