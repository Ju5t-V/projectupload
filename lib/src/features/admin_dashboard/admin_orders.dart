import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Ensure you have intl in pubspec.yaml

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Safety check
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Incoming Orders")),
      body: StreamBuilder<QuerySnapshot>(
        // 1. FILTER: Only show orders assigned to THIS seller
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('seller_id', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             // Handle the "Index" error gracefully
             if (snapshot.error.toString().contains('index')) {
               return const Center(child: Padding(
                 padding: EdgeInsets.all(20.0),
                 child: Text("Missing Index! Check debug console for the link to create it."),
               ));
             }
             return Center(child: Text("Error: ${snapshot.error}"));
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data?.docs ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No orders found."),
                  Text("(Orders must have 'seller_id' field)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderData = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              
              // Safe Data Extraction
              final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
              final total = (orderData['total_amount'] ?? 0).toDouble();
              final status = orderData['status'] ?? 'Pending';
              final Timestamp? ts = orderData['timestamp'];
              
              // Format Date
              final dateString = ts != null 
                  ? DateFormat('dd MMM, hh:mm a').format(ts.toDate()) 
                  : 'Date Unknown';

              // Status Color Logic
              Color statusColor = Colors.orange;
              if (status == 'Shipped') statusColor = Colors.blue;
              if (status == 'Completed') statusColor = Colors.green;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.all(16),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Order #${orderId.substring(0, 5).toUpperCase()}", 
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor)
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("$dateString • RM ${total.toStringAsFixed(2)}"),
                  ),
                  children: [
                    const Divider(),
                    
                    // ITEM LIST
                    ...items.map((item) => ListTile(
                      visualDensity: VisualDensity.compact,
                      title: Text(item['product_name'] ?? 'Item'),
                      trailing: Text("x${item['quantity']}"),
                    )),

                    const Divider(),

                    // ACTION BUTTONS AREA
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           // Helper Text
                           Expanded(
                             child: Text(
                               _getStatusHelperText(status),
                               style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                             ),
                           ),

                           // THE BUTTON
                           if (status == 'Pending')
                            ElevatedButton.icon(
                              onPressed: () {
                                // 2. ACTION: Update to 'Shipped'
                                FirebaseFirestore.instance
                                    .collection('orders')
                                    .doc(orderId)
                                    .update({'status': 'Shipped'});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.local_shipping, size: 16),
                              label: const Text("Mark Shipped"),
                            ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getStatusHelperText(String status) {
    switch (status) {
      case 'Pending': return "Action Required: Pack and Ship items.";
      case 'Shipped': return "Waiting for customer to confirm receipt.";
      case 'Completed': return "Order successfully closed.";
      default: return "";
    }
  }
}