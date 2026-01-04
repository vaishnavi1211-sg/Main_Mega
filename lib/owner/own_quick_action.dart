import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/models/mar_manager_model.dart';
import 'package:mega_pro/services/mar_target_assigning_services.dart';


class AssignTargetPage extends StatefulWidget {
  const AssignTargetPage({super.key});

  @override
  State<AssignTargetPage> createState() => _AssignTargetPageState();
}

class _AssignTargetPageState extends State<AssignTargetPage> {
  final MarketingTargetService _targetService = MarketingTargetService();
  final _formKey = GlobalKey<FormState>();

  // State variables
  String _selectedBranch = 'All Branches';
  DateTime _selectedMonth = DateTime.now();
  List<String> _selectedManagers = [];
  List<MarketingManager> _allManagers = [];
  List<String> _branches = ['All Branches'];
  
  // Controllers
  final TextEditingController _revenueController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _isLoading = false;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _branches = await _targetService.getBranches();
      _allManagers = await _targetService.getMarketingManagers();
      setState(() {});
    } catch (e) {
      _showSnackBar('Failed to load data: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _assignTargets() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedManagers.isEmpty) {
      _showSnackBar('Please select at least one manager', isError: true);
      return;
    }

    setState(() => _isAssigning = true);
    
    try {
      final success = await _targetService.assignTargets(
        managerIds: _selectedManagers,
        branch: _selectedBranch == 'All Branches' ? 'All' : _selectedBranch,
        targetMonth: _selectedMonth,
        revenueTarget: int.parse(_revenueController.text),
        orderTarget: int.parse(_orderController.text),
        remarks: _remarksController.text.isNotEmpty ? _remarksController.text : null,
      );

      if (success) {
        _showSnackBar('Targets assigned successfully!', isError: false);
        _resetForm();
      } else {
        _showSnackBar('Failed to assign targets', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isAssigning = false);
    }
  }

  void _resetForm() {
    _selectedManagers.clear();
    _revenueController.clear();
    _orderController.clear();
    _remarksController.clear();
    setState(() {});
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<MarketingManager> get _filteredManagers {
    if (_selectedBranch == 'All Branches') return _allManagers;
    return _allManagers.where((m) => m.branch == _selectedBranch).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Marketing Targets'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Branch Selection
                    _buildSectionHeader('Select Branch'),
                    _buildBranchDropdown(),

                    const SizedBox(height: 24),

                    // Target Month
                    _buildSectionHeader('Target Month'),
                    _buildMonthSelector(),

                    const SizedBox(height: 24),

                    // Select Managers
                    _buildSectionHeader('Select Managers'),
                    _buildManagersSelection(),

                    const SizedBox(height: 24),

                    // Targets Input
                    _buildSectionHeader('Set Targets'),
                    _buildTargetsInput(),

                    const SizedBox(height: 24),

                    // Remarks
                    _buildSectionHeader('Remarks (Optional)'),
                    _buildRemarksInput(),

                    const SizedBox(height: 32),

                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBranchDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBranch,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          onChanged: (value) {
            setState(() {
              _selectedBranch = value!;
              _selectedManagers.clear();
            });
          },
          items: _branches.map((branch) {
            return DropdownMenuItem(
              value: branch,
              child: Text(branch),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return GestureDetector(
      onTap: () => _selectMonth(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            Text(
              DateFormat('MM/yyyy').format(_selectedMonth),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'SELECT MONTH',
      cancelText: 'CANCEL',
      confirmText: 'SELECT',
      fieldHintText: 'Month/Year',
      fieldLabelText: 'Enter month',
    );
    
    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  Widget _buildManagersSelection() {
    if (_filteredManagers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            'No managers found for $_selectedBranch',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Select All Button
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Checkbox(
                  value: _selectedManagers.length == _filteredManagers.length && _filteredManagers.isNotEmpty,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedManagers = _filteredManagers.map((m) => m.id).toList();
                      } else {
                        _selectedManagers.clear();
                      }
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Select All (${_filteredManagers.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Managers List
          SizedBox(
            height: 200,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _filteredManagers.length,
              itemBuilder: (context, index) {
                final manager = _filteredManagers[index];
                final isSelected = _selectedManagers.contains(manager.id);
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    manager.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${manager.branch} • ${manager.position}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedManagers.add(manager.id);
                        } else {
                          _selectedManagers.remove(manager.id);
                        }
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedManagers.remove(manager.id);
                      } else {
                        _selectedManagers.add(manager.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetsInput() {
    return Row(
      children: [
        // Revenue Target
        Expanded(
          child: _buildTargetField(
            controller: _revenueController,
            label: 'Revenue Target',
            hint: 'Enter amount',
            prefix: '₹',
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (int.tryParse(value) == null) return 'Enter valid number';
              if (int.parse(value) <= 0) return 'Must be greater than 0';
              return null;
            },
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Order Target
        Expanded(
          child: _buildTargetField(
            controller: _orderController,
            label: 'Order Target',
            hint: 'Enter count',
            prefix: '#',
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (int.tryParse(value) == null) return 'Enter valid number';
              if (int.parse(value) <= 0) return 'Must be greater than 0';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTargetField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String prefix,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: '$prefix ',
            prefixStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildRemarksInput() {
    return TextFormField(
      controller: _remarksController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Add any additional notes or instructions...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Reset Button
        Expanded(
          child: OutlinedButton(
            onPressed: _resetForm,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Reset',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Assign Button
        Expanded(
          child: ElevatedButton(
            onPressed: _isAssigning ? null : _assignTargets,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: _isAssigning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Assign Targets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _revenueController.dispose();
    _orderController.dispose();
    _remarksController.dispose();
    super.dispose();
  }
}



// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:mega_pro/owner/own_view_reports.dart';

// class OwnerQuickActionsPage extends StatefulWidget {
//   const OwnerQuickActionsPage({super.key});

//   @override
//   State<OwnerQuickActionsPage> createState() => _OwnerQuickActionsPageState();
// }

// class _OwnerQuickActionsPageState extends State<OwnerQuickActionsPage> {
//   List<Map<String, dynamic>> activityLogs = [];
//   List<Map<String, dynamic>> assignedTargets = [];

//   final List<String> branches = [
//     "All Branches",
//     "Nagpur",
//     "Kolhapur",
//     "Pune",
//   ];

//   final List<String> marketingManagers = [
//     "All Managers",
//     "Amit Sharma",
//     "Priya Verma",
//     "Rohit Desai",
//   ];

//   // ---------------- CONTROLLERS ----------------
//   final TextEditingController _announcementController =
//       TextEditingController();
//   final TextEditingController _revenueTargetController =
//       TextEditingController();
//   final TextEditingController _orderTargetController =
//       TextEditingController();
//   final TextEditingController _remarksController = TextEditingController();

//   String? selectedBranch;
//   String? selectedManager;
//   DateTime? selectedMonth;

//   // ---------------- GENERIC LOG ----------------
//   void addLog(String message) {
//     activityLogs.insert(0, {
//       "type": "log",
//       "message": message,
//       "time": DateFormat('dd MMM yyyy • hh:mm a').format(DateTime.now()),
//     });
//     setState(() {});
//   }

//   // ---------------- ANNOUNCEMENT ----------------
//   void sendAnnouncement() {
//     final message = _announcementController.text.trim();
//     if (message.isEmpty) return;

//     activityLogs.insert(0, {
//       "type": "announcement",
//       "message": message,
//       "time": DateFormat('dd MMM yyyy • hh:mm a').format(DateTime.now()),
//     });

//     _announcementController.clear();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Announcement Sent Successfully")),
//     );

//     setState(() {});
//   }

//   // ---------------- PICK MONTH ----------------
//   Future<void> pickMonth() async {
//     DateTime now = DateTime.now();
//     DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: now,
//       firstDate: DateTime(now.year - 1),
//       lastDate: DateTime(now.year + 2),
//     );

//     if (picked != null) {
//       setState(() => selectedMonth = picked);
//     }
//   }

//   // ---------------- ASSIGN TARGET (UPDATED) ----------------
//   void assignMonthlyTarget() {
//     if (selectedBranch == null ||
//         selectedManager == null ||
//         selectedMonth == null ||
//         _revenueTargetController.text.isEmpty ||
//         _orderTargetController.text.isEmpty) {
//       return;
//     }

//     // ✅ HANDLE ALL / SINGLE BRANCHES
//     final List<String> targetBranches =
//         selectedBranch == "All Branches"
//             ? branches.where((b) => b != "All Branches").toList()
//             : [selectedBranch!];

//     // ✅ HANDLE ALL / SINGLE MANAGERS
//     final List<String> targetManagers =
//         selectedManager == "All Managers"
//             ? marketingManagers
//                 .where((m) => m != "All Managers")
//                 .toList()
//             : [selectedManager!];

//     // ✅ CREATE TARGETS IN BULK
//     for (final branch in targetBranches) {
//       for (final manager in targetManagers) {
//         assignedTargets.add({
//           "branch": branch,
//           "manager": manager,
//           "month": DateFormat('MMMM yyyy').format(selectedMonth!),
//           "revenue": _revenueTargetController.text,
//           "orders": _orderTargetController.text,
//           "remarks": _remarksController.text,
//         });
//       }
//     }

//     addLog(
//       "🎯 Target assigned to $selectedBranch / $selectedManager "
//       "(${DateFormat('MMM yyyy').format(selectedMonth!)})",
//     );

//     selectedBranch = null;
//     selectedManager = null;
//     selectedMonth = null;
//     _revenueTargetController.clear();
//     _orderTargetController.clear();
//     _remarksController.clear();

//     setState(() {});
//   }

//   // ---------------- UI ----------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         title: const Text(
//           "Control Panel",
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             color: AppColors.softGreyBg,
//           ),
//         ),
//         backgroundColor: AppColors.primaryBlue,
//         iconTheme: const IconThemeData(color: Colors.white),

//         actions: [
//           IconButton(
//             tooltip: "View Reports",
//             icon: const Icon(Icons.analytics, color: Colors.white),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => OwnerReportsPage(
//                     assignedTargets: assignedTargets,
//                     activityLogs: activityLogs,
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),

//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // -------- ANNOUNCEMENT --------
//             _sectionCard(
//               title: "Company Announcement",
//               subtitle: "Broadcast message to all departments",
//               child: Column(
//                 children: [
//                   TextField(
//                     controller: _announcementController,
//                     maxLines: 3,
//                     decoration: const InputDecoration(
//                       hintText: "Enter announcement message...",
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: ElevatedButton.icon(
//                       icon: const Icon(Icons.send, color: Colors.white),
//                       label: const Text(
//                         "Send",
//                         style: TextStyle(color: AppColors.softGreyBg),
//                       ),
//                       onPressed: sendAnnouncement,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primaryBlue,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // -------- TARGET ASSIGNMENT --------
//             _sectionCard(
//               title: "Assign Monthly Target",
//               subtitle: "Set revenue & order goals",
//               child: Column(
//                 children: [
//                   _dropdown(
//                     "Select Branch",
//                     branches,
//                     (v) => setState(() => selectedBranch = v),
//                     value: selectedBranch,
//                   ),
//                   const SizedBox(height: 10),
//                   _dropdown(
//                     "Marketing Manager",
//                     marketingManagers,
//                     (v) => setState(() => selectedManager = v),
//                     value: selectedManager,
//                   ),
//                   const SizedBox(height: 10),
//                   _input("Revenue Target (₹)", _revenueTargetController),
//                   const SizedBox(height: 10),
//                   _input("Order Target (Qty)", _orderTargetController),
//                   const SizedBox(height: 10),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           selectedMonth == null
//                               ? "No month selected"
//                               : DateFormat('MMMM yyyy')
//                                   .format(selectedMonth!),
//                         ),
//                       ),
//                       OutlinedButton(
//                         onPressed: pickMonth,
//                         child: const Text(
//                           "Select Month",
//                           style:
//                               TextStyle(color: AppColors.primaryBlue),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   _input(
//                     "Remarks (Optional)",
//                     _remarksController,
//                     maxLines: 2,
//                   ),
//                   const SizedBox(height: 14),
//                   ElevatedButton(
//                     onPressed: assignMonthlyTarget,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.primaryBlue,
//                       minimumSize: const Size.fromHeight(45),
//                     ),
//                     child: const Text(
//                       "Assign Target",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ---------------- UI HELPERS ----------------
//   Widget _sectionCard({
//     required String title,
//     required String subtitle,
//     required Widget child,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 18),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.cardBg,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             blurRadius: 6,
//             color: AppColors.shadowGrey,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style:
//                 const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             subtitle,
//             style: const TextStyle(color: Colors.grey, fontSize: 13),
//           ),
//           const SizedBox(height: 14),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget _input(String label, TextEditingController c,
//       {int maxLines = 1}) {
//     return TextField(
//       controller: c,
//       maxLines: maxLines,
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//       ),
//     );
//   }

//   Widget _dropdown(
//     String label,
//     List<String> items,
//     ValueChanged<String?> onChanged, {
//     String? value,
//   }) {
//     return DropdownButtonFormField<String>(
//       value: value,
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//       ),
//       items: items
//           .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//           .toList(),
//       onChanged: onChanged,
//     );
//   }
// }
