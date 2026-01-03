import 'package:flutter/material.dart';
import 'package:mega_pro/marketing/mar_employees.dart';
import 'package:mega_pro/marketing/mar_order.dart';
import 'package:mega_pro/marketing/mar_profile.dart';
import 'package:mega_pro/marketing/mar_reporting.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class MarketingManagerDashboard extends StatefulWidget {
  const MarketingManagerDashboard({super.key, required Map userData});

  @override
  State<MarketingManagerDashboard> createState() =>
      _MarketingManagerDashboardState();
}

class _MarketingManagerDashboardState extends State<MarketingManagerDashboard> {
  int _currentIndex = 0;
  
  // Pages for bottom navigation
  final List<Widget> _pages = [
    const DashboardContent(),
    const EmployeeDetailPage(),
    const CattleFeedOrderScreen(),
    const ReportingPage(),
    const MarketingProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.background,
      appBar: _currentIndex == 0 
          ? _buildDashboardAppBar() 
          : _buildStandardAppBar(_currentIndex),
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _buildDashboardAppBar() {
    return AppBar(
      backgroundColor: GlobalColors.primaryBlue,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Marketing Dashboard",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
          tooltip: 'Notifications',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  AppBar _buildStandardAppBar(int index) {
    return AppBar(
      backgroundColor: GlobalColors.primaryBlue,
      title: Text(
        _getAppBarTitle(index),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.dashboard, "Dashboard"),
              _buildNavItem(1, Icons.people_alt, "Team"),
              _buildNavItem(2, Icons.shopping_cart, "Orders"),
              _buildNavItem(3, Icons.analytics, "Reports"),
              _buildNavItem(4, Icons.person, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _currentIndex == index
              ? GlobalColors.primaryBlue.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _currentIndex == index
                  ? GlobalColors.primaryBlue
                  : Colors.grey[600],
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: _currentIndex == index
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: _currentIndex == index
                    ? GlobalColors.primaryBlue
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return "Marketing Dashboard";
      case 1:
        return "Team Management";
      case 2:
        return "Order Management";
      case 3:
        return "Reporting";
      case 4:
        return "My Profile";
      default:
        return "Marketing Dashboard";
    }
  }
}

// Dashboard Content Widget
class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  // Sales data in Tons (T)
  final Map<String, List<Map<String, dynamic>>> _districtTalukaData = {
    "Kolhapur": [
      {"taluka": "Karvir", "sales": 220, "target": 250},
      {"taluka": "Panhala", "sales": 160, "target": 180},
      {"taluka": "Shirol", "sales": 140, "target": 150},
      {"taluka": "Hatkanangale", "sales": 110, "target": 120},
      {"taluka": "Kagal", "sales": 180, "target": 200},
      {"taluka": "Shahuwadi", "sales": 95, "target": 100},
      {"taluka": "Ajara", "sales": 75, "target": 90},
      {"taluka": "Gadhinglaj", "sales": 205, "target": 220},
      {"taluka": "Chandgad", "sales": 130, "target": 140},
      {"taluka": "Radhanagari", "sales": 120, "target": 130},
      {"taluka": "Jat", "sales": 90, "target": 100},
      {"taluka": "Bhudargad", "sales": 150, "target": 160},
    ],
  };

  final String _selectedDistrict = "Kolhapur";
  final Color themePrimary = GlobalColors.primaryBlue;

  double _getTotalSales() {
    final talukas = _districtTalukaData[_selectedDistrict] ?? [];
    return talukas.fold<double>(0, (sum, e) => sum + (e['sales'] as num).toDouble());
  }

  Widget _buildChart(List<Map<String, dynamic>> talukas) {
    // Calculate required width based on number of data points
    final chartWidth = talukas.length * 80.0;
    final chartHeight = 250.0;
    
    return Container(
      height: chartHeight,
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20)
      ),
      child: Column(
        children: [
          // Chart Area with horizontal scroll
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: chartWidth,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: false,
                      horizontalInterval: _getMaxY(talukas) / 5,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            int i = value.toInt();
                            if (i < 0 || i >= talukas.length) return const SizedBox();
                            
                            return Container(
                              width: 75,
                              margin: const EdgeInsets.only(top: 8),
                              child: Transform.rotate(
                                angle: -0.4, // Rotate labels slightly for better fit
                                child: Text(
                                  talukas[i]['taluka'].toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          interval: _getMaxY(talukas) / 5,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    minX: 0,
                    maxX: talukas.length > 0 ? (talukas.length - 1).toDouble() : 0,
                    minY: 0,
                    maxY: _getMaxY(talukas),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(talukas.length, (i) => 
                          FlSpot(i.toDouble(), talukas[i]['sales'].toDouble())
                        ),
                        isCurved: true,
                        color: themePrimary,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => 
                            FlDotCirclePainter(
                              radius: 3,
                              color: themePrimary,
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            ),
                        ),
                        belowBarData: BarAreaData(
                          show: true, 
                          color: themePrimary.withOpacity(0.08),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              themePrimary.withOpacity(0.3),
                              themePrimary.withOpacity(0.05),
                            ],
                          ),
                        ),
                      )
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.8),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            final taluka = talukas[spot.x.toInt()];
                            return LineTooltipItem(
                              '${taluka['taluka']}\n${taluka['sales']} T',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Scroll indicator
          Container(
            height: 4,
            width: 100,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY(List<Map<String, dynamic>> talukas) {
    if (talukas.isEmpty) return 100.0;
    
    final maxSales = talukas
        .map((e) => (e['sales'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    
    // Round up to nearest 50
    return (maxSales / 50).ceil() * 50 * 1.1;
  }

  @override
  Widget build(BuildContext context) {
    final talukaList = _districtTalukaData[_selectedDistrict] ?? [];

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Performance Overview Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      GlobalColors.primaryBlue,
                      Colors.blue[700]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: GlobalColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Sales",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${_getTotalSales().toInt()} T",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Across ${talukaList.length} Talukas",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Chart Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chart Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Sales Trend by Taluka",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: GlobalColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: GlobalColors.primaryBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _selectedDistrict,
                                style: TextStyle(
                                  color: GlobalColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Chart Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildLegendItem(GlobalColors.primaryBlue, "Sales Trend"),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Line Chart
                    talukaList.isNotEmpty
                        ? _buildChart(talukaList)
                        : SizedBox(
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bar_chart,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No Sales Data Available",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    
                    // Chart Explanation
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.swipe_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Swipe horizontally to view all talukas",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}







// import 'package:flutter/material.dart';
// import 'package:mega_pro/marketing/mar_employees.dart';
// import 'package:mega_pro/marketing/mar_order.dart';
// import 'package:mega_pro/marketing/mar_profile.dart';
// import 'package:mega_pro/marketing/mar_reporting.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:fl_chart/fl_chart.dart';


// class MarketingManagerDashboard extends StatefulWidget {
//   const MarketingManagerDashboard({super.key, required Map userData});

//   @override
//   State<MarketingManagerDashboard> createState() =>
//       _MarketingManagerDashboardState();
// }

// class _MarketingManagerDashboardState extends State<MarketingManagerDashboard> {
//   int _currentIndex = 0;
  
//   // Pages for bottom navigation
//   final List<Widget> _pages = [
//     const DashboardContent(),
//     const EmployeeDetailPage(),
//     const MakeOrderPage(),
//     const ReportingPage(),
//     const MarketingProfilePage(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: _currentIndex == 0 
//           ? _buildDashboardAppBar() 
//           : _buildStandardAppBar(_currentIndex),
//       body: _pages[_currentIndex],
//       bottomNavigationBar: _buildBottomNavigationBar(),
//     );
//   }

//   AppBar _buildDashboardAppBar() {
//     return AppBar(
//       backgroundColor: GlobalColors.primaryBlue,
//       title: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Marketing Dashboard",
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w600,
//               color: Colors.white,
//               fontSize: 18,
//             ),
//           ),
          
//         ],
//       ),
//       centerTitle: false,
//       iconTheme: const IconThemeData(color: Colors.white),
//       actions: [
//         IconButton(
//           icon: const Icon(Icons.notifications_none),
//           onPressed: () {},
//           tooltip: 'Notifications',
//         ),
//         const SizedBox(width: 8),
//       ],
//     );
//   }

//   AppBar _buildStandardAppBar(int index) {
//     return AppBar(
//       backgroundColor: GlobalColors.primaryBlue,
//       title: Text(
//         _getAppBarTitle(index),
//         style: GoogleFonts.poppins(
//           fontWeight: FontWeight.w600,
//           color: Colors.white,
//         ),
//       ),
//       //centerTitle: true,
//       iconTheme: const IconThemeData(color: Colors.white),
//     );
//   }

//   Widget _buildBottomNavigationBar() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _buildNavItem(0, Icons.dashboard, "Dashboard"),
//               _buildNavItem(1, Icons.people_alt, "Team"),
//               _buildNavItem(2, Icons.shopping_cart, "Orders"),
//               _buildNavItem(3, Icons.analytics, "Reports"),
//               _buildNavItem(4, Icons.person, "Profile"),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem(int index, IconData icon, String label) {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _currentIndex = index;
//         });
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: _currentIndex == index
//               ? GlobalColors.primaryBlue.withOpacity(0.1)
//               : Colors.transparent,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               color: _currentIndex == index
//                   ? GlobalColors.primaryBlue
//                   : Colors.grey[600],
//               size: 22,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 10,
//                 fontWeight: _currentIndex == index
//                     ? FontWeight.w600
//                     : FontWeight.normal,
//                 color: _currentIndex == index
//                     ? GlobalColors.primaryBlue
//                   : Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _getAppBarTitle(int index) {
//     switch (index) {
//       case 0:
//         return "Marketing Dashboard";
//       case 1:
//         return "Team Management";
//       case 2:
//         return "Order Management";
//       case 3:
//         return "Reporting";
//       case 4:
//         return "My Profile";
//       default:
//         return "Marketing Dashboard";
//     }
//   }
// }

// // Dashboard Content Widget
// class DashboardContent extends StatefulWidget {
//   const DashboardContent({super.key});

//   @override
//   State<DashboardContent> createState() => _DashboardContentState();
// }

// class _DashboardContentState extends State<DashboardContent> {
//   // Sales data in Tons (T)
//   final Map<String, List<Map<String, dynamic>>> _districtTalukaData = {
//     "Kolhapur": [
//       {"taluka": "Karvir", "sales": 220, "target": 250},
//       {"taluka": "Panhala", "sales": 160, "target": 180},
//       {"taluka": "Shirol", "sales": 140, "target": 150},
//       {"taluka": "Hatkanangale", "sales": 110, "target": 120},
//       {"taluka": "Kagal", "sales": 180, "target": 200},
//       {"taluka": "Shahuwadi", "sales": 95, "target": 100},
//       {"taluka": "Ajara", "sales": 75, "target": 90},
//       {"taluka": "Gadhinglaj", "sales": 205, "target": 220},
//       {"taluka": "Chandgad", "sales": 130, "target": 140},
//       {"taluka": "Radhanagari", "sales": 120, "target": 130},
//       {"taluka": "Jat", "sales": 90, "target": 100},
//       {"taluka": "Bhudargad", "sales": 150, "target": 160},
//     ],
//   };

//   final String _selectedDistrict = "Kolhapur";

  

//   double _getMaxY(List<Map<String, dynamic>> talukas) {
//     if (talukas.isEmpty) return 100.0;
    
//     final maxSales = talukas
//         .map((e) => (e['sales'] as num).toDouble())
//         .reduce((a, b) => a > b ? a : b);
    
//     final maxTarget = talukas
//         .map((e) => (e['target'] as num).toDouble())
//         .reduce((a, b) => a > b ? a : b);
    
//     return (maxSales > maxTarget ? maxSales : maxTarget) * 1.2;
//   }

//   double _getTotalSales() {
//     final talukas = _districtTalukaData[_selectedDistrict] ?? [];
//     return talukas.fold<double>(0, (sum, e) => sum + (e['sales'] as num).toDouble());
//   }


//   BarChartData _buildBarChartDataForDistrict(String district) {
//     final talukas = _districtTalukaData[district] ?? [];
    
//     // Create bar groups
//     final barGroups = talukas.asMap().entries.map((entry) {
//       final index = entry.key;
//       final data = entry.value;
//       return BarChartGroupData(
//         x: index,
//         groupVertically: true,
//         barRods: [
//           BarChartRodData(
//             toY: (data['sales'] as num).toDouble(),
//             color: GlobalColors.primaryBlue,
//             width: 12,
//             borderRadius: BorderRadius.circular(4),
//           ),
//           BarChartRodData(
//             toY: (data['target'] as num).toDouble(),
//             color: Colors.grey[300]!,
//             width: 12,
//             borderRadius: BorderRadius.circular(4),
//           ),
//         ],
//       );
//     }).toList();

//     return BarChartData(
//       barGroups: barGroups,
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: false,
//         horizontalInterval: _getMaxY(talukas) / 5,
//         getDrawingHorizontalLine: (value) =>
//             FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 50,
//             interval: 2,
//             getTitlesWidget: (value, meta) {
//               final i = value.toInt();
//               if (i < 0 || i >= talukas.length || i % 2 != 0) {
//                 return const SizedBox.shrink();
//               }
//               return Padding(
//                 padding: const EdgeInsets.only(top: 8.0),
//                 child: Text(
//                   talukas[i]["taluka"],
//                   style: TextStyle(
//                     fontSize: 10,
//                     color: Colors.grey[700],
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   maxLines: 2,
//                   textAlign: TextAlign.center,
//                 ),
//               );
//             },
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 50,
//             interval: _getMaxY(talukas) / 5,
//             getTitlesWidget: (value, meta) => Padding(
//               padding: const EdgeInsets.only(right: 8.0),
//               child: Text(
//                 "${value.toInt()}",
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//       borderData: FlBorderData(
//         show: true,
//         border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
//       ),
//       barTouchData: BarTouchData(
//         enabled: true,
//         touchTooltipData: BarTouchTooltipData(
//           getTooltipItem: (group, groupIndex, rod, rodIndex) {
//             final taluka = talukas[group.x.toInt()];
//             final isTarget = rodIndex == 1;
//             final value = isTarget ? taluka['target'] : taluka['sales'];
//             final label = isTarget ? 'Target' : 'Sales';
//             return BarTooltipItem(
//               '$label: $value T\n${taluka["taluka"]}',
//               const TextStyle(color: Colors.white),
//             );
//           },
//         ),
//       ),
//       maxY: _getMaxY(talukas),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final talukaList = _districtTalukaData[_selectedDistrict] ?? [];
//     final barChartData = _buildBarChartDataForDistrict(_selectedDistrict);

//     return SafeArea(
//       child: SingleChildScrollView(
//         physics: const BouncingScrollPhysics(),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Performance Overview Card
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [
//                       GlobalColors.primaryBlue,
//                       Colors.blue[700]!,
//                     ],
//                   ),
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: GlobalColors.primaryBlue.withOpacity(0.3),
//                       blurRadius: 15,
//                       offset: const Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Total Sales",
//                             style: GoogleFonts.poppins(
//                               color: Colors.white.withOpacity(0.9),
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             "${_getTotalSales().toInt()} T",
//                             style: GoogleFonts.poppins(
//                               color: Colors.white,
//                               fontSize: 28,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             "Across ${talukaList.length} Talukas",
//                             style: GoogleFonts.poppins(
//                               color: Colors.white.withOpacity(0.8),
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       width: 80,
//                       height: 80,
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Icon(
//                         Icons.trending_up,
//                         color: Colors.white,
//                         size: 40,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // Chart Container
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.08),
//                       blurRadius: 15,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Chart Header
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           "Sales vs Target by Taluka",
//                           style: GoogleFonts.poppins(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.grey[800],
//                           ),
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                           decoration: BoxDecoration(
//                             color: GlobalColors.primaryBlue.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
                          
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.location_on,
//                                 size: 10,
//                                 color: GlobalColors.primaryBlue,
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 _selectedDistrict,
//                                 style: TextStyle(
//                                   color: GlobalColors.primaryBlue,
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 10,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),

//                     // Chart Legend
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         _buildLegendItem(GlobalColors.primaryBlue, "Sales"),
//                         const SizedBox(width: 20),
//                         _buildLegendItem(Colors.grey[300]!, "Target"),
//                       ],
//                     ),
//                     const SizedBox(height: 20),

//                     // Bar Chart
//                     SizedBox(
//                       height: 300,
//                       child: talukaList.isNotEmpty
//                           ? BarChart(barChartData)
//                           : const Center(
//                               child: Text(
//                                 "No Sales Data Available",
//                                 style: TextStyle(color: Colors.grey),
//                               ),
//                             ),
//                     ),
                    
//                     // Chart Explanation
//                     Padding(
//                       padding: const EdgeInsets.only(top: 16),
//                       child: Text(
//                         "Blue bars show actual sales, gray bars show targets for each taluka",
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                           fontStyle: FontStyle.italic,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),

              
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLegendItem(Color color, String text) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 12,
//           height: 12,
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         const SizedBox(width: 6),
//         Text(
//           text,
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey[700],
//           ),
//         ),
//       ],
//     );
//   }
// }










// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:mega_pro/employee/emp_create_order_page.dart';
// import 'package:mega_pro/marketing/mar_employees.dart';
// import 'package:mega_pro/marketing/mar_reporting.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:mega_pro/global/global_variables.dart';

// // Import dashboard related pages

// import 'package:google_fonts/google_fonts.dart';
// import 'package:fl_chart/fl_chart.dart';

// // ===============================================
// // MARKETING MANAGER DASHBOARD (Main Screen)
// // ===============================================

// class MarketingManagerDashboard extends StatefulWidget {
//   const MarketingManagerDashboard({super.key, required Map userData});

//   @override
//   State<MarketingManagerDashboard> createState() =>
//       _MarketingManagerDashboardState();
// }

// class _MarketingManagerDashboardState extends State<MarketingManagerDashboard> {
//   int _currentIndex = 0;
  
//   // Pages for bottom navigation
//   final List<Widget> _pages = [
//     const DashboardContent(),
//     const EmployeeDetailPage(),
//     const CattleFeedOrderScreen(),
//     const ReportingPage(),
//     const MarketingProfilePage(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         title: Text(
//           _getAppBarTitle(_currentIndex),
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//           ),
//         ),
//         centerTitle: true,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: _pages[_currentIndex],
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10,
//               offset: const Offset(0, -2),
//             ),
//           ],
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _buildNavItem(0, Icons.dashboard, "Dashboard"),
//                 _buildNavItem(1, Icons.people, "Employees"),
//                 _buildNavItem(2, Icons.shopping_cart, "Orders"),
//                 _buildNavItem(3, Icons.bar_chart, "Reports"),
//                 _buildNavItem(4, Icons.person, "Profile"),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem(int index, IconData icon, String label) {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _currentIndex = index;
//         });
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: _currentIndex == index
//               ? GlobalColors.primaryBlue.withOpacity(0.1)
//               : Colors.transparent,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               color: _currentIndex == index
//                   ? GlobalColors.primaryBlue
//                   : Colors.grey[600],
//               size: 24,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 10,
//                 fontWeight: _currentIndex == index
//                     ? FontWeight.w600
//                     : FontWeight.normal,
//                 color: _currentIndex == index
//                     ? GlobalColors.primaryBlue
//                     : Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _getAppBarTitle(int index) {
//     switch (index) {
//       case 0:
//         return "Marketing Manager Dashboard";
//       case 1:
//         return "Employees";
//       case 2:
//         return "Make Order";
//       case 3:
//         return "Reports";
//       case 4:
//         return "Profile";
//       default:
//         return "Marketing Manager Dashboard";
//     }
//   }
// }

// // Dashboard Content Widget (separated for better organization)
// class DashboardContent extends StatefulWidget {
//   const DashboardContent({super.key});

//   @override
//   State<DashboardContent> createState() => _DashboardContentState();
// }

// class _DashboardContentState extends State<DashboardContent> {
//   // Sales are now in Tons (T)
//   final Map<String, List<Map<String, dynamic>>> _districtTalukaData = {
//     "Kolhapur": [
//       {"taluka": "Karvir", "sales": 220},
//       {"taluka": "Panhala", "sales": 160},
//       {"taluka": "Shirol", "sales": 140},
//       {"taluka": "Hatkanangale", "sales": 110},
//       {"taluka": "Kagal", "sales": 180},
//       {"taluka": "Shahuwadi", "sales": 95},
//       {"taluka": "Ajara", "sales": 75},
//       {"taluka": "Gadhinglaj", "sales": 205},
//       {"taluka": "Chandgad", "sales": 130},
//       {"taluka": "Radhanagari", "sales": 120},
//       {"taluka": "Jat", "sales": 90},
//       {"taluka": "Bhudargad", "sales": 150},
//     ],
//     "Sangli": [
//       {"taluka": "Miraj", "sales": 180},
//       {"taluka": "Kavathe Mahankal", "sales": 130},
//       {"taluka": "Walwa", "sales": 95},
//       {"taluka": "Khanapur", "sales": 110},
//     ],
//     "Satara": [
//       {"taluka": "Karad", "sales": 210},
//       {"taluka": "Koregaon", "sales": 140},
//       {"taluka": "Phaltan", "sales": 125},
//     ],
//     "Pune": [
//       {"taluka": "Haveli", "sales": 300},
//       {"taluka": "Mulshi", "sales": 95},
//       {"taluka": "Shirur", "sales": 160},
//       {"taluka": "Baramati", "sales": 220},
//     ],
//   };

//   // Fixed the selected district to Kolhapur since the selector is removed.
//   final String _selectedDistrict = "Kolhapur";

//   double _getMaxY(List<Map<String, dynamic>> talukas) {
//     return talukas.isNotEmpty
//         ? (talukas
//                 .map((e) => (e['sales'] as num).toDouble())
//                 .reduce((a, b) => a > b ? a : b)) *
//             1.15
//         : 100.0;
//   }

//   LineChartData _buildLineChartDataForDistrict(String district) {
//     final talukas = _districtTalukaData[district] ?? [];
//     final spots = List<FlSpot>.generate(talukas.length, (i) {
//       final value = (talukas[i]['sales'] as num).toDouble();
//       return FlSpot(i.toDouble(), value);
//     });

//     return LineChartData(
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: false,
//         horizontalInterval: _getMaxY(talukas) / 5,
//         getDrawingHorizontalLine: (value) =>
//             FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         rightTitles: const AxisTitles(
//           sideTitles: SideTitles(showTitles: false),
//         ),
//         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 80,
//             interval: 1,
//             getTitlesWidget: (value, meta) {
//               final i = value.toInt();
//               if (i < 0 || i >= talukas.length) {
//                 return const SizedBox.shrink();
//               }
//               return SideTitleWidget(
//                 axisSide: meta.axisSide,
//                 space: 10,
//                 child: Transform.rotate(
//                   angle: -0.6,
//                   child: Text(
//                     talukas[i]["taluka"],
//                     style: const TextStyle(fontSize: 11),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 40,
//             getTitlesWidget: (value, meta) => Text(
//               value.toInt().toString(), // Show Y-axis values as integers
//               style: const TextStyle(fontSize: 11),
//             ),
//           ),
//         ),
//       ),
//       borderData: FlBorderData(
//         show: true,
//         border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1),
//       ),
//       minX: 0,
//       maxX: (talukas.length - 1).toDouble(),
//       minY: 0,
//       maxY: _getMaxY(talukas),
//       lineBarsData: [
//         LineChartBarData(
//           spots: spots,
//           isCurved: true,
//           color: GlobalColors.primaryBlue,
//           barWidth: 4,
//           isStrokeCapRound: true,
//           dotData: const FlDotData(show: true),
//           belowBarData: BarAreaData(
//             show: true,
//             color: GlobalColors.primaryBlue.withOpacity(0.3),
//           ),
//         ),
//       ],
//     );
//   }

//   double _districtTotalSales(String district) {
//     final talukas = _districtTalukaData[district] ?? [];
//     return talukas.fold<double>(
//       0,
//       (sum, e) => sum + (e['sales'] as num).toDouble(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final talukaList = _districtTalukaData[_selectedDistrict] ?? [];
//     final lineChartData = _buildLineChartDataForDistrict(_selectedDistrict);

//     return SafeArea(
//       child: SingleChildScrollView(
//         physics: const BouncingScrollPhysics(),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // --- DISTRICT INFO CARD (Simplified) ---
//               Container(
//                 height: 80,
//                 width: double.infinity, // Take full width
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.05),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       'Sales for $_selectedDistrict (Tons)', // Updated title
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Total: ${_districtTotalSales(_selectedDistrict).toStringAsFixed(0)} T',
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.w700,
//                         fontSize: 20,
//                         color: GlobalColors.primaryBlue,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 18),
//               // ----------------------------------------

//               // Title
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Taluka-wise Sales Trend",
//                     style: GoogleFonts.poppins(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   Text(
//                     "${talukaList.length} talukas",
//                     style: GoogleFonts.poppins(color: Colors.grey[600]),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),

//               // Line Chart
//               Container(
//                 height: 360,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.06),
//                       blurRadius: 14,
//                       offset: const Offset(0, 6),
//                     ),
//                   ],
//                 ),
//                 padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//                 child: talukaList.isNotEmpty
//                     ? SingleChildScrollView(
//                         // <-- Handles horizontal overflow if many data points exist
//                         scrollDirection: Axis.horizontal,
//                         child: Row(
//                           // <-- Use Row to provide infinite horizontal constraints
//                           mainAxisSize: MainAxisSize
//                               .min, // <-- Key to let Row shrink-wrap content
//                           children: [
//                             SizedBox(
//                               // Calculate the required width: 40px for left title area +
//                               // 90px buffer for each data point. This forces the chart to be wide.
//                               width: 40.0 + (talukaList.length * 90.0),
//                               height: 344, // Match container height minus padding
//                               child: LineChart(lineChartData),
//                             ),
//                           ],
//                         ),
//                       )
//                     : Center(
//                         child: Text(
//                           "No Sales Data Available for $_selectedDistrict",
//                         ),
//                       ),
//               ),
//               const SizedBox(height: 36),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Marketing Profile Page (with fixed bottom overflow issue)
// class MarketingProfilePage extends StatefulWidget {
//   final Map<String, dynamic>? userData;

//   const MarketingProfilePage({super.key, this.userData});

//   @override
//   State<MarketingProfilePage> createState() => _MarketingProfilePageState();
// }

// class _MarketingProfilePageState extends State<MarketingProfilePage> {
//   final ImagePicker picker = ImagePicker();
//   File? profileImage;

//   Map<String, dynamic>? managerData;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadProfile();
//   }

//   // ================= LOAD PROFILE =================
//   Future<void> _loadProfile() async {
//     try {
//       final supabase = Supabase.instance.client;

//       // If userData is passed from dashboard, use it directly
//       if (widget.userData != null && widget.userData!.isNotEmpty) {
//         _processUserData(widget.userData!);
//         return;
//       }

//       // Otherwise fetch from database
//       final user = supabase.auth.currentUser;
//       if (user == null) return;

//       // Get data from emp_profile table using user_id
//       final data = await supabase
//           .from('emp_profile')
//           .select('*')
//           .eq('user_id', user.id)
//           .maybeSingle();

//       if (data == null) {
//         // Try with email as fallback
//         final emailData = await supabase
//             .from('emp_profile')
//             .select('*')
//             .eq('email', user.email!)
//             .maybeSingle();

//         if (emailData != null) {
//           _processUserData(emailData);
//         } else {
//           _createDefaultProfile(user.email!);
//         }
//       } else {
//         _processUserData(data);
//       }
//     } catch (e) {
//       debugPrint('Error loading profile: $e');
//       _createDefaultProfile('manager@mega.com');
//     }
//   }

//   void _processUserData(Map<String, dynamic> data) {
//     setState(() {
//       managerData = {
//         'empId': data['emp_id'] ?? data['emp_id'] ?? 'N/A',
//         'empName': data['full_name'] ?? data['full_name'] ?? 'Marketing Manager',
//         'position': data['position'] ?? data['position'] ?? 'Marketing Manager',
//         'branch': data['branch'] ?? data['branch'] ?? 'Head Office',
//         'district': data['district'] ?? data['district'] ?? 'N/A',
//         'joiningDate': data['joining_date'] != null
//             ? DateTime.parse(data['joining_date'])
//             : (data['joining_date'] != null
//                 ? DateTime.parse(data['joining_date'])
//                 : DateTime.now()),
//         'status': data['status'] ?? data['status'] ?? 'Active',
//         'phone': data['phone'] ?? data['phone'] ?? 'Not Provided',
//         'email': data['email'] ?? data['email'] ?? 'N/A',
//         'performance': (data['performance'] ?? data['performance'] ?? 0)
//             .toDouble(),
//         'attendance':
//             (data['attendance'] ?? data['attendance'] ?? 0).toDouble(),
//         'role': data['role'] ?? data['role'] ?? 'Marketing Manager',
//         'salary': data['salary'] ?? data['salary'] ?? 0,
//       };
//       isLoading = false;
//     });
//   }

//   void _createDefaultProfile(String email) {
//     setState(() {
//       managerData = {
//         'empId': 'MM${DateTime.now().millisecondsSinceEpoch % 1000}',
//         'empName': 'Marketing Manager',
//         'position': 'Marketing Manager',
//         'branch': 'Marketing Department',
//         'district': 'Corporate',
//         'joiningDate': DateTime.now(),
//         'status': 'Active',
//         'phone': '9876543210',
//         'email': email,
//         'performance': 85.0,
//         'attendance': 95.0,
//         'role': 'Marketing Manager',
//         'salary': 0,
//       };
//       isLoading = false;
//     });
//   }

//   // ================= IMAGE PICKER =================
//   Future<void> pickProfileImage() async {
//     final XFile? file =
//         await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
//     if (file != null) {
//       setState(() => profileImage = File(file.path));
//     }
//   }

//   Future<void> _logout() async {
//     try {
//       await Supabase.instance.client.auth.signOut();
//       Navigator.pushNamedAndRemoveUntil(
//         context,
//         '/',
//         (route) => false,
//       );
//     } catch (e) {
//       print('Error logging out: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         backgroundColor: GlobalColors.background,
//         body: const Center(
//           child: CircularProgressIndicator(
//             color: GlobalColors.primaryBlue,
//           ),
//         ),
//       );
//     }

//     if (managerData == null) {
//       return Scaffold(
//         backgroundColor: GlobalColors.background,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.error_outline, size: 64, color: Colors.grey),
//               const SizedBox(height: 16),
//               const Text(
//                 'Profile Not Found',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Contact administrator to set up your profile',
//                 style: TextStyle(color: Colors.grey),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _loadProfile,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: GlobalColors.primaryBlue,
//                 ),
//                 child:
//                     const Text('Retry', style: TextStyle(color: Colors.white)),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     final manager = managerData!;

//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           physics: const BouncingScrollPhysics(),
//           child: Column(
//             children: [
//               _buildProfileHeader(manager),
//               const SizedBox(height: 20),
//               _buildTabSection(manager),
//               const SizedBox(height: 20), // Added padding at bottom
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ================= PROFILE HEADER =================
//   Widget _buildProfileHeader(Map<String, dynamic> manager) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             GlobalColors.primaryBlue,
//             GlobalColors.primaryBlue.withOpacity(0.9),
//           ],
//         ),
//         borderRadius: const BorderRadius.only(
//           bottomLeft: Radius.circular(24),
//           bottomRight: Radius.circular(24),
//         ),
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Stack(
//                 children: [
//                   Container(
//                     width: 80,
//                     height: 80,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       border: Border.all(color: Colors.white, width: 3),
//                     ),
//                     child: CircleAvatar(
//                       radius: 40,
//                       backgroundColor: Colors.white,
//                       backgroundImage:
//                           profileImage != null ? FileImage(profileImage!) : null,
//                       child: profileImage == null
//                           ? Text(
//                               (manager['empName'] is String &&
//                                       manager['empName'].isNotEmpty)
//                                   ? manager['empName']
//                                       .substring(0, 2)
//                                       .toUpperCase()
//                                   : "MM",
//                               style: TextStyle(
//                                 fontSize: 28,
//                                 fontWeight: FontWeight.bold,
//                                 color: GlobalColors.primaryBlue,
//                               ),
//                             )
//                           : null,
//                     ),
//                   ),
//                   Positioned(
//                     bottom: 0,
//                     right: 0,
//                     child: GestureDetector(
//                       onTap: pickProfileImage,
//                       child: Container(
//                         padding: const EdgeInsets.all(6),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.15),
//                               blurRadius: 4,
//                             )
//                           ],
//                         ),
//                         child: Icon(
//                           Icons.camera_alt,
//                           size: 18,
//                           color: GlobalColors.primaryBlue,
//                         ),
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//               const SizedBox(width: 20),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       manager['empName']?.toString() ?? 'Marketing Manager',
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       manager['position']?.toString() ?? 'Marketing Manager',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.9),
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 6,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         manager['status']?.toString() ?? 'Active',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               )
//             ],
//           ),
//           const SizedBox(height: 20),
//           _buildManagerIdCard(manager),
//         ],
//       ),
//     );
//   }

//   Widget _buildManagerIdCard(Map<String, dynamic> manager) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.white.withOpacity(0.2)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           _idItem("Employee ID", manager['empId']?.toString() ?? 'N/A'),
//           _idItem("Branch", manager['branch']?.toString() ?? 'N/A'),
//           _idItem(
//             "Since",
//             DateFormat("MMM yyyy").format(
//                 manager['joiningDate'] is DateTime
//                     ? manager['joiningDate']
//                     : DateTime.now()),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _idItem(String title, String value) {
//     return Expanded(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.8),
//               fontSize: 12,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 15,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= TABS =================
//   Widget _buildTabSection(Map<String, dynamic> manager) {
//     return DefaultTabController(
//       length: 2,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 6,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: TabBar(
//               labelColor: GlobalColors.primaryBlue,
//               unselectedLabelColor: Colors.grey[600],
//               indicator: BoxDecoration(
//                 color: GlobalColors.primaryBlue.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               tabs: const [
//                 Tab(text: "Details"),
//                 Tab(text: "Performance"),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             height: MediaQuery.of(context).size.height * 0.5, // Fixed height to prevent overflow
//             child: TabBarView(
//               children: [
//                 _detailsTab(manager),
//                 _performanceTab(manager),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _detailsTab(Map<String, dynamic> manager) {
//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 _infoItem(Icons.email, "Email",
//                     manager['email']?.toString() ?? 'N/A'),
//                 const Divider(),
//                 _infoItem(Icons.phone, "Phone",
//                     manager['phone']?.toString() ?? 'N/A'),
//                 const Divider(),
//                 _infoItem(Icons.location_on, "District",
//                     manager['district']?.toString() ?? 'N/A'),
//                 const Divider(),
//                 _infoItem(Icons.business, "Branch",
//                     manager['branch']?.toString() ?? 'N/A'),
//                 const Divider(),
//                 _infoItem(
//                   Icons.calendar_today,
//                   "Joining Date",
//                   DateFormat('dd MMMM yyyy').format(
//                     manager['joiningDate'] is DateTime
//                         ? manager['joiningDate']
//                         : DateTime.now(),
//                   ),
//                 ),
//                 if (manager['role'] != null) ...[
//                   const Divider(),
//                   _infoItem(
//                       Icons.work, "Role", manager['role']?.toString() ?? 'N/A'),
//                 ],
//                 if (manager['salary'] != null && manager['salary'] > 0) ...[
//                   const Divider(),
//                   _infoItem(Icons.currency_rupee, "Salary",
//                       "₹${manager['salary']}"),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _performanceTab(Map<String, dynamic> manager) {
//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Column(
//           children: [
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _metricCard("Performance",
//                         manager['performance']?.toDouble() ?? 0.0,
//                         GlobalColors.primaryBlue),
//                     Container(
//                       width: 1,
//                       height: 60,
//                       color: Colors.grey[300],
//                     ),
//                     _metricCard("Attendance",
//                         manager['attendance']?.toDouble() ?? 0.0,
//                         GlobalColors.primaryBlue),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Additional Marketing Metrics
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Marketing Performance",
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     _marketingMetric(
//                       title: "Target Achievement",
//                       value: "92.5%",
//                       color: Colors.green,
//                     ),
//                     const SizedBox(height: 12),
//                     _marketingMetric(
//                       title: "Campaign ROI",
//                       value: "24.5%",
//                       color: Colors.orange,
//                     ),
//                     const SizedBox(height: 12),
//                     _marketingMetric(
//                       title: "Team Productivity",
//                       value: "88%",
//                       color: Colors.purple,
//                     ),
//                     const SizedBox(height: 12),
//                     _marketingMetric(
//                       title: "Customer Satisfaction",
//                       value: "94%",
//                       color: Colors.blue,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _metricCard(String title, double value, Color color) {
//     return Expanded(
//       child: Column(
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey[700],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "${value.toStringAsFixed(1)}%",
//             style: TextStyle(
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Container(
//             width: 60,
//             height: 6,
//             decoration: BoxDecoration(
//               color: Colors.grey[200],
//               borderRadius: BorderRadius.circular(3),
//             ),
//             child: FractionallySizedBox(
//               alignment: Alignment.centerLeft,
//               widthFactor: value / 100,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: color,
//                   borderRadius: BorderRadius.circular(3),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _marketingMetric({
//     required String title,
//     required String value,
//     required Color color,
//   }) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: Colors.grey[700],
//           ),
//         ),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _infoItem(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: GlobalColors.primaryBlue.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(icon, color: GlobalColors.primaryBlue, size: 20),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }