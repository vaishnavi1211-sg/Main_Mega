import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProRawMaterialEntryPage extends StatefulWidget {
  const ProRawMaterialEntryPage({super.key});

  @override
  State<ProRawMaterialEntryPage> createState() => _ProRawMaterialEntryPageState();
}

class _ProRawMaterialEntryPageState extends State<ProRawMaterialEntryPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _rawMaterials = [];
  List<MaterialSelection> _selectedMaterials = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  
  // Form fields
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  double _totalCost = 0.0;
  
  @override
  void initState() {
    super.initState();
    _fetchRawMaterials();
    _batchController.text = "BATCH-${DateFormat('yyMMddHHmm').format(DateTime.now())}";
  }
  
  Future<void> _fetchRawMaterials() async {
    try {
      setState(() => _isLoading = true);
      
      final response = await _supabase
          .from('pro_inventory')
          .select('id, name, stock, unit, price_per_unit')
          .order('name');
      
      setState(() {
        _rawMaterials = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error fetching raw materials: $e');
      _showErrorSnackBar('Failed to load raw materials');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _addMaterial(String materialId) {
    final material = _rawMaterials.firstWhere(
      (m) => m['id'].toString() == materialId,
      orElse: () => {},
    );
    
    if (material.isNotEmpty && !_selectedMaterials.any((m) => m.id == materialId)) {
      setState(() {
        _selectedMaterials.add(MaterialSelection(
          id: materialId,
          name: material['name'] ?? 'Unknown',
          unit: material['unit'] ?? 'kg',
          pricePerUnit: (material['price_per_unit'] ?? 0).toDouble(),
          availableStock: (material['stock'] ?? 0).toDouble(),
        ));
      });
      _calculateTotalCost();
    }
  }
  
  void _removeMaterial(String materialId) {
    setState(() {
      _selectedMaterials.removeWhere((m) => m.id == materialId);
    });
    _calculateTotalCost();
  }
  
  void _updateMaterialQuantity(String materialId, String quantity) {
    final qty = double.tryParse(quantity) ?? 0;
    setState(() {
      final index = _selectedMaterials.indexWhere((m) => m.id == materialId);
      if (index != -1) {
        _selectedMaterials[index] = _selectedMaterials[index].copyWith(quantity: qty);
      }
    });
    _calculateTotalCost();
  }
  
  void _calculateTotalCost() {
    double total = 0.0;
    for (var material in _selectedMaterials) {
      total += (material.pricePerUnit * material.quantity);
    }
    setState(() => _totalCost = total);
  }
  
  Future<void> _submitForm() async {
    // Scroll to top to show any validation errors
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fix the errors in the form');
      return;
    }
    
    if (_selectedMaterials.isEmpty) {
      _showErrorSnackBar('Please select at least one raw material');
      return;
    }
    
    // Validate all selected materials
    for (var material in _selectedMaterials) {
      if (material.quantity <= 0) {
        _showErrorSnackBar('Please enter valid quantity for ${material.name}');
        return;
      }
      
      if (material.quantity > material.availableStock) {
        _showErrorSnackBar('Insufficient stock for ${material.name}! Available: ${material.availableStock} ${material.unit}');
        return;
      }
    }
    
    try {
      setState(() => _isSubmitting = true);
      
      // Process each selected material
      for (var material in _selectedMaterials) {
        final totalCost = material.pricePerUnit * material.quantity;
        
        // 1. Insert raw material usage record
        await _supabase.from('pro_raw_material_usage').insert({
          'raw_material_id': material.id,
          'quantity_used': material.quantity,
          'total_cost': totalCost,
          'usage_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'batch_number': _batchController.text.trim().isNotEmpty ? _batchController.text.trim() : null,
          'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          'created_at': DateTime.now().toIso8601String(),
        });
        
        // 2. Update inventory stock (reduce stock)
        final newStock = material.availableStock - material.quantity;
        await _supabase
            .from('pro_inventory')
            .update({'stock': newStock})
            .eq('id', material.id);
      }
      
      // 3. Show success message
      _showSuccessSnackBar('✓ ${_selectedMaterials.length} raw material(s) usage recorded successfully!\nTotal Cost: ₹${_totalCost.toStringAsFixed(2)}');
      
      // 4. Reset form after delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _resetForm();
      });
      
    } catch (e) {
      debugPrint('Error submitting form: $e');
      _showErrorSnackBar('Failed to save data: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
  
  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedMaterials.clear();
      _batchController.text = "BATCH-${DateFormat('yyMMddHHmm').format(DateTime.now())}";
      _notesController.clear();
      _selectedDate = DateTime.now();
      _totalCost = 0.0;
    });
    _fetchRawMaterials(); // Refresh stock data
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: GlobalColors.primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: GlobalColors.primaryBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Record Raw Material Usage',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: GlobalColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRawMaterials,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: GlobalColors.primaryBlue),
                  SizedBox(height: 16),
                  Text(
                    'Loading materials...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  // Step Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStep(1, 'Select Material(s)', _selectedMaterials.isNotEmpty),
                        Container(
                          height: 1,
                          width: 30,
                          color: Colors.grey[300],
                        ),
                        _buildStep(2, 'Enter Details', _selectedMaterials.isNotEmpty),
                        Container(
                          height: 1,
                          width: 30,
                          color: Colors.grey[300],
                        ),
                        _buildStep(3, 'Confirm', _selectedMaterials.isNotEmpty && _selectedMaterials.every((m) => m.quantity > 0)),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          
                          // Date Selection
                          _buildCard(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: GlobalColors.primaryBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.calendar_today,
                                        color: GlobalColors.primaryBlue,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Usage Date',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('dd MMM yyyy').format(_selectedDate),
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey[500],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Raw Material Selection
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Select Raw Material(s)', isRequired: true),
                              const SizedBox(height: 8),
                              if (_rawMaterials.isEmpty)
                                _buildEmptyState(
                                  icon: Icons.inventory_outlined,
                                  message: 'No raw materials found',
                                  actionText: 'Refresh',
                                  onAction: _fetchRawMaterials,
                                )
                              else
                                _buildCard(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Column(
                                      children: [
                                        // Material selection dropdown with constrained height
                                        Container(
                                          height: 56,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[300]!),
                                          ),
                                          child: PopupMenuButton<String>(
                                            onSelected: (value) {
                                              _addMaterial(value);
                                            },
                                            itemBuilder: (BuildContext context) {
                                              final availableMaterials = _rawMaterials.where((material) {
                                                return !_selectedMaterials.any((m) => m.id == material['id'].toString());
                                              }).toList();
                                              
                                              return availableMaterials.map((material) {
                                                final currentStock = (material['stock'] ?? 0).toDouble();
                                                final unit = material['unit'] ?? 'kg';
                                                final price = (material['price_per_unit'] ?? 0).toDouble();
                                                final isLowStock = currentStock < 100;
                                                
                                                return PopupMenuItem<String>(
                                                  value: material['id'].toString(),
                                                  height: 48,
                                                  child: SizedBox(
                                                    width: 300,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                material['name'] ?? 'Unknown',
                                                                style: GoogleFonts.poppins(
                                                                  fontWeight: FontWeight.w500,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            ),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: isLowStock
                                                                    ? Colors.orange.withOpacity(0.1)
                                                                    : Colors.green.withOpacity(0.1),
                                                                borderRadius: BorderRadius.circular(4),
                                                              ),
                                                              child: Text(
                                                                '${currentStock.toStringAsFixed(0)} $unit',
                                                                style: GoogleFonts.poppins(
                                                                  fontSize: 11,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: isLowStock ? Colors.orange : Colors.green,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          'Price: ₹${price.toStringAsFixed(2)}/$unit',
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 11,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }).toList();
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.add, color: GlobalColors.primaryBlue, size: 20),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        'Add Raw Material',
                                                        style: GoogleFonts.poppins(
                                                          color: Colors.grey[600],
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Icon(Icons.arrow_drop_down, color: GlobalColors.primaryBlue),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        
                                        // Selected materials list
                                        if (_selectedMaterials.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          Divider(color: Colors.grey[300]),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Selected Materials (${_selectedMaterials.length})',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ..._selectedMaterials.map((material) {
                                            return _buildSelectedMaterialCard(material);
                                          }).toList(),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Total Cost Display
                          if (_totalCost > 0) ...[
                            _buildCard(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Cost',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${_totalCost.toStringAsFixed(2)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: GlobalColors.primaryBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calculate,
                                            size: 16,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Auto Calculated',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          // Batch Number
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Batch Number'),
                              const SizedBox(height: 8),
                              _buildCard(
                                child: TextFormField(
                                  controller: _batchController,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Auto-generated batch number',
                                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                                    prefixIcon: Icon(
                                      Icons.qr_code_scanner,
                                      color: GlobalColors.primaryBlue,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Notes (Optional)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Notes', isOptional: true),
                              const SizedBox(height: 8),
                              _buildCard(
                                child: TextFormField(
                                  controller: _notesController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Add any notes or remarks...',
                                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                                    alignLabelWithHint: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Information Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: GlobalColors.primaryBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: GlobalColors.primaryBlue.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: GlobalColors.primaryBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'How this helps',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: GlobalColors.primaryBlue,
                                        fontSize: 14,
                                    ),
                                  ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '• Automatically updates inventory stock\n'
                                  '• Tracks raw material costs for profit calculation\n'
                                  '• Supports multiple material selection\n'
                                  '• Calculates total cost automatically\n'
                                  '• Essential for accurate profit reporting',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Action Buttons (now at end of scrollable content)
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting || _isLoading ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: GlobalColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isSubmitting
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Recording...',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.check_circle_outline, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Record Material Usage',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: _resetForm,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey[600],
                                    side: BorderSide(color: Colors.grey[400]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.clear, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Clear Form',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 40), // Extra padding at bottom
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSelectedMaterialCard(MaterialSelection material) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
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
                      material.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Price: ₹${material.pricePerUnit.toStringAsFixed(2)}/${material.unit}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                onPressed: () => _removeMaterial(material.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: material.quantity > 0 ? material.quantity.toString() : '',
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    labelStyle: GoogleFonts.poppins(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixText: material.unit,
                    suffixStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateMaterialQuantity(material.id, value),
                  validator: (value) {
                    final qty = double.tryParse(value ?? '') ?? 0;
                    if (qty <= 0) return 'Enter valid quantity';
                    if (qty > material.availableStock) {
                      return 'Max: ${material.availableStock}';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Stock: ${material.availableStock.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          if (material.quantity > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Cost: ',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '₹${(material.pricePerUnit * material.quantity).toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
  
  Widget _buildSectionTitle(String title, {bool isRequired = false, bool isOptional = false}) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        ],
        if (isOptional) ...[
          const SizedBox(width: 4),
          Text(
            '(Optional)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(actionText),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStep(int number, String title, bool isActive) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? GlobalColors.primaryBlue : Colors.grey[300],
            shape: BoxShape.circle,
            boxShadow: isActive ? [
              BoxShadow(
                color: GlobalColors.primaryBlue.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? GlobalColors.primaryBlue : Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _batchController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class MaterialSelection {
  final String id;
  final String name;
  final String unit;
  final double pricePerUnit;
  final double availableStock;
  double quantity;

  MaterialSelection({
    required this.id,
    required this.name,
    required this.unit,
    required this.pricePerUnit,
    required this.availableStock,
    this.quantity = 0.0,
  });

  MaterialSelection copyWith({
    double? quantity,
  }) {
    return MaterialSelection(
      id: id,
      name: name,
      unit: unit,
      pricePerUnit: pricePerUnit,
      availableStock: availableStock,
      quantity: quantity ?? this.quantity,
    );
  }
}