import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/owner/own_view_reports.dart';

class OwnerQuickActionsPage extends StatefulWidget {
  const OwnerQuickActionsPage({super.key});

  @override
  State<OwnerQuickActionsPage> createState() => _OwnerQuickActionsPageState();
}

class _OwnerQuickActionsPageState extends State<OwnerQuickActionsPage> {
  List<Map<String, dynamic>> activityLogs = [];
  List<Map<String, dynamic>> assignedTargets = [];

  final List<String> branches = [
    "All Branches",
    "Nagpur",
    "Kolhapur",
    "Pune",
  ];

  final List<String> marketingManagers = [
    "All Managers",
    "Amit Sharma",
    "Priya Verma",
    "Rohit Desai",
  ];

  // ---------------- CONTROLLERS ----------------
  final TextEditingController _announcementController =
      TextEditingController();
  final TextEditingController _revenueTargetController =
      TextEditingController();
  final TextEditingController _orderTargetController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  String? selectedBranch;
  String? selectedManager;
  DateTime? selectedMonth;

  // ---------------- GENERIC LOG ----------------
  void addLog(String message) {
    activityLogs.insert(0, {
      "type": "log",
      "message": message,
      "time": DateFormat('dd MMM yyyy • hh:mm a').format(DateTime.now()),
    });
    setState(() {});
  }

  // ---------------- ANNOUNCEMENT ----------------
  void sendAnnouncement() {
    final message = _announcementController.text.trim();
    if (message.isEmpty) return;

    activityLogs.insert(0, {
      "type": "announcement",
      "message": message,
      "time": DateFormat('dd MMM yyyy • hh:mm a').format(DateTime.now()),
    });

    _announcementController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Announcement Sent Successfully")),
    );

    setState(() {});
  }

  // ---------------- PICK MONTH ----------------
  Future<void> pickMonth() async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() => selectedMonth = picked);
    }
  }

  // ---------------- ASSIGN TARGET (UPDATED) ----------------
  void assignMonthlyTarget() {
    if (selectedBranch == null ||
        selectedManager == null ||
        selectedMonth == null ||
        _revenueTargetController.text.isEmpty ||
        _orderTargetController.text.isEmpty) {
      return;
    }

    // ✅ HANDLE ALL / SINGLE BRANCHES
    final List<String> targetBranches =
        selectedBranch == "All Branches"
            ? branches.where((b) => b != "All Branches").toList()
            : [selectedBranch!];

    // ✅ HANDLE ALL / SINGLE MANAGERS
    final List<String> targetManagers =
        selectedManager == "All Managers"
            ? marketingManagers
                .where((m) => m != "All Managers")
                .toList()
            : [selectedManager!];

    // ✅ CREATE TARGETS IN BULK
    for (final branch in targetBranches) {
      for (final manager in targetManagers) {
        assignedTargets.add({
          "branch": branch,
          "manager": manager,
          "month": DateFormat('MMMM yyyy').format(selectedMonth!),
          "revenue": _revenueTargetController.text,
          "orders": _orderTargetController.text,
          "remarks": _remarksController.text,
        });
      }
    }

    addLog(
      "🎯 Target assigned to $selectedBranch / $selectedManager "
      "(${DateFormat('MMM yyyy').format(selectedMonth!)})",
    );

    selectedBranch = null;
    selectedManager = null;
    selectedMonth = null;
    _revenueTargetController.clear();
    _orderTargetController.clear();
    _remarksController.clear();

    setState(() {});
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          "Control Panel",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.softGreyBg,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),

        actions: [
          IconButton(
            tooltip: "View Reports",
            icon: const Icon(Icons.analytics, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OwnerReportsPage(
                    assignedTargets: assignedTargets,
                    activityLogs: activityLogs,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // -------- ANNOUNCEMENT --------
            _sectionCard(
              title: "Company Announcement",
              subtitle: "Broadcast message to all departments",
              child: Column(
                children: [
                  TextField(
                    controller: _announcementController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Enter announcement message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: const Text(
                        "Send",
                        style: TextStyle(color: AppColors.softGreyBg),
                      ),
                      onPressed: sendAnnouncement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // -------- TARGET ASSIGNMENT --------
            _sectionCard(
              title: "Assign Monthly Target",
              subtitle: "Set revenue & order goals",
              child: Column(
                children: [
                  _dropdown(
                    "Select Branch",
                    branches,
                    (v) => setState(() => selectedBranch = v),
                    value: selectedBranch,
                  ),
                  const SizedBox(height: 10),
                  _dropdown(
                    "Marketing Manager",
                    marketingManagers,
                    (v) => setState(() => selectedManager = v),
                    value: selectedManager,
                  ),
                  const SizedBox(height: 10),
                  _input("Revenue Target (₹)", _revenueTargetController),
                  const SizedBox(height: 10),
                  _input("Order Target (Qty)", _orderTargetController),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedMonth == null
                              ? "No month selected"
                              : DateFormat('MMMM yyyy')
                                  .format(selectedMonth!),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: pickMonth,
                        child: const Text(
                          "Select Month",
                          style:
                              TextStyle(color: AppColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _input(
                    "Remarks (Optional)",
                    _remarksController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: assignMonthlyTarget,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      minimumSize: const Size.fromHeight(45),
                    ),
                    child: const Text(
                      "Assign Target",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- UI HELPERS ----------------
  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: AppColors.shadowGrey,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _input(String label, TextEditingController c,
      {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    ValueChanged<String?> onChanged, {
    String? value,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
