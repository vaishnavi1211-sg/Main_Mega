import 'package:flutter/material.dart';
import 'package:mega_pro/global/global_variables.dart';

class OwnerReportsPage extends StatefulWidget {
  final List<Map<String, dynamic>> assignedTargets;
  final List<Map<String, dynamic>> activityLogs;

  const OwnerReportsPage({
    super.key,
    required this.assignedTargets,
    required this.activityLogs,
  });

  @override
  State<OwnerReportsPage> createState() => _OwnerReportsPageState();
}

class _OwnerReportsPageState extends State<OwnerReportsPage> {
  bool showTargets = true;
  int? expandedAnnouncementIndex;

  @override
  Widget build(BuildContext context) {
    final announcements = widget.activityLogs
        .where((log) => log["type"] == "announcement")
        .toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          "Owner Reports",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.cardBg,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ================= TOGGLE =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _toggle("Assigned Targets", showTargets,
                      () => setState(() => showTargets = true)),
                  _toggle("Announcements", !showTargets,
                      () => setState(() => showTargets = false)),
                ],
              ),
            ),
          ),

          // ================= CONTENT =================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: showTargets
                  ? _buildTargets()
                  : _buildAnnouncements(announcements),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ASSIGNED TARGETS =================
  Widget _buildTargets() {
    if (widget.assignedTargets.isEmpty) {
      return _emptyState("No targets assigned yet");
    }

    return Column(
      children: widget.assignedTargets.map(_targetCard).toList(),
    );
  }

  Widget _targetCard(Map<String, dynamic> t) {
    final bool isSummary =
        t["branch"] == "All Branches" || t["manager"] == "All Managers";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          // HEADER
          Row(
            children: [
              const Icon(Icons.flag, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSummary
                      ? "Target Assigned to All"
                      : "${t['branch']} • ${t['month']}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _openEditTargetSheet(t),
              ),
              IconButton(
                icon: const Icon(Icons.delete,
                    color: Colors.red, size: 20),
                onPressed: () {
                  setState(() {
                    widget.assignedTargets.remove(t);
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 10),
          _infoRow("Branch", t["branch"]),
          _infoRow("Manager", t["manager"]),
          _infoRow("Month", t["month"]),
          _infoRow("Revenue", "₹${t['revenue']}"),
          _infoRow("Orders", t["orders"]),

          if (t["remarks"] != null &&
              t["remarks"].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Remarks: ${t['remarks']}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= EDIT TARGET (IMPROVED UI) =================
  void _openEditTargetSheet(Map<String, dynamic> t) {
    final revenueCtrl = TextEditingController(text: t["revenue"]);
    final orderCtrl = TextEditingController(text: t["orders"]);
    final remarksCtrl = TextEditingController(text: t["remarks"]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Edit Assigned Target",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _editField("Revenue Target", revenueCtrl),
            const SizedBox(height: 12),
            _editField("Order Target", orderCtrl),
            const SizedBox(height: 12),
            _editField("Remarks", remarksCtrl, maxLines: 2),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    onPressed: () {
                      setState(() {
                        t["revenue"] = revenueCtrl.text;
                        t["orders"] = orderCtrl.text;
                        t["remarks"] = remarksCtrl.text;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= ANNOUNCEMENTS (PREVIOUS UI) =================
  Widget _buildAnnouncements(List<Map<String, dynamic>> announcements) {
    if (announcements.isEmpty) {
      return _emptyState("No announcements sent yet");
    }

    return Column(
      children: announcements.asMap().entries.map((entry) {
        final index = entry.key;
        final a = entry.value;
        final isExpanded = expandedAnnouncementIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              expandedAnnouncementIndex =
                  isExpanded ? null : index;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
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
                Row(
                  children: [
                    const Icon(Icons.campaign,
                        color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Announcement",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  a["time"],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey.shade300),
                  Text(
                    a["message"],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ================= UI HELPERS =================
  Widget _toggle(String title, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                selected ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color:
                    selected ? Colors.white : AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _editField(String label, TextEditingController c,
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

  Widget _emptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
