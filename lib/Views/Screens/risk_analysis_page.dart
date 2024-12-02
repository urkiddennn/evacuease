import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RiskAnalysisPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.location_on), label: "Location"),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: "Notification"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "User"),
        ],
        selectedItemColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Risk Area",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            // Chart Widget
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          return Text(
                            value.toString(),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          );
                        },
                        interval: 5, // Set the interval for Y-axis
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          const days = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun'
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < days.length) {
                            return Text(
                              days[value.toInt()],
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 2),
                        FlSpot(1, 4),
                        FlSpot(2, 6),
                        FlSpot(3, 5),
                        FlSpot(4, 8),
                        FlSpot(5, 10),
                        FlSpot(6, 15),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            // Ranking List
            Text(
              "Ranking",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 70,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color:
                            Colors.grey, // Change to your desired border color
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
                                    fontWeight: FontWeight.bold, fontSize: 20),
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
                        color:
                            Colors.grey, // Change to your desired border color
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
                                    fontWeight: FontWeight.bold, fontSize: 20),
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
                        color:
                            Colors.grey, // Change to your desired border color
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
                                    fontWeight: FontWeight.bold, fontSize: 20),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
