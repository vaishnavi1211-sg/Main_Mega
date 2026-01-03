import 'package:flutter/material.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final List<Map<String, dynamic>> _salesData = [
    {
      "product": "Calf Starter",
      "sales": 125000,
      "growth": 12.5,
      "units": 2500,
      "region": "North",
      "target": 150000
    },
    {
      "product": "Dairy Feed",
      "sales": 320000,
      "growth": 8.2,
      "units": 6400,
      "region": "West",
      "target": 300000
    },
    {
      "product": "Poultry Feed",
      "sales": 185000,
      "growth": -2.1,
      "units": 3700,
      "region": "South",
      "target": 200000
    },
    {
      "product": "Cattle Grower",
      "sales": 275000,
      "growth": 15.8,
      "units": 5500,
      "region": "East",
      "target": 250000
    },
    {
      "product": "Mineral Mix",
      "sales": 89000,
      "growth": 5.4,
      "units": 1780,
      "region": "Central",
      "target": 100000
    },
  ];

  final List<Map<String, dynamic>> _topCustomers = [
    {
      "name": "Shree Dairy Farm",
      "orders": 45,
      "value": 450000,
      "growth": 25.0,
      "status": "Premium"
    },
    {
      "name": "Mohan Cattle Care",
      "orders": 32,
      "value": 320000,
      "growth": 12.3,
      "status": "Regular"
    },
    {
      "name": "Green Pastures Ltd",
      "orders": 28,
      "value": 275000,
      "growth": -5.2,
      "status": "Regular"
    },
    {
      "name": "Royal Poultry",
      "orders": 24,
      "value": 185000,
      "growth": 8.7,
      "status": "New"
    },
    {
      "name": "Modern Agro",
      "orders": 18,
      "value": 150000,
      "growth": 15.4,
      "status": "Premium"
    },
  ];

  Color _getProductColor(String product) {
    switch (product) {
      case "Calf Starter":
        return Colors.blue;
      case "Dairy Feed":
        return Colors.green;
      case "Poultry Feed":
        return Colors.orange;
      case "Cattle Grower":
        return Colors.purple;
      case "Mineral Mix":
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSales = _salesData.fold<double>(0, (sum, item) => sum + item["sales"].toDouble());
    final totalTarget = _salesData.fold<double>(0, (sum, item) => sum + item["target"].toDouble());
    final achievement = (totalSales / totalTarget * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Sales Dashboard"),
        backgroundColor: Colors.white,
        elevation: 1,
        
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Metrics
            _buildKeyMetrics(totalSales, achievement),
            const SizedBox(height: 20),

            // Sales Performance
            _buildSalesPerformance(),
            const SizedBox(height: 20),

            // Top Products
            _buildTopProducts(),
            const SizedBox(height: 20),

            // Top Customers
            _buildTopCustomers(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetrics(double totalSales, String achievement) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _metricCard(
          "Total Revenue",
          "₹${(totalSales / 1000).toStringAsFixed(0)}K",
          "+12.5%",
          Icons.currency_rupee,
          Colors.green,
        ),
        _metricCard(
          "Target Achievement",
          "$achievement%",
          "On Track",
          Icons.flag,
          Colors.blue,
        ),
        _metricCard(
          "Total Orders",
          "1,248",
          "+8.2%",
          Icons.shopping_cart,
          Colors.orange,
        ),
        _metricCard(
          "Avg Order Value",
          "₹7,890",
          "+4.3%",
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value, String growth, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                growth,
                style: TextStyle(
                  color: growth.startsWith('+') || growth == "On Track" ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesPerformance() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sales Performance",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._salesData.map((product) => _performanceItem(product)),
        ],
      ),
    );
  }

  Widget _performanceItem(Map<String, dynamic> product) {
    final achievement = (product["sales"] / product["target"] * 100).round();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product["product"],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "₹${(product["sales"] / 1000).toStringAsFixed(0)}K",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: LinearProgressIndicator(
                  value: product["sales"] / product["target"],
                  backgroundColor: Colors.grey.shade200,
                  color: _getProductColor(product["product"]),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Text(
                  "$achievement%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: achievement >= 100 ? Colors.green : Colors.orange,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Text(
                  "${product["growth"]}%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: product["growth"] > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "${product["units"]} Units • ${product["region"]} Region",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Top Products",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "View All",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._salesData.map((product) => _productItem(product)),
        ],
      ),
    );
  }

  Widget _productItem(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getProductColor(product["product"]).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory,
              color: _getProductColor(product["product"]),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product["product"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${product["units"]} Units • ${product["region"]}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${(product["sales"] / 1000).toStringAsFixed(0)}K",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${product["growth"]}%",
                style: TextStyle(
                  fontSize: 12,
                  color: product["growth"] > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopCustomers() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Top Customers",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "View All",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._topCustomers.map((customer) => _customerItem(customer)),
        ],
      ),
    );
  }

  Widget _customerItem(Map<String, dynamic> customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer["name"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "${customer["orders"]} Orders",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: customer["status"] == "Premium" ? Colors.amber.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        customer["status"],
                        style: TextStyle(
                          fontSize: 10,
                          color: customer["status"] == "Premium" ? Colors.amber : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${(customer["value"] / 1000).toStringAsFixed(0)}K",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${customer["growth"]}%",
                style: TextStyle(
                  fontSize: 12,
                  color: customer["growth"] > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}