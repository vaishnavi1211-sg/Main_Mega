import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key, required Map productionProfile, required Null Function() onDataChanged});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  // ---------------------------------------
  // TALUKA WISE INVENTORY (DUMMY LIVE DATA)
  // ---------------------------------------
  List<Map<String, dynamic>> branches = [
    {
      "name": "Karad",
      "stock": 420,
      "sold": 120,
      "inbound": 80,
      "color": Colors.blue
    },
    {
      "name": "Satara",
      "stock": 320,
      "sold": 150,
      "inbound": 60,
      "color": Colors.lightBlue
    },
    {
      "name": "Patan",
      "stock": 210,
      "sold": 80,
      "inbound": 50,
      "color": Colors.indigo
    },
    {
      "name": "Koynanagar",
      "stock": 160,
      "sold": 60,
      "inbound": 40,
      "color": Colors.blueAccent
    },
  ];

  // Simulate "live" updating values every 5 seconds
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() {
        for (var b in branches) {
          b["stock"] += (5 - b["sold"] % 3);
          b["sold"] += (2);
          b["inbound"] += (1);
        }
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // ----------------------------------------------------------
  // SIMPLE CHART DATA FOR INVENTORY STOCK X SOLD VISUALIZATION
  // ----------------------------------------------------------
  List<BarChartGroupData> _chartBars() {
    return List.generate(branches.length, (index) {
      final b = branches[index];
      return BarChartGroupData(
        x: index,
        barsSpace: 8,
        barRods: [
          BarChartRodData(
            toY: b["stock"].toDouble(),
            color: Colors.blue.shade600,
            width: 18,
            borderRadius: BorderRadius.circular(6),
          ),
          BarChartRodData(
            toY: b["sold"].toDouble(),
            color: Colors.blue.shade200,
            width: 18,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("Inventory Dashboard"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // -------------------- CHART CARD ------------------
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(2, 3),
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Stock vs Sold (Taluka-wise)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        maxY: 600,
                        barGroups: _chartBars(),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 100,
                              getTitlesWidget: (v, _) =>
                                  Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) => Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  branches[v.toInt()]["name"],
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -------------------- BRANCH WISE CARDS ------------------
            Column(
              children: branches.map((b) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blue.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(2, 3),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b["name"],
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoTile("Stock (kg)", b["stock"].toString(), Colors.blue.shade700),
                          _infoTile("Sold (kg)", b["sold"].toString(), Colors.blue.shade400),
                          _infoTile("Inbound (kg)", b["inbound"].toString(), Colors.indigo.shade300),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Small info cube widget ----------
  Widget _infoTile(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
