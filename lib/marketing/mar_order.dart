import 'package:flutter/material.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/providers/emp_order_provider.dart';
import 'package:provider/provider.dart';

class CattleFeedOrderScreen extends StatefulWidget {
  const CattleFeedOrderScreen({super.key});

  @override
  State<CattleFeedOrderScreen> createState() => _CattleFeedOrderScreenState();
}

class _CattleFeedOrderScreenState extends State<CattleFeedOrderScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int selectedBags = 1;
  String? selectedCategory;
  bool _orderPlaced = false;
  Map<String, dynamic>? _orderDetails;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  // Category definitions with bag weights
  final Map<String, Map<String, dynamic>> categories = {
    "मिल्क पॉवर / Milk Power": {"weight": 20, "unit": "kg", "price": 350},
    "दुध सरिता / Dugdh Sarita": {"weight": 25, "unit": "kg", "price": 450},
    "दुग्धराज / Dugdh Raj": {"weight": 30, "unit": "kg", "price": 600},
    "डायमंड संतुलित पशु आहार / Diamond Balanced Animal Feed": {"weight": 10, "unit": "kg", "price": 800},
    "मिल्क पॉवर प्लस / Milk Power Plus": {"weight": 5, "unit": "kg", "price": 1200},
    "संतुलित पशु आहार / Santulit Pashu Aahar": {"weight": 5, "unit": "kg", "price": 1200},
    "जीवन धारा / Jeevan Dhara": {"weight": 5, "unit": "kg", "price": 1200},
    "Dairy Special संतुलित पशु आहार": {"weight": 5, "unit": "kg", "price": 1200},
  };

  // Bag quantity options
  final List<int> bagOptions = [1, 2, 3, 4, 5, 10, 15, 20, 25, 30, 40, 50];

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    if (_orderPlaced) {
      return _buildSuccessPage(orderProvider);
    }

    return Scaffold(
      backgroundColor: GlobalColors.background,      
      body: orderProvider.loading
          ? const Center(
              child: CircularProgressIndicator(
                color: GlobalColors.primaryBlue,
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            "New Feed Order",
                            style: TextStyle(
                              color: GlobalColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Fill the details to place order",
                            style: TextStyle(
                              color: GlobalColors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Customer Details Section
                    _buildSectionHeader("Customer Information"),
                    _buildCard(
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: nameController,
                            label: "Customer Name *",
                            hintText: "Enter full name",
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter customer name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: mobileController,
                            label: "Mobile Number *",
                            hintText: "10 digit mobile number",
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter mobile number';
                              }
                              if (value.length != 10 || int.tryParse(value) == null) {
                                return 'Enter valid 10-digit mobile number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: addressController,
                            label: "Delivery Address *",
                            hintText: "Enter complete delivery address",
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter delivery address';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Order Details Section
                    _buildSectionHeader("Order Details"),
                    _buildCard(
                      child: Column(
                        children: [
                          // Category Dropdown
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Feed Category *"),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 1,
                                  ),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: selectedCategory,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    prefixIcon: Icon(
                                      Icons.category_outlined,
                                      color: GlobalColors.primaryBlue,
                                    ),
                                  ),
                                  hint: const Text(
                                    "Select feed category",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  isExpanded: true,
                                  items: categories.keys
                                      .map((category) => DropdownMenuItem(
                                            value: category,
                                            child: Text(
                                              category,
                                              style: const TextStyle(fontSize: 14),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => selectedCategory = value),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a category';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Quantity Selection (Bags)
                          if (selectedCategory != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Number of Bags *"),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 60,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: bagOptions.length,
                                    itemBuilder: (context, index) {
                                      final bags = bagOptions[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                          label: Text('$bags Bag${bags > 1 ? 's' : ''}'),
                                          selected: selectedBags == bags,
                                          selectedColor: GlobalColors.primaryBlue,
                                          labelStyle: TextStyle(
                                            color: selectedBags == bags
                                                ? GlobalColors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          onSelected: (selected) {
                                            setState(() {
                                              selectedBags = bags;
                                            });
                                          },
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: GlobalColors.primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: GlobalColors.primaryBlue.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: GlobalColors.primaryBlue, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Each bag contains ${categories[selectedCategory]!['weight']} ${categories[selectedCategory]!['unit']}",
                                          style: TextStyle(
                                            color: GlobalColors.primaryBlue,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Total Weight Calculation
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Total Quantity",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Weight",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "$selectedBags Bags",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: GlobalColors.primaryBlue,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${(selectedBags * categories[selectedCategory]!['weight'])} ${categories[selectedCategory]!['unit']}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Remarks Section
                    _buildSectionHeader("Additional Information"),
                    _buildCard(
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: remarksController,
                            label: "Remarks (Optional)",
                            hintText: "Any special instructions or notes...",
                            icon: Icons.note_outlined,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Place Order Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlobalColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          onPressed: () => _submitOrder(orderProvider),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline,
                                  color: GlobalColors.white, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                "PLACE ORDER",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: GlobalColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // --------------------------------------------------------
  // Success Page
  // --------------------------------------------------------
  Widget _buildSuccessPage(OrderProvider orderProvider) {
    final totalWeight =
        selectedBags * categories[_orderDetails!['feed_category']]!['weight'];
    final unit = categories[_orderDetails!['feed_category']]!['unit'];
    final pricePerBag = categories[_orderDetails!['feed_category']]!['price'];
    final totalPrice = selectedBags * pricePerBag;

    return Scaffold(
      backgroundColor: GlobalColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: GlobalColors.primaryBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Order Confirmed",
          style: TextStyle(
            color: GlobalColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: GlobalColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: GlobalColors.primaryBlue.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: GlobalColors.primaryBlue,
                      size: 70,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Success Message
                  const Text(
                    "Order Placed Successfully!",
                    style: TextStyle(
                      color: GlobalColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Order will appear in production orders",
                    style: TextStyle(
                      color: GlobalColors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Order Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order Summary",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Customer Info
                        _successDetailRow("Customer", _orderDetails!['customer_name']),
                        const SizedBox(height: 12),
                        _successDetailRow("Mobile", _orderDetails!['customer_mobile']),
                        const SizedBox(height: 12),
                        _successDetailRow("Address", _orderDetails!['customer_address']),
                        const Divider(height: 24),

                        // Order Info
                        _successDetailRow("Category", _orderDetails!['feed_category']),
                        const SizedBox(height: 12),
                        _successDetailRow("Bags", "${_orderDetails!['bags']} Bags"),
                        const SizedBox(height: 12),
                        _successDetailRow("Weight", "$totalWeight $unit"),
                        const SizedBox(height: 12),
                        _successDetailRow("Price per Bag", "₹$pricePerBag"),
                        const Divider(height: 24),

                        // Total Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Amount",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "₹$totalPrice",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: GlobalColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Payment: To be collected on delivery",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: GlobalColors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "What's Next?",
                              style: TextStyle(
                                color: GlobalColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Our production team will process this order. You can track the order status in the Production Orders section.",
                          style: TextStyle(
                            color: GlobalColors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Action Buttons - Fixed at bottom
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _orderPlaced = false;
                        _resetForm();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: GlobalColors.primaryBlue,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      "NEW ORDER",
                      style: TextStyle(
                        color: GlobalColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      "BACK TO HOME",
                      style: TextStyle(
                        color: GlobalColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _successDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------
  // Helper Methods
  // --------------------------------------------------------

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.grey,
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, color: GlobalColors.primaryBlue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: GlobalColors.primaryBlue,
                width: 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 0,
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------
  // Order Submission Logic
  // --------------------------------------------------------
  Future<void> _submitOrder(OrderProvider orderProvider) async {
    if (!_formKey.currentState!.validate()) {
      _showError("Please fill all required fields");
      return;
    }

    if (selectedCategory == null) {
      _showError("Please select a feed category");
      return;
    }

    try {
      final category = selectedCategory!;
      final meta = categories[category]!;
      final pricePerBag = meta['price'] as int;
      final totalPrice = selectedBags * pricePerBag;

      // Prepare order data matching emp_mar_orders table structure
      final orderData = {
        'customer_name': nameController.text.trim(),
        'customer_mobile': mobileController.text.trim(),
        'customer_address': addressController.text.trim(),
        'feed_category': category,
        'bags': selectedBags,
        'weight_per_bag': meta['weight'],
        'weight_unit': meta['unit'],
        'total_weight': selectedBags * meta['weight'],
        'price_per_bag': pricePerBag,
        'total_price': totalPrice,
        'remarks': remarksController.text.trim().isEmpty ? null : remarksController.text.trim(),
        'status': 'pending', // Default status
      };

      print('Submitting order to emp_mar_orders: $orderData');

      await orderProvider.createOrder(orderData);

      setState(() {
        _orderDetails = {
          'customer_name': nameController.text.trim(),
          'customer_mobile': mobileController.text.trim(),
          'customer_address': addressController.text.trim(),
          'feed_category': category,
          'bags': selectedBags,
          'price_per_bag': pricePerBag,
          'total_price': totalPrice,
          'remarks': remarksController.text.trim(),
        };
        _orderPlaced = true;
      });

    } catch (e) {
      print('Error placing order: $e');
      _showError("Failed to place order: ${e.toString()}");
    }
  }

  void _resetForm() {
    nameController.clear();
    mobileController.clear();
    addressController.clear();
    remarksController.clear();
    selectedCategory = null;
    selectedBags = 1;
    _orderDetails = null;
  }
  
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}







// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// final supabase = Supabase.instance.client;

// class MakeOrderPage extends StatefulWidget {
//   const MakeOrderPage({super.key});

//   @override
//   State<MakeOrderPage> createState() => _MakeOrderPageState();
// }

// class _MakeOrderPageState extends State<MakeOrderPage> {
//   final _formKey = GlobalKey<FormState>();
//   final Color themePrimary = const Color(0xFF2563EB);

//   // Form Controllers
//   final TextEditingController _customerNameController = TextEditingController();
//   final TextEditingController _enterpriseNameController = TextEditingController();
//   final TextEditingController _quantityController = TextEditingController();
  
//   // Data Lists
//   final List<String> _productCategories = ['Feed', 'Fertilizer', 'Seeds'];
//   final List<String> _talukas = ['Haveli', 'Khed', 'Baramati', 'Shirur', 'Maval'];
  
//   String? _selectedCategory;
//   String? _selectedTaluka;
  
//   // Static Manager Data 
//   final String _managerName = "District Manager Alpha";
//   final String _assignedDistrict = "Pune";

//   bool _isSubmitting = false;

//   Future<void> _submitOrder() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => _isSubmitting = true);
      
//       try {
//         // This Map must match your Supabase column names exactly
//         final Map<String, dynamic> newManagerOrder = {
//           'manager_name': _managerName,
//           'district': _assignedDistrict,
//           'taluka': _selectedTaluka, 
//           'product_name': _selectedCategory!,
//           'quantity_tons': double.parse(_quantityController.text),
//           'customer_name': _customerNameController.text,
//           'enterprise_name': _enterpriseNameController.text,
//           'order_status': 'Completed',
//           'created_at': DateTime.now().toIso8601String(),
//         };

//         // Targeting the specific manager table
//         await supabase.from('manager_orders').insert(newManagerOrder);

//         if (mounted) {
//           _showSuccessFeedback();
//           Navigator.pop(context);
//         }
//       } on PostgrestException catch (e) {
//         _showErrorSnackBar('Database Error: ${e.message}');
//       } catch (e) {
//         _showErrorSnackBar('Connection Error. Please try again.');
//       } finally {
//         if (mounted) setState(() => _isSubmitting = false);
//       }
//     }
//   }

//   void _showSuccessFeedback() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.check_circle, color: Colors.white),
//             const SizedBox(width: 12),
//             Text('Order for $_selectedTaluka logged!'),
//           ],
//         ),
//         backgroundColor: Colors.green[700],
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
      
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             padding: const EdgeInsets.all(20.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildSectionHeader("Area & Product"),
//                   const SizedBox(height: 16),
                  
//                   // Taluka Selection
//                   _buildDropdown(
//                     label: 'Target Taluka',
//                     icon: Icons.location_on_outlined,
//                     value: _selectedTaluka,
//                     items: _talukas,
//                     onChanged: (val) => setState(() => _selectedTaluka = val),
//                   ),
//                   const SizedBox(height: 16),

//                   // Product Selection
//                   _buildDropdown(
//                     label: 'Product Category',
//                     icon: Icons.inventory_2_outlined,
//                     value: _selectedCategory,
//                     items: _productCategories,
//                     onChanged: (val) => setState(() => _selectedCategory = val),
//                   ),
//                   const SizedBox(height: 24),

//                   _buildSectionHeader("Customer Information"),
//                   const SizedBox(height: 16),

//                   _buildTextField(_customerNameController, 'Customer Name', Icons.person_outline),
//                   const SizedBox(height: 16),
//                   _buildTextField(_enterpriseNameController, 'Enterprise/Shop Name', Icons.business),
//                   const SizedBox(height: 16),
                  
//                   _buildTextField(
//                     _quantityController, 
//                     'Quantity (Tons)', 
//                     Icons.scale_outlined,
//                     isNumber: true
//                   ),
                  
//                   const SizedBox(height: 32),

//                   // Submit Button
//                   SizedBox(
//                     width: double.infinity,
//                     height: 55,
//                     child: ElevatedButton(
//                       onPressed: _isSubmitting ? null : _submitOrder,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: themePrimary,
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         elevation: 2,
//                       ),
//                       child: Text("CONFIRM & LOG SALE", 
//                           style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           if (_isSubmitting)
//             Container(
//               color: Colors.black26,
//               child: const Center(child: CircularProgressIndicator()),
//             ),
//         ],
//       ),
//     );
//   }

//   // --- UI Helper Methods ---

//   Widget _buildSectionHeader(String title) {
//     return Text(
//       title,
//       style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: themePrimary),
//     );
//   }

//   Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//         filled: true,
//         fillColor: Colors.grey[50],
//       ),
//       validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
//     );
//   }

//   Widget _buildDropdown({
//     required String label, 
//     required IconData icon, 
//     required String? value, 
//     required List<String> items, 
//     required Function(String?) onChanged
//   }) {
//     return DropdownButtonFormField<String>(
//       value: value,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//       items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
//       onChanged: onChanged,
//       validator: (val) => val == null ? 'Selection required' : null,
//     );
//   }
// }









