import 'package:intl/intl.dart';

class OrderUtils {
  static String getDisplayOrderId(Map<String, dynamic> order) {
    // Priority 1: Use auto-generated order_number
    if (order['order_number'] != null && 
        order['order_number'].toString().isNotEmpty) {
      return order['order_number'].toString();
    }
    
    // Priority 2: Generate from UUID
    if (order['id'] != null) {
      final uuid = order['id'].toString();
      final shortId = uuid.substring(0, 8).toUpperCase();
      return '#$shortId';
    }
    
    // Priority 3: Generate from date and random number
    try {
      final date = DateTime.parse(order['created_at'] ?? DateTime.now().toString());
      final dateStr = DateFormat('yyMMdd').format(date);
      final random = DateTime.now().microsecondsSinceEpoch % 10000;
      final padded = random.toString().padLeft(4, '0');
      return 'TEMP-$dateStr-$padded';
    } catch (e) {
      return '#N/A';
    }
  }
  
  static String formatOrderDate(String? dateString) {
    if (dateString == null) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }
  
  static String formatPrice(int price) {
    return '₹${NumberFormat('#,##,###').format(price)}';
  }
}