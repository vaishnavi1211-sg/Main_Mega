import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mega_pro/providers/emp_order_provider.dart';

class OrderNotificationButtons extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> order;
  final bool showLabels;
  final bool compact;

  const OrderNotificationButtons({
    Key? key,
    required this.orderId,
    required this.order,
    this.showLabels = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasWhatsApp = order['customer_mobile']?.toString().isNotEmpty ?? false;
    final hasEmail = order['customer_email']?.toString().isNotEmpty ?? false;
    final whatsappSent = order['whatsapp_sent'] == true;
    final emailSent = order['email_sent'] == true;

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasWhatsApp)
            IconButton(
              icon: Icon(
                Icons.message,
                color: whatsappSent ? Colors.green : Colors.grey,
                size: 20,
              ),
              onPressed: () {
                Provider.of<OrderProvider>(context, listen: false)
                  .sendOrderWhatsAppNotification(
                    context: context,
                    orderId: orderId,
                    order: order,
                  );
              },
              tooltip: whatsappSent ? 'WhatsApp sent' : 'Send WhatsApp',
            ),
          
          if (hasEmail)
            IconButton(
              icon: Icon(
                Icons.email,
                color: emailSent ? Colors.blue : Colors.grey,
                size: 20,
              ),
              onPressed: () {
                Provider.of<OrderProvider>(context, listen: false)
                  .sendOrderEmailNotification(
                    context: context,
                    orderId: orderId,
                    order: order,
                  );
              },
              tooltip: emailSent ? 'Email sent' : 'Send email',
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasWhatsApp || hasEmail)
          const Text(
            'Send Notifications:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (hasWhatsApp)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Provider.of<OrderProvider>(context, listen: false)
                      .sendOrderWhatsAppNotification(
                        context: context,
                        orderId: orderId,
                        order: order,
                      );
                  },
                  icon: Icon(
                    Icons.message,
                    color: whatsappSent ? Colors.white : Colors.green,
                  ),
                  label: Text(
                    whatsappSent ? 'WhatsApp Sent' : 'Send WhatsApp',
                    style: TextStyle(
                      color: whatsappSent ? Colors.white : Colors.green,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: whatsappSent ? Colors.green : Colors.green[50],
                    side: BorderSide(
                      color: whatsappSent ? Colors.green : Colors.green,
                    ),
                  ),
                ),
              ),
            
            if (hasWhatsApp && hasEmail) const SizedBox(width: 10),
            
            if (hasEmail)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Provider.of<OrderProvider>(context, listen: false)
                      .sendOrderEmailNotification(
                        context: context,
                        orderId: orderId,
                        order: order,
                      );
                  },
                  icon: Icon(
                    Icons.email,
                    color: emailSent ? Colors.white : Colors.blue,
                  ),
                  label: Text(
                    emailSent ? 'Email Sent' : 'Send Email',
                    style: TextStyle(
                      color: emailSent ? Colors.white : Colors.blue,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emailSent ? Colors.blue : Colors.blue[50],
                    side: BorderSide(
                      color: emailSent ? Colors.blue : Colors.blue,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}