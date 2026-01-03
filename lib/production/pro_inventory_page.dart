import 'package:flutter/material.dart';
import 'package:mega_pro/providers/pro_inventory_provider.dart';
import 'package:provider/provider.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:google_fonts/google_fonts.dart';

class ProInventoryManager extends StatefulWidget {
  const ProInventoryManager({super.key});

  @override
  State<ProInventoryManager> createState() => _ProInventoryManagerState();
}

class _ProInventoryManagerState extends State<ProInventoryManager> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showMarathi = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final inventoryItems = _searchQuery.isEmpty
        ? inventoryProvider.activeItems
        : inventoryProvider.searchProducts(_searchQuery);

    // Calculate totals
    final totalBags = inventoryItems.fold(0.0, (sum, item) => sum + item.bags);
    final totalTons = inventoryItems.fold(0.0, (sum, item) => sum + item.tons);
    final totalValue = inventoryItems.fold(0.0, (sum, item) => sum + item.totalValue);

    return Scaffold(
      backgroundColor: GlobalColors.background,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        elevation: 0,
        title: Text(
          "Inventory Manager",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search and Stats Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: GlobalColors.primaryBlue),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: GlobalColors.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${inventoryItems.length}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Items',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    title: 'Total Bags',
                    value: totalBags.toStringAsFixed(0),
                    icon: Icons.inventory,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _summaryCard(
                    title: 'Total Tons',
                    value: totalTons.toStringAsFixed(2),
                    icon: Icons.scale,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _summaryCard(
                    title: 'Total Value',
                    value: '₹${totalValue.toStringAsFixed(0)}',
                    icon: Icons.currency_rupee, 
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Language Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Language:',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      _languageChip(
                        'English',
                        isSelected: !_showMarathi,
                        onTap: () => setState(() => _showMarathi = false),
                      ),
                      const SizedBox(width: 8),
                      _languageChip(
                        'मराठी',
                        isSelected: _showMarathi,
                        onTap: () => setState(() => _showMarathi = true),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Inventory List Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Products Inventory',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: GlobalColors.primaryBlue),
                    onPressed: () => inventoryProvider.refresh(),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Inventory List
            Expanded(
              child: inventoryProvider.isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: GlobalColors.primaryBlue),
                          const SizedBox(height: 16),
                          Text(
                            'Loading inventory...',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : inventoryItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No products in inventory'
                                    : 'No products found',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Tap + to add your first product'
                                    : 'Try a different search term',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: inventoryItems.length,
                          itemBuilder: (context, index) {
                            final item = inventoryItems[index];
                            return _inventoryItemCard(item, context);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddProductScreen(),
          ),
        ),
        backgroundColor: GlobalColors.primaryBlue,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _summaryCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 12, color: color),
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageChip(String text, {required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? GlobalColors.primaryBlue : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? GlobalColors.primaryBlue : Colors.grey[300]!,
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _inventoryItemCard(InventoryItem item, BuildContext context) {
    final displayName = _showMarathi
        ? (item.nameHindi ?? item.name)
        : item.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showProductDetails(item, context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: GlobalColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: GlobalColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Stock Summary
                Row(
                  children: [
                    _infoChip('${item.bags.toStringAsFixed(0)} Bags',
                        icon: Icons.inventory, color: Colors.blue[100]),
                    const SizedBox(width: 8),
                    _infoChip('${item.tons.toStringAsFixed(2)} Tons',
                        icon: Icons.scale, color: Colors.green[100]),
                  ],
                ),

                const SizedBox(height: 12),

                // Product Details
                Row(
                  children: [
                    _infoChip('${item.weightPerBag} kg/bag',
                        icon: Icons.scale, color: Colors.orange[100]),
                    const SizedBox(width: 8),
                    _infoChip('₹${item.pricePerBag}/bag',
                        icon: Icons.currency_rupee, color: Colors.purple[100]),
                    // const SizedBox(width: 8),
                    // _infoChip('₹${item.pricePerTon}/ton',
                    //     icon: Icons.currency_rupee, color: Colors.red[100]),
                  ],
                ),

                const SizedBox(height: 12),

                // Stock Status and Actions
                Row(
                  children: [
                    // Stock Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: item.isLowStock
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.isLowStock ? Icons.warning : Icons.check_circle,
                            size: 14,
                            color: item.isLowStock ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.isLowStock ? 'Low Stock' : 'In Stock',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: item.isLowStock ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Action Buttons
                    _actionButton(
                      icon: Icons.edit,
                      color: GlobalColors.primaryBlue,
                      onTap: () => _showUpdateDialog(item, context),
                      tooltip: 'Edit',
                    ),
                    const SizedBox(width: 8),
                    _actionButton(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      onTap: () => _showDeleteDialog(item, context),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String text, {IconData? icon, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.grey[700]),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: color,
        ),
      ),
    );
  }

  void _showProductDetails(InventoryItem item, BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ProductDetailsSheet(item: item, showMarathi: _showMarathi);
      },
    );
  }

  void _showUpdateDialog(InventoryItem item, BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return UpdateProductSheet(item: item);
      },
    );
  }

  void _showDeleteDialog(InventoryItem item, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Product',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete "${item.name}"?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final inventoryProvider = Provider.of<InventoryProvider>(
                  context,
                  listen: false,
                );
                try {
                  await inventoryProvider.deleteProduct(item.id);
                  if (context.mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${item.name}" deleted successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                } catch (e) {
                  if (context.mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Product Details Bottom Sheet
class ProductDetailsSheet extends StatelessWidget {
  final InventoryItem item;
  final bool showMarathi;

  const ProductDetailsSheet({
    super.key,
    required this.item,
    required this.showMarathi,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = showMarathi ? (item.nameHindi ?? item.name) : item.name;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: GlobalColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: GlobalColors.primaryBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      item.category,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Stock Summary
          _sectionHeader('Stock Summary'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _detailCard('Total Bags', '${item.bags.toStringAsFixed(0)}', Icons.inventory, Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _detailCard('Total Tons', '${item.tons.toStringAsFixed(2)}', Icons.scale, Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _detailCard('Total Value', '₹${item.totalValue.toStringAsFixed(0)}', Icons.currency_rupee, Colors.orange),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Product Details
          _sectionHeader('Product Details'),
          const SizedBox(height: 12),
          _detailRow('Weight per Bag', '${item.weightPerBag} kg', Icons.scale),
          _detailRow('Price per Bag', '₹${item.pricePerBag}', Icons.currency_rupee),
          _detailRow('Price per Ton', '₹${item.pricePerTon}', Icons.currency_rupee),
          _detailRow('Bags in Stock', '${item.bags.toStringAsFixed(0)}', Icons.inventory),
          _detailRow('Min Bags Stock', '${item.minBagsStock.toStringAsFixed(0)}', Icons.warning),
          
          if (item.description != null && item.description!.isNotEmpty)
            _detailRow('Description', item.description!, Icons.description),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => UpdateProductSheet(item: item),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _detailCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// Update Product Bottom Sheet
class UpdateProductSheet extends StatefulWidget {
  final InventoryItem item;

  const UpdateProductSheet({super.key, required this.item});

  @override
  State<UpdateProductSheet> createState() => _UpdateProductSheetState();
}

class _UpdateProductSheetState extends State<UpdateProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bagsController;
  late TextEditingController _pricePerBagController;
  late TextEditingController _nameController;
  late TextEditingController _nameHindiController;
  late TextEditingController _weightPerBagController;
  late TextEditingController _minBagsController;
  late TextEditingController _descriptionController;
  
  late String _selectedUnit;
  late String _selectedCategory;

  final List<String> _units = ['kg', 'ton'];
  final List<String> _categories = [
    'Animal Feed',
    'Dairy Products',
    'Veterinary',
    'Supplements',
    'Equipment',
    'Others'
  ];

  @override
  void initState() {
    super.initState();
    _bagsController = TextEditingController(text: widget.item.bags.toStringAsFixed(0));
    _pricePerBagController = TextEditingController(text: widget.item.pricePerBag.toStringAsFixed(2));
    _nameController = TextEditingController(text: widget.item.name);
    _nameHindiController = TextEditingController(text: widget.item.nameHindi ?? '');
    _weightPerBagController = TextEditingController(text: widget.item.weightPerBag.toStringAsFixed(2));
    _minBagsController = TextEditingController(text: widget.item.minBagsStock.toStringAsFixed(0));
    _descriptionController = TextEditingController(text: widget.item.description ?? '');
    
    _selectedUnit = widget.item.unit;
    _selectedCategory = widget.item.category;
  }

  @override
  void dispose() {
    _bagsController.dispose();
    _pricePerBagController.dispose();
    _nameController.dispose();
    _nameHindiController.dispose();
    _weightPerBagController.dispose();
    _minBagsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Edit ${widget.item.name}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            
            // Product Name (English)
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Product Name (English) *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Product Name (Marathi)
            TextFormField(
              controller: _nameHindiController,
              decoration: InputDecoration(
                labelText: 'Product Name (मराठी)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.translate),
              ),
            ),
            const SizedBox(height: 12),
            
            // Weight per Bag and Unit
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightPerBagController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Weight per Bag *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.scale),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter weight per bag';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter valid weight';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUnit = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Price per Bag
            TextFormField(
              controller: _pricePerBagController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price per Bag (₹) *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.currency_rupee),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter price per bag';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Stock and Min Stock
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bagsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Bags in Stock *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.inventory_2),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter bags count';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter valid bags count';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minBagsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Min Bags Stock *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.warning),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter min bags stock';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter valid min bags';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final inventoryProvider = Provider.of<InventoryProvider>(
                          context,
                          listen: false,
                        );
                        
                        final updatedItem = InventoryItem(
                          id: widget.item.id,
                          name: _nameController.text,
                          nameHindi: _nameHindiController.text.isNotEmpty
                              ? _nameHindiController.text
                              : null,
                          weightPerBag: double.parse(_weightPerBagController.text),
                          unit: _selectedUnit,
                          pricePerBag: double.parse(_pricePerBagController.text),
                          bags: double.parse(_bagsController.text),
                          minBagsStock: double.parse(_minBagsController.text),
                          category: _selectedCategory,
                          description: _descriptionController.text.isNotEmpty
                              ? _descriptionController.text
                              : null,
                          createdAt: widget.item.createdAt,
                          updatedAt: DateTime.now(),
                        );

                        try {
                          await inventoryProvider.updateProduct(widget.item.id, updatedItem);
                          if (context.mounted) Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('"${updatedItem.name}" updated successfully'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Update'),
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

// Add Product Screen
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameHindiController = TextEditingController();
  final _weightPerBagController = TextEditingController(text: '50');
  final _pricePerBagController = TextEditingController();
  final _bagsController = TextEditingController(text: '0');
  final _minBagsController = TextEditingController(text: '100');
  final _descriptionController = TextEditingController();
  
  String _selectedUnit = 'kg';
  String _selectedCategory = 'Animal Feed';

  final List<String> _units = ['kg', 'ton'];
  final List<String> _categories = [
    'Animal Feed',
    'Dairy Products',
    'Veterinary',
    'Supplements',
    'Equipment',
    'Others'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _nameHindiController.dispose();
    _weightPerBagController.dispose();
    _pricePerBagController.dispose();
    _bagsController.dispose();
    _minBagsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColors.background,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        elevation: 0,
        title: Text(
          'Add New Product',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('Product Information'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name (English) *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.label),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameHindiController,
                decoration: InputDecoration(
                  labelText: 'Product Name (मराठी)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.translate),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightPerBagController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Weight per Bag *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.scale),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'e.g., 50 kg',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Weight per bag is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter valid weight';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: InputDecoration(
                        labelText: 'Unit *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _units.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pricePerBagController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price per Bag (₹) *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.currency_rupee),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'e.g., 800',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Price per bag is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _sectionHeader('Stock Information (Bulk)'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bagsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Initial Bags',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.inventory_2),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'e.g., 100',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (int.tryParse(value) == null) {
                            return 'Enter valid bag count';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minBagsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Minimum Bags',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.warning),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'e.g., 100',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Min bags is required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Enter valid min bags';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Based on 50kg bags: ${double.tryParse(_bagsController.text) ?? 0} bags = ${((double.tryParse(_bagsController.text) ?? 0) * (double.tryParse(_weightPerBagController.text) ?? 50) / 1000).toStringAsFixed(2)} tons',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Category is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final inventoryProvider = Provider.of<InventoryProvider>(
                        context,
                        listen: false,
                      );

                      final newProduct = InventoryItem(
                        id: '',
                        name: _nameController.text,
                        nameHindi: _nameHindiController.text.isNotEmpty
                            ? _nameHindiController.text
                            : null,
                        weightPerBag: double.parse(_weightPerBagController.text),
                        unit: _selectedUnit,
                        pricePerBag: double.parse(_pricePerBagController.text),
                        bags: double.parse(_bagsController.text),
                        minBagsStock: double.parse(_minBagsController.text),
                        category: _selectedCategory,
                        description: _descriptionController.text.isNotEmpty
                            ? _descriptionController.text
                            : null,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      try {
                        await inventoryProvider.addProduct(newProduct);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('"${newProduct.name}" added successfully'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add Product',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:mega_pro/providers/pro_inventory_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:mega_pro/global/global_variables.dart';
// import 'package:google_fonts/google_fonts.dart';

// class ProInventoryManager extends StatefulWidget {
//   const ProInventoryManager({super.key});

//   @override
//   State<ProInventoryManager> createState() => _ProInventoryManagerState();
// }

// class _ProInventoryManagerState extends State<ProInventoryManager> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   bool _showMarathi = false;

//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(() {
//       setState(() {
//         _searchQuery = _searchController.text;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final inventoryProvider = Provider.of<InventoryProvider>(context);
//     final inventoryItems = _searchQuery.isEmpty
//         ? inventoryProvider.activeItems
//         : inventoryProvider.searchProducts(_searchQuery);

//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 0,
//         title: Text(
//           "Inventory Manager",
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//             fontSize: 20,
//           ),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // Search and Stats Row
//             Row(
//               children: [
//                 Expanded(
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.withOpacity(0.1),
//                           blurRadius: 10,
//                           spreadRadius: 1,
//                         ),
//                       ],
//                     ),
//                     child: TextField(
//                       controller: _searchController,
//                       decoration: InputDecoration(
//                         hintText: 'Search products...',
//                         hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
//                         prefixIcon: Icon(Icons.search, color: GlobalColors.primaryBlue),
//                         border: InputBorder.none,
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 14,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: GlobalColors.primaryBlue,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     '${inventoryItems.length}',
//                     style: GoogleFonts.poppins(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 16),

//             // Language Toggle
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.grey[200]!),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Language:',
//                     style: GoogleFonts.poppins(
//                       color: Colors.grey[700],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   Row(
//                     children: [
//                       _languageChip(
//                         'English',
//                         isSelected: !_showMarathi,
//                         onTap: () => setState(() => _showMarathi = false),
//                       ),
//                       const SizedBox(width: 8),
//                       _languageChip(
//                         'मराठी',
//                         isSelected: _showMarathi,
//                         onTap: () => setState(() => _showMarathi = true),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Inventory List Header
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 4),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Products Inventory',
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.refresh, color: GlobalColors.primaryBlue),
//                     onPressed: () => inventoryProvider.refresh(),
//                     tooltip: 'Refresh',
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 8),

//             // Inventory List
//             Expanded(
//               child: inventoryProvider.isLoading
//                   ? Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           CircularProgressIndicator(color: GlobalColors.primaryBlue),
//                           const SizedBox(height: 16),
//                           Text(
//                             'Loading inventory...',
//                             style: GoogleFonts.poppins(color: Colors.grey[600]),
//                           ),
//                         ],
//                       ),
//                     )
//                   : inventoryItems.isEmpty
//                       ? Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.inventory_2_outlined,
//                                 size: 80,
//                                 color: Colors.grey[300],
//                               ),
//                               const SizedBox(height: 16),
//                               Text(
//                                 _searchQuery.isEmpty
//                                     ? 'No products in inventory'
//                                     : 'No products found',
//                                 style: GoogleFonts.poppins(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w500,
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 _searchQuery.isEmpty
//                                     ? 'Tap + to add your first product'
//                                     : 'Try a different search term',
//                                 style: GoogleFonts.poppins(
//                                   fontSize: 14,
//                                   color: Colors.grey[500],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                       : ListView.builder(
//                           physics: const BouncingScrollPhysics(),
//                           itemCount: inventoryItems.length,
//                           itemBuilder: (context, index) {
//                             final item = inventoryItems[index];
//                             return _inventoryItemCard(item, context);
//                           },
//                         ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => const AddProductScreen(),
//           ),
//         ),
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 4,
//         child: const Icon(Icons.add, color: Colors.white, size: 28),
//       ),
//     );
//   }

//   Widget _languageChip(String text, {required bool isSelected, required VoidCallback onTap}) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: isSelected ? GlobalColors.primaryBlue : Colors.grey[100],
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: isSelected ? GlobalColors.primaryBlue : Colors.grey[300]!,
//           ),
//         ),
//         child: Text(
//           text,
//           style: GoogleFonts.poppins(
//             color: isSelected ? Colors.white : Colors.grey[700],
//             fontWeight: FontWeight.w500,
//             fontSize: 14,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _inventoryItemCard(InventoryItem item, BuildContext context) {
//     final displayName = _showMarathi
//         ? (item.nameHindi ?? item.name)
//         : item.name;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 8,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () => _showProductDetails(item, context),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Product Name
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         displayName,
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: GlobalColors.primaryBlue.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Text(
//                         item.category,
//                         style: GoogleFonts.poppins(
//                           fontSize: 12,
//                           color: GlobalColors.primaryBlue,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 12),

//                 // Product Info Row
//                 Row(
//                   children: [
//                     _infoChip('${item.weight} ${item.unit}',
//                         icon: Icons.scale, color: Colors.blue[100]),
//                     const SizedBox(width: 8),
//                     _infoChip('${item.price}',
//                         icon: Icons.currency_rupee, color: Colors.green[100]),
//                     const SizedBox(width: 8),
//                     _infoChip('${item.stock} ${item.unit}',
//                         icon: Icons.inventory_2, color: Colors.orange[100]),
//                   ],
//                 ),

//                 const SizedBox(height: 12),

//                 // Stock Status and Actions
//                 Row(
//                   children: [
//                     // Stock Status
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: item.isLowStock
//                             ? Colors.orange.withOpacity(0.1)
//                             : Colors.green.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             item.isLowStock ? Icons.warning : Icons.check_circle,
//                             size: 14,
//                             color: item.isLowStock ? Colors.orange : Colors.green,
//                           ),
//                           const SizedBox(width: 6),
//                           Text(
//                             item.isLowStock ? 'Low Stock' : 'In Stock',
//                             style: GoogleFonts.poppins(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                               color: item.isLowStock ? Colors.orange : Colors.green,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     const Spacer(),

//                     // Action Buttons
//                     _actionButton(
//                       icon: Icons.edit,
//                       color: GlobalColors.primaryBlue,
//                       onTap: () => _showUpdateDialog(item, context),
//                       tooltip: 'Edit',
//                     ),
//                     const SizedBox(width: 8),
//                     _actionButton(
//                       icon: Icons.delete_outline,
//                       color: Colors.red,
//                       onTap: () => _showDeleteDialog(item, context),
//                       tooltip: 'Delete',
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _infoChip(String text, {IconData? icon, Color? color}) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: color ?? Colors.grey[100],
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (icon != null) ...[
//             Icon(icon, size: 14, color: Colors.grey[700]),
//             const SizedBox(width: 4),
//           ],
//           Text(
//             text,
//             style: GoogleFonts.poppins(
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[700],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _actionButton({
//     required IconData icon,
//     required Color color,
//     required VoidCallback onTap,
//     required String tooltip,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20),
//       child: Container(
//         width: 36,
//         height: 36,
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           shape: BoxShape.circle,
//         ),
//         child: Icon(
//           icon,
//           size: 18,
//           color: color,
//         ),
//       ),
//     );
//   }

//   void _showProductDetails(InventoryItem item, BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return ProductDetailsSheet(item: item, showMarathi: _showMarathi);
//       },
//     );
//   }

//   void _showUpdateDialog(InventoryItem item, BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return UpdateProductSheet(item: item);
//       },
//     );
//   }

//   void _showDeleteDialog(InventoryItem item, BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           title: Text(
//             'Delete Product',
//             style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(
//                 Icons.warning_amber_rounded,
//                 size: 48,
//                 color: Colors.orange,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Are you sure you want to delete "${item.name}"?',
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: Colors.grey[700],
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 'This action cannot be undone.',
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.poppins(
//                   fontSize: 12,
//                   color: Colors.grey[500],
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text(
//                 'Cancel',
//                 style: GoogleFonts.poppins(color: Colors.grey[600]),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 final inventoryProvider = Provider.of<InventoryProvider>(
//                   context,
//                   listen: false,
//                 );
//                 try {
//                   await inventoryProvider.deleteProduct(item.id);
//                   if (context.mounted) Navigator.pop(context);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('"${item.name}" deleted successfully'),
//                       backgroundColor: Colors.green,
//                       behavior: SnackBarBehavior.floating,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   );
//                 } catch (e) {
//                   if (context.mounted) Navigator.pop(context);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Error: $e'),
//                       backgroundColor: Colors.red,
//                       behavior: SnackBarBehavior.floating,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   );
//                 }
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: Text(
//                 'Delete',
//                 style: GoogleFonts.poppins(color: Colors.white),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// // Product Details Bottom Sheet
// class ProductDetailsSheet extends StatelessWidget {
//   final InventoryItem item;
//   final bool showMarathi;

//   const ProductDetailsSheet({
//     super.key,
//     required this.item,
//     required this.showMarathi,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final displayName = showMarathi ? (item.nameHindi ?? item.name) : item.name;

//     return Container(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Center(
//             child: Container(
//               width: 60,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           Row(
//             children: [
//               Container(
//                 width: 50,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: GlobalColors.primaryBlue.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(
//                   Icons.inventory_2,
//                   color: GlobalColors.primaryBlue,
//                   size: 28,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       displayName,
//                       style: GoogleFonts.poppins(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black,
//                       ),
//                     ),
//                     Text(
//                       item.category,
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),
//           _detailRow('Weight', '${item.weight} ${item.unit}', Icons.scale),
//           _detailRow('Price', '${item.price}', Icons.currency_rupee),
//           _detailRow('Current Stock', '${item.stock} ${item.unit}', Icons.inventory_2),
//           _detailRow('Min Stock', '${item.minStock} ${item.unit}', Icons.warning),
//           if (item.description != null && item.description!.isNotEmpty)
//             _detailRow('Description', item.description!, Icons.description),
//           const SizedBox(height: 24),
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton.icon(
//                   onPressed: () => Navigator.pop(context),
//                   icon: const Icon(Icons.close),
//                   label: const Text('Close'),
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: () {
//                     Navigator.pop(context);
//                     showModalBottomSheet(
//                       context: context,
//                       isScrollControlled: true,
//                       shape: const RoundedRectangleBorder(
//                         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//                       ),
//                       builder: (context) => UpdateProductSheet(item: item),
//                     );
//                   },
//                   icon: const Icon(Icons.edit, color: Colors.white),
//                   label: const Text('Edit', style: TextStyle(fontSize: 16, color: Colors.white),),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: GlobalColors.primaryBlue,
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _detailRow(String label, String value, IconData icon) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Icon(icon, size: 20, color: Colors.grey[600]),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               label,
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ),
//           Text(
//             value,
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//               color: Colors.black,
//             ),
//           ),
//         ],
//       ),
//       );
//   }
// }

// // Update Product Bottom Sheet
// class UpdateProductSheet extends StatefulWidget {
//   final InventoryItem item;

//   const UpdateProductSheet({super.key, required this.item});

//   @override
//   State<UpdateProductSheet> createState() => _UpdateProductSheetState();
// }

// class _UpdateProductSheetState extends State<UpdateProductSheet> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _stockController;
//   late TextEditingController _priceController;
//   late TextEditingController _nameController;
//   late TextEditingController _nameHindiController;
//   late TextEditingController _weightController;
//   late TextEditingController _minStockController;
//   late TextEditingController _descriptionController;
  
//   late String _selectedUnit;
//   late String _selectedCategory;

//   final List<String> _units = ['kg', 'ton', 'pack', 'liter', 'piece'];
//   final List<String> _categories = [
//     'Animal Feed',
//     'Dairy Products',
//     'Veterinary',
//     'Supplements',
//     'Equipment',
//     'Others'
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _stockController = TextEditingController(text: widget.item.stock.toString());
//     _priceController = TextEditingController(text: widget.item.price.toString());
//     _nameController = TextEditingController(text: widget.item.name);
//     _nameHindiController = TextEditingController(text: widget.item.nameHindi ?? '');
//     _weightController = TextEditingController(text: widget.item.weight.toString());
//     _minStockController = TextEditingController(text: widget.item.minStock.toString());
//     _descriptionController = TextEditingController(text: widget.item.description ?? '');
    
//     _selectedUnit = widget.item.unit;
//     _selectedCategory = widget.item.category;
//   }

//   @override
//   void dispose() {
//     _stockController.dispose();
//     _priceController.dispose();
//     _nameController.dispose();
//     _nameHindiController.dispose();
//     _weightController.dispose();
//     _minStockController.dispose();
//     _descriptionController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       child: Form(
//         key: _formKey,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: Container(
//                 width: 60,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Edit ${widget.item.name}',
//               style: GoogleFonts.poppins(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Product Name (English)
//             TextFormField(
//               controller: _nameController,
//               decoration: InputDecoration(
//                 labelText: 'Product Name (English) *',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 prefixIcon: const Icon(Icons.label),
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter product name';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 12),
            
//             // Product Name (Marathi)
//             TextFormField(
//               controller: _nameHindiController,
//               decoration: InputDecoration(
//                 labelText: 'Product Name (मराठी)',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 prefixIcon: const Icon(Icons.translate),
//               ),
//             ),
//             const SizedBox(height: 12),
            
//             // Weight and Unit
//             Row(
//               children: [
//                 Expanded(
//                   child: TextFormField(
//                     controller: _weightController,
//                     keyboardType: TextInputType.number,
//                     decoration: InputDecoration(
//                       labelText: 'Weight *',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       prefixIcon: const Icon(Icons.scale),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter weight';
//                       }
//                       if (double.tryParse(value) == null) {
//                         return 'Please enter valid weight';
//                       }
//                       return null;
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: DropdownButtonFormField<String>(
//                     value: _selectedUnit,
//                     decoration: InputDecoration(
//                       labelText: 'Unit *',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     items: _units.map((unit) {
//                       return DropdownMenuItem(
//                         value: unit,
//                         child: Text(unit.toUpperCase()),
//                       );
//                     }).toList(),
//                     onChanged: (value) {
//                       setState(() {
//                         _selectedUnit = value!;
//                       });
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
            
//             // Price
//             TextFormField(
//               controller: _priceController,
//               keyboardType: TextInputType.number,
//               decoration: InputDecoration(
//                 labelText: 'Price *',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 prefixIcon: const Icon(Icons.currency_rupee),
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter price';
//                 }
//                 if (double.tryParse(value) == null) {
//                   return 'Please enter valid price';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 12),
            
//             // Stock and Min Stock
//             Row(
//               children: [
//                 Expanded(
//                   child: TextFormField(
//                     controller: _stockController,
//                     keyboardType: TextInputType.number,
//                     decoration: InputDecoration(
//                       labelText: 'Current Stock *',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       prefixIcon: const Icon(Icons.inventory_2),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter stock';
//                       }
//                       if (double.tryParse(value) == null) {
//                         return 'Please enter valid stock';
//                       }
//                       return null;
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: TextFormField(
//                     controller: _minStockController,
//                     keyboardType: TextInputType.number,
//                     decoration: InputDecoration(
//                       labelText: 'Min Stock *',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       prefixIcon: const Icon(Icons.warning),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter min stock';
//                       }
//                       if (double.tryParse(value) == null) {
//                         return 'Please enter valid min stock';
//                       }
//                       return null;
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
            
//             // Category
//             DropdownButtonFormField<String>(
//               value: _selectedCategory,
//               decoration: InputDecoration(
//                 labelText: 'Category *',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               items: _categories.map((category) {
//                 return DropdownMenuItem(
//                   value: category,
//                   child: Text(category),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 setState(() {
//                   _selectedCategory = value!;
//                 });
//               },
//             ),
//             const SizedBox(height: 12),
            
//             // Description
//             TextFormField(
//               controller: _descriptionController,
//               maxLines: 3,
//               decoration: InputDecoration(
//                 labelText: 'Description',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 alignLabelWithHint: true,
//               ),
//             ),
//             const SizedBox(height: 24),
            
//             // Buttons
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: const Text('Cancel'),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () async {
//                       if (_formKey.currentState!.validate()) {
//                         final inventoryProvider = Provider.of<InventoryProvider>(
//                           context,
//                           listen: false,
//                         );
                        
//                         final updatedItem = InventoryItem(
//                           id: widget.item.id,
//                           name: _nameController.text,
//                           nameHindi: _nameHindiController.text.isNotEmpty
//                               ? _nameHindiController.text
//                               : null,
//                           weight: double.parse(_weightController.text),
//                           unit: _selectedUnit,
//                           price: double.parse(_priceController.text),
//                           stock: double.parse(_stockController.text),
//                           minStock: double.parse(_minStockController.text),
//                           category: _selectedCategory,
//                           description: _descriptionController.text.isNotEmpty
//                               ? _descriptionController.text
//                               : null,
//                           createdAt: widget.item.createdAt,
//                           updatedAt: DateTime.now(),
//                         );

//                         try {
//                           // FIXED: Pass both id and updatedItem to the provider
//                           await inventoryProvider.updateProduct(widget.item.id, updatedItem);
//                           if (context.mounted) Navigator.pop(context);
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text('"${updatedItem.name}" updated successfully'),
//                               backgroundColor: Colors.green,
//                               behavior: SnackBarBehavior.floating,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                           );
//                         } catch (e) {
//                           if (context.mounted) Navigator.pop(context);
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text('Error: $e'),
//                               backgroundColor: Colors.red,
//                               behavior: SnackBarBehavior.floating,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                           );
//                         }
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: GlobalColors.primaryBlue,
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: const Text('Update'),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Add Product Screen
// class AddProductScreen extends StatefulWidget {
//   const AddProductScreen({super.key});

//   @override
//   State<AddProductScreen> createState() => _AddProductScreenState();
// }

// class _AddProductScreenState extends State<AddProductScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _nameHindiController = TextEditingController();
//   final _weightController = TextEditingController();
//   final _priceController = TextEditingController();
//   final _stockController = TextEditingController(text: '0');
//   final _minStockController = TextEditingController(text: '10');
//   final _descriptionController = TextEditingController();
  
//   String _selectedUnit = 'kg';
//   String _selectedCategory = 'Animal Feed';

//   final List<String> _units = ['kg', 'g', 'pack', 'liter', 'piece'];
//   final List<String> _categories = [
//     'Animal Feed',
//     'Dairy Products',
//     'Veterinary',
//     'Supplements',
//     'Equipment',
//     'Others'
//   ];

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _nameHindiController.dispose();
//     _weightController.dispose();
//     _priceController.dispose();
//     _stockController.dispose();
//     _minStockController.dispose();
//     _descriptionController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: GlobalColors.background,
//       appBar: AppBar(
//         backgroundColor: GlobalColors.primaryBlue,
//         elevation: 0,
//         title: Text(
//           'Add New Product',
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//             fontSize: 20,
//           ),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _sectionHeader('Product Information'),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _nameController,
//                 decoration: InputDecoration(
//                   labelText: 'Product Name (English) *',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   prefixIcon: const Icon(Icons.label),
//                   filled: true,
//                   fillColor: Colors.white,
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Product name is required';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _nameHindiController,
//                 decoration: InputDecoration(
//                   labelText: 'Product Name (मराठी)',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   prefixIcon: const Icon(Icons.translate),
//                   filled: true,
//                   fillColor: Colors.white,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _weightController,
//                       keyboardType: TextInputType.number,
//                       decoration: InputDecoration(
//                         labelText: 'Weight *',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         prefixIcon: const Icon(Icons.scale),
//                         filled: true,
//                         fillColor: Colors.white,
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Weight is required';
//                         }
//                         if (double.tryParse(value) == null) {
//                           return 'Enter valid weight';
//                         }
//                         return null;
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: DropdownButtonFormField<String>(
//                       value: _selectedUnit,
//                       decoration: InputDecoration(
//                         labelText: 'Unit *',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         filled: true,
//                         fillColor: Colors.white,
//                       ),
//                       items: _units.map((unit) {
//                         return DropdownMenuItem(
//                           value: unit,
//                           child: Text(unit.toUpperCase()),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedUnit = value!;
//                         });
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _priceController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   labelText: 'Price *',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   prefixIcon: const Icon(Icons.currency_rupee),
//                   filled: true,
//                   fillColor: Colors.white,
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Price is required';
//                   }
//                   if (double.tryParse(value) == null) {
//                     return 'Enter valid price';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               _sectionHeader('Stock Information'),
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _stockController,
//                       keyboardType: TextInputType.number,
//                       decoration: InputDecoration(
//                         labelText: 'Initial Stock',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         prefixIcon: const Icon(Icons.inventory_2),
//                         filled: true,
//                         fillColor: Colors.white,
//                       ),
//                       validator: (value) {
//                         if (value != null && value.isNotEmpty) {
//                           if (double.tryParse(value) == null) {
//                             return 'Enter valid stock';
//                           }
//                         }
//                         return null;
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: TextFormField(
//                       controller: _minStockController,
//                       keyboardType: TextInputType.number,
//                       decoration: InputDecoration(
//                         labelText: 'Minimum Stock',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         prefixIcon: const Icon(Icons.warning),
//                         filled: true,
//                         fillColor: Colors.white,
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Min stock is required';
//                         }
//                         if (double.tryParse(value) == null) {
//                           return 'Enter valid min stock';
//                         }
//                         return null;
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: _selectedCategory,
//                 decoration: InputDecoration(
//                   labelText: 'Category *',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   filled: true,
//                   fillColor: Colors.white,
//                 ),
//                 items: _categories.map((category) {
//                   return DropdownMenuItem(
//                     value: category,
//                     child: Text(category),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedCategory = value!;
//                   });
//                 },
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Category is required';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _descriptionController,
//                 maxLines: 3,
//                 decoration: InputDecoration(
//                   labelText: 'Description (Optional)',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   alignLabelWithHint: true,
//                   filled: true,
//                   fillColor: Colors.white,
//                 ),
//               ),
//               const SizedBox(height: 32),
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   onPressed: () async {
//                     if (_formKey.currentState!.validate()) {
//                       final inventoryProvider = Provider.of<InventoryProvider>(
//                         context,
//                         listen: false,
//                       );

//                       final newProduct = InventoryItem(
//                         id: '',
//                         name: _nameController.text,
//                         nameHindi: _nameHindiController.text.isNotEmpty
//                             ? _nameHindiController.text
//                             : null,
//                         weight: double.parse(_weightController.text),
//                         unit: _selectedUnit,
//                         price: double.parse(_priceController.text),
//                         stock: double.parse(_stockController.text),
//                         minStock: double.parse(_minStockController.text),
//                         category: _selectedCategory,
//                         description: _descriptionController.text.isNotEmpty
//                             ? _descriptionController.text
//                             : null,
//                         createdAt: DateTime.now(),
//                         updatedAt: DateTime.now(),
//                       );

//                       try {
//                         await inventoryProvider.addProduct(newProduct);
//                         if (context.mounted) {
//                           Navigator.pop(context);
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text('"${newProduct.name}" added successfully'),
//                               backgroundColor: Colors.green,
//                               behavior: SnackBarBehavior.floating,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                           );
//                         }
//                       } catch (e) {
//                         if (context.mounted) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text('Error: $e'),
//                               backgroundColor: Colors.red,
//                               behavior: SnackBarBehavior.floating,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                           );
//                         }
//                       }
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: GlobalColors.primaryBlue,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: Text(
//                     'Add Product',
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _sectionHeader(String title) {
//     return Text(
//       title,
//       style: GoogleFonts.poppins(
//         fontSize: 18,
//         fontWeight: FontWeight.w600,
//         color: Colors.black,
//       ),
//     );
//   }
// }