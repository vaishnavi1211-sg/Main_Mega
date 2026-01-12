import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Product data with prices
  final Map<String, Map<String, dynamic>> _products = {
    "मिल्क पॉवर / Milk Power": {"weight": 20, "unit": "kg", "price": 350},
    "दुध सरिता / Dugdh Sarita": {"weight": 25, "unit": "kg", "price": 450},
    "दुग्धराज / Dugdh Raj": {"weight": 30, "unit": "kg", "price": 600},
    "डायमंड संतुलित पशु आहार / Diamond Balanced Animal Feed": {"weight": 10, "unit": "kg", "price": 800},
    "मिल्क पॉवर प्लस / Milk Power Plus": {"weight": 5, "unit": "kg", "price": 1200},
    "संतुलित पशु आहार / Santulit Pashu Aahar": {"weight": 5, "unit": "kg", "price": 1200},
    "जीवन धारा / Jeevan Dhara": {"weight": 5, "unit": "kg", "price": 1200},
    "Dairy Special संतुलित पशु आहार": {"weight": 5, "unit": "kg", "price": 1200},
  };

  // State variables
  String? _selectedDistrict;
  DateTime _selectedMonth = DateTime.now();
  List<String> _selectedManagers = [];
  List<MarketingManager> _allManagers = [];
  List<Map<String, dynamic>> _recentTargets = [];
  
  // Target calculation variables
  double _averagePricePerKg = 0;
  bool _showValidationError = false;
  String _validationMessage = '';
  String _validationDetails = '';

  // Controllers
  final TextEditingController _revenueController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _isLoading = false;
  bool _isAssigning = false;
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _calculateAveragePrice();
  }

  void _calculateAveragePrice() {
    double totalPrice = 0;
    double totalWeight = 0;
    
    _products.forEach((name, data) {
      totalPrice += (data['price'] as int).toDouble();
      totalWeight += (data['weight'] as int).toDouble();
    });
    
    if (totalWeight > 0) {
      _averagePricePerKg = totalPrice / totalWeight;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _allManagers = await _targetService.getMarketingManagers();
      _loadRecentTargets();
      setState(() {});
    } catch (e) {
      _showSnackBar('Failed to load data: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecentTargets() async {
    setState(() => _loadingHistory = true);
    try {
      _recentTargets = await _targetService.getRecentTargets(limit: 10);
    } catch (e) {
      print('Error loading recent targets: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingHistory = false);
      }
    }
  }

  // Get unique districts from managers
  List<String> get _availableDistricts {
    try {
      final Set<String> districts = {};
      
      for (final manager in _allManagers) {
        if (manager.district != null && 
            manager.district!.isNotEmpty && 
            manager.district!.trim().toLowerCase() != 'null') {
          districts.add(manager.district!.trim());
        }
      }
      
      final List<String> districtList = districts.toList()..sort();
      
      if (districtList.isEmpty) {
        return _getFallbackDistricts();
      }
      
      return ['All Districts', ...districtList];
    } catch (e) {
      return _getFallbackDistricts();
    }
  }

  List<String> _getFallbackDistricts() {
    final fallbackDistricts = [
      "Ahmednagar", "Akola", "Amravati", "Aurangabad", "Beed",
      "Bhandara", "Buldhana", "Chandrapur", "Dhule", "Gadchiroli",
      "Gondiya", "Hingoli", "Jalgaon", "Jalna", "Kolhapur",
      "Latur", "Mumbai City", "Mumbai Suburban", "Nagpur", "Nanded",
      "Nandurbar", "Nashik", "Osmanabad", "Palghar", "Parbhani",
      "Pune", "Raigad", "Ratnagiri", "Sangli", "Satara",
      "Sindhudurg", "Solapur", "Thane", "Wardha", "Washim", "Yavatmal"
    ]..sort();
    
    return ['All Districts', ...fallbackDistricts];
  }

  List<MarketingManager> get _filteredManagers {
    if (_selectedDistrict == null || _selectedDistrict == 'All Districts') {
      return _allManagers;
    }
    
    return _allManagers
        .where((m) => m.district == _selectedDistrict)
        .toList();
  }

  void _validateTargets() {
    final revenueText = _revenueController.text.trim();
    final ordersText = _orderController.text.trim();
    
    setState(() {
      _showValidationError = false;
      _validationMessage = '';
      _validationDetails = '';
    });
    
    if (revenueText.isEmpty || ordersText.isEmpty) return;
    
    final revenue = int.tryParse(revenueText) ?? 0;
    final orders = int.tryParse(ordersText) ?? 0;
    
    if (revenue == 0 || orders == 0) return;
    
    final avgOrderValue = revenue / orders;
    final avgOrderWeight = avgOrderValue / _averagePricePerKg;
    
    final List<String> errors = [];
    final List<String> details = [];
    
    if (avgOrderWeight < 5) {
      errors.add('Average order too small');
      details.add('Each order should be at least 5kg\nCurrent: ${avgOrderWeight.toStringAsFixed(1)}kg per order');
    }
    
    if (avgOrderWeight > 1000) {
      errors.add('Average order too large');
      details.add('Each order should not exceed 1000kg\nCurrent: ${avgOrderWeight.toStringAsFixed(1)}kg per order');
    }
    
    if (avgOrderValue < 350) {
      errors.add('Order value too low');
      details.add('Minimum product price: ₹350\nCurrent: ₹${avgOrderValue.toStringAsFixed(0)} per order');
    }
    
    if (errors.isNotEmpty) {
      setState(() {
        _showValidationError = true;
        _validationMessage = errors.join(', ');
        _validationDetails = details.join('\n\n');
      });
    }
  }

  Future<void> _assignTargets() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fix the validation errors', isError: true);
      return;
    }
    
    if (_selectedManagers.isEmpty) {
      _showSnackBar('Please select at least one manager', isError: true);
      return;
    }
    
    if (_selectedDistrict == null) {
      _showSnackBar('Please select a district', isError: true);
      return;
    }
    
    _validateTargets();
    if (_showValidationError) {
      _showSnackBar('Please fix the target validation errors', isError: true);
      return;
    }

    setState(() => _isAssigning = true);

    try {
      print('=== STARTING TARGET ASSIGNMENT ===');
      print('Selected Managers: ${_selectedManagers.length}');
      print('Selected District: $_selectedDistrict');
      
      String targetDistrict = _selectedDistrict!;
      if (targetDistrict == 'All Districts') {
        targetDistrict = 'All';
      }

      final success = await _targetService.assignTargets(
        managerIds: _selectedManagers,
        district: targetDistrict,
        targetMonth: _selectedMonth,
        revenueTarget: int.parse(_revenueController.text),
        orderTarget: int.parse(_orderController.text),
        remarks: _remarksController.text.isNotEmpty ? _remarksController.text : null,
        branch: '',
      );

      if (success) {
        print('✅ Target assignment SUCCESSFUL');
        _showSnackBar('✅ Targets assigned successfully!', isError: false);
        
        await Future.delayed(const Duration(milliseconds: 1500));
        
        _resetForm();
        _loadRecentTargets();
      } else {
        print('❌ Target assignment FAILED');
        _showSnackBar('❌ Failed to assign targets. Please try again.', isError: true);
      }
    } catch (e, stackTrace) {
      print('=== TARGET ASSIGNMENT ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      _showSnackBar('❌ Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isAssigning = false);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedDistrict = null;
      _selectedManagers.clear();
      _showValidationError = false;
    });
    _revenueController.clear();
    _orderController.clear();
    _remarksController.clear();
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

  void _showTargetsHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Targets History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              if (_loadingHistory)
                const Center(child: CircularProgressIndicator())
              else if (_recentTargets.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No targets assigned yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _recentTargets.length,
                    itemBuilder: (context, index) {
                      final target = _recentTargets[index];
                      final revenue = target['revenue_target'] ?? 0;
                      final achievedRevenue = target['achieved_revenue'] ?? 0;
                      final orders = target['order_target'] ?? 0;
                      final achievedOrders = target['achieved_orders'] ?? 0;
                      final progress = revenue > 0 ? (achievedRevenue / revenue) * 100 : 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        target['manager_name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (target['manager_emp_id']?.isNotEmpty == true)
                                        Text(
                                          'ID: ${target['manager_emp_id']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getDistrictColor(target['district'] ?? ''),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    target['district'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Month: ${DateFormat('MMM yyyy').format(DateTime.parse(target['target_month']))}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Revenue Progress
                            _buildProgressRow(
                              label: 'Revenue',
                              current: achievedRevenue,
                              target: revenue,
                              prefix: '₹',
                            ),
                            const SizedBox(height: 8),
                            // Orders Progress
                            _buildProgressRow(
                              label: 'Orders',
                              current: achievedOrders,
                              target: orders,
                              prefix: '#',
                            ),
                            const SizedBox(height: 8),
                            // Overall Progress
                            LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getProgressColor(progress),
                              ),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${progress.toStringAsFixed(1)}% Complete',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM, hh:mm a').format(DateTime.parse(target['assigned_at'])),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressRow({
    required String label,
    required int current,
    required int target,
    required String prefix,
  }) {
    final percentage = target > 0 ? (current / target) * 100 : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              '$prefix${NumberFormat().format(current)} / $prefix${NumberFormat().format(target)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: percentage >= 100 ? Colors.green : Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage >= 100 ? Colors.green : Colors.blue,
          ),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 100) return Colors.green;
    if (percentage >= 75) return Colors.greenAccent;
    if (percentage >= 50) return Colors.orange;
    if (percentage >= 25) return Colors.amber;
    return Colors.red;
  }

  Color _getDistrictColor(String district) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.brown,
    ];
    final index = district.hashCode % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: GlobalColors.primaryBlue,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Assign Monthly Targets",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 18),
          ),
        ],
      ),
      //centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            onPressed: () => _showTargetsHistory(context),
            tooltip: 'View Targets History',
          ),
        ],
      
      ),   


      
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                onChanged: _validateTargets,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    _buildInfoCard(),

                    const SizedBox(height: 24),

                    // District Selection
                    _buildSectionHeader('Select District'),
                    const SizedBox(height: 8),
                    _buildDistrictSelection(),

                    // District Info
                    if (_selectedDistrict != null && _selectedDistrict != 'All Districts')
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.blue[700],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_filteredManagers.length} managers available in $_selectedDistrict',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Target Month
                    _buildSectionHeader('Target Month'),
                    const SizedBox(height: 8),
                    _buildMonthSelector(),

                    const SizedBox(height: 24),

                    // Select Managers
                    _buildSectionHeader('Select Managers'),
                    const SizedBox(height: 8),
                    _buildManagersSelection(),

                    const SizedBox(height: 24),

                    // Targets Input
                    _buildSectionHeader('Set Targets'),
                    const SizedBox(height: 12),
                    _buildTargetsInput(),

                    // Auto-calculated values
                    if (_revenueController.text.isNotEmpty && _orderController.text.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Average per order:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '₹${(_revenueController.text.isNotEmpty && _orderController.text.isNotEmpty) ? (int.parse(_revenueController.text) / int.parse(_orderController.text)).toStringAsFixed(0) : '0'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Average weight:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${(_revenueController.text.isNotEmpty && _orderController.text.isNotEmpty) ? ((int.parse(_revenueController.text) / int.parse(_orderController.text)) / _averagePricePerKg).toStringAsFixed(1) : '0'}kg',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Validation Error
                    if (_showValidationError) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _validationMessage,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _validationDetails,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Remarks
                    _buildSectionHeader('Remarks (Optional)'),
                    const SizedBox(height: 8),
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

  Widget _buildInfoCard() {
    final minPrice = _products.values
        .map((p) => p['price'] as int)
        .reduce((a, b) => a < b ? a : b);
    final maxPrice = _products.values
        .map((p) => p['price'] as int)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.blue[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Information',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                    children: [
                      TextSpan(
                        text: '${_products.length} products | ',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: '₹$minPrice - ₹$maxPrice',
                        style: TextStyle(color: Colors.blue[600]),
                      ),
                      const TextSpan(text: ' price range'),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                    children: [
                      const TextSpan(text: 'Avg: '),
                      TextSpan(
                        text: '₹${_averagePricePerKg.toStringAsFixed(0)}/kg',
                        style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.w500),
                      ),
                      const TextSpan(text: ' | Orders: '),
                      TextSpan(
                        text: '5-1000kg',
                        style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDistrictSelection() {
    final districts = _availableDistricts;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1.5,
        ),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDistrict,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.blue,
            size: 24,
          ),
          iconSize: 24,
          elevation: 0,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          hint: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              "Select District",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
          underline: const SizedBox(),
          items: districts.map((district) {
            final isAllDistricts = district == 'All Districts';
            final managerCount = district == 'All Districts' 
                ? _allManagers.length 
                : _allManagers.where((m) => m.district == district).length;
            
            return DropdownMenuItem<String>(
              value: district,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (isAllDistricts)
                      Icon(
                        Icons.all_inclusive,
                        color: Colors.blue,
                        size: 18,
                      )
                    else
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        district,
                        style: TextStyle(
                          fontSize: 15,
                          color: isAllDistricts ? Colors.blue : Colors.black87,
                          fontWeight: isAllDistricts ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$managerCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedDistrict = value;
                _selectedManagers.clear();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return GestureDetector(
      onTap: () => _selectMonth(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              color: Colors.blue,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    DateFormat('MM/yyyy').format(_selectedMonth),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[600],
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
    if (_selectedDistrict == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Colors.grey[400],
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Select a district to view managers',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredManagers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _selectedDistrict == 'All Districts'
                    ? Icons.group_outlined
                    : Icons.group_off_outlined,
                color: Colors.grey[400],
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _selectedDistrict == 'All Districts'
                    ? 'No marketing managers found'
                    : 'No marketing managers found for $_selectedDistrict',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Checkbox(
                  value: _selectedManagers.length == _filteredManagers.length &&
                      _filteredManagers.isNotEmpty,
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
                  activeColor: Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select All (${_filteredManagers.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Selected: ${_selectedManagers.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          SizedBox(
            height: 220,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _filteredManagers.length,
              itemBuilder: (context, index) {
                final manager = _filteredManagers[index];
                final isSelected = _selectedManagers.contains(manager.id);

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: isSelected ? Colors.blue : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    manager.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.blue : Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manager.position ?? 'No position',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (manager.empId.isNotEmpty)
                        Text(
                          'ID: ${manager.empId}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      if (manager.district != null && manager.district!.isNotEmpty && _selectedDistrict != 'All Districts')
                        Text(
                          manager.district!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
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
                    activeColor: Colors.blue,
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
    return Column(
      children: [
        _buildTargetField(
          controller: _revenueController,
          label: 'Revenue Target (₹)',
          hint: 'Enter total revenue amount',
          icon: Icons.currency_rupee_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Revenue target is required';
            }
            final revenue = int.tryParse(value);
            if (revenue == null) {
              return 'Enter a valid number';
            }
            if (revenue <= 0) {
              return 'Revenue must be greater than 0';
            }
            if (revenue > 10000000) {
              return 'Revenue too high (max: 10,000,000)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTargetField(
          controller: _orderController,
          label: 'Order Target (Count)',
          hint: 'Enter number of orders',
          icon: Icons.shopping_cart_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Order target is required';
            }
            final orders = int.tryParse(value);
            if (orders == null) {
              return 'Enter a valid number';
            }
            if (orders <= 0) {
              return 'Orders must be greater than 0';
            }
            if (orders > 10000) {
              return 'Orders too high (max: 10,000)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTargetField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (value) => _validateTargets(),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: Colors.blue.withOpacity(0.7),
              size: 22,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.blue,
                width: 2,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
        hintStyle: const TextStyle(fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.blue,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _resetForm,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.white,
            ),
            child: const Text(
              'Reset',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isAssigning ? null : _assignTargets,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
              shadowColor: Colors.blue.withOpacity(0.3),
            ),
            child: _isAssigning
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        _selectedDistrict == 'All Districts'
                            ? 'Assign to All'
                            : 'Assign Target',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
