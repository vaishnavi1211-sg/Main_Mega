import 'package:flutter/material.dart';
import 'package:mega_pro/global/global_variables.dart';

class CompletedOrdersPage extends StatefulWidget {
  const CompletedOrdersPage({super.key});

  @override
  State<CompletedOrdersPage> createState() => _CompletedOrdersPageState();
}

class _CompletedOrdersPageState extends State<CompletedOrdersPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = "";

  final List<Map<String, dynamic>> _completedOrders = [
    {
      "month": "October 2023",
      "id": "#ORD-4921",
      "name": "Krishna Dairy Farm",
      "date": "Oct 24",
      "bags": "25",
      "weight": "500 kg",
      "amount": "₹ 12,500",
      "status": "Delivered",
      "statusColor": GlobalColors.success,
    },
    {
      "month": "October 2023",
      "id": "#ORD-4890",
      "name": "Anand Traders",
      "date": "Oct 22",
      "bags": "100",
      "weight": "2,500 kg",
      "amount": "₹ 45,000",
      "status": "Delivered",
      "statusColor": GlobalColors.success,
    },
    {
      "month": "October 2023",
      "id": "#ORD-4855",
      "name": "Shree Ram Gaushala",
      "date": "Oct 20",
      "bags": "15",
      "weight": "375 kg",
      "amount": "₹ 8,200",
      "status": "Cancelled",
      "statusColor": GlobalColors.danger,
    },
    {
      "month": "September 2023",
      "id": "#ORD-4712",
      "name": "Gopal Dairy",
      "date": "Sep 28",
      "bags": "45",
      "weight": "1,125 kg",
      "amount": "₹ 22,100",
      "status": "Delivered",
      "statusColor": GlobalColors.success,
    },
    {
      "month": "September 2023",
      "id": "#ORD-4688",
      "name": "Modern Cattle Farm",
      "date": "Sep 25",
      "bags": "30",
      "weight": "750 kg",
      "amount": "₹ 18,750",
      "status": "Delivered",
      "statusColor": GlobalColors.success,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _completedOrders.where((o) {
      return o["name"].toLowerCase().contains(_query) ||
          o["id"].toLowerCase().contains(_query);
    }).toList();

    // Group orders by month
    final Map<String, List<Map<String, dynamic>>> groupedOrders = {};
    for (var order in filteredOrders) {
      final month = order["month"];
      if (!groupedOrders.containsKey(month)) {
        groupedOrders[month] = [];
      }
      groupedOrders[month]!.add(order);
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: GlobalColors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GlobalColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Completed Orders",
          style: TextStyle(
            color: GlobalColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: GlobalColors.primaryBlue,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Text(
                  "Delivered and cancelled order history",
                  style: TextStyle(
                    color: GlobalColors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  // Search Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GlobalColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowGrey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: "Search completed orders...",
                        prefixIcon: const Icon(Icons.search,
                            color: GlobalColors.primaryBlue),
                        filled: true,
                        fillColor: AppColors.softGreyBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Orders List Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Order History",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      Text(
                        "${filteredOrders.length} Orders",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Orders List
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: groupedOrders.length,
                      itemBuilder: (context, index) {
                        final month = groupedOrders.keys.elementAt(index);
                        final monthOrders = groupedOrders[month]!;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Month Header
                            Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 8, top: index > 0 ? 16 : 0),
                              child: Text(
                                month,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ),
                            
                            // Orders for this month
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: monthOrders.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, orderIndex) {
                                final order = monthOrders[orderIndex];
                                return _buildOrderCard(order);
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> data) {
    final disabled = data["status"] == "Cancelled";

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.borderGrey,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Order ID and Customer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data["id"],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data["name"],
                        style: TextStyle(
                          fontSize: 13,
                          color: disabled
                              ? AppColors.secondaryText
                              : AppColors.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (data["statusColor"] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (data["statusColor"] as Color).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    data["status"],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: data["statusColor"],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date and Bags
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Text(
                  data["date"],
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.scale,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Text(
                  "${data["bags"]} Bags",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Weight
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Text(
                  data["weight"],
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom row with amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Amount",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data["amount"],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                        decoration: disabled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
                if (data["status"] == "Delivered")
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: GlobalColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: GlobalColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Completed",
                          style: TextStyle(
                            fontSize: 12,
                            color: GlobalColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}