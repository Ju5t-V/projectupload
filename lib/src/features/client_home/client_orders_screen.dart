import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ClientOrdersScreen extends StatelessWidget {
  const ClientOrdersScreen({super.key});

  // --- LOGIC: UPDATE ORDER STATUS TO COMPLETED ---
  Future<void> _confirmOrderReceived(BuildContext context, String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': 'Completed'});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order confirmed as received!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("My Orders")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('user_id', isEqualTo: user?.uid) // Filter: ONLY my orders
            .orderBy('timestamp', descending: true) // Sort: Newest first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final orders = snapshot.data?.docs ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No orders placed yet"),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final status = order['status'] ?? 'Pending';
              final total = (order['total_amount'] ?? 0).toDouble();
              final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
              final Timestamp? timestamp = order['timestamp'];

              // Color Logic
              Color statusColor = Colors.grey;
              IconData statusIcon = Icons.access_time;
              
              if (status == 'Pending') {
                statusColor = Colors.orange;
                statusIcon = Icons.timer;
              } else if (status == 'Shipped') {
                statusColor = Colors.blue;
                statusIcon = Icons.local_shipping;
              } else if (status == 'Completed') {
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
              } else if (status == 'Cancelled') {
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
              }

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  title: Text(
                    "Order #${orderId.substring(0, 5).toUpperCase()}", 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(timestamp != null 
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate()) 
                        : "Date Unknown",
                        style: const TextStyle(fontSize: 12, color: Colors.grey)
                      ),
                      const SizedBox(height: 5),
                      Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  trailing: Text(
                    "RM ${total.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Divider(color: Colors.grey[200], height: 1),
                    Container(
                      color: Colors.grey[50],
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        children: [
                          // 1. LIST OF ITEMS
                          ...items.map((item) {
                            return ListTile(
                              visualDensity: VisualDensity.compact,
                              title: Text(item['product_name'] ?? 'Item'),
                              trailing: Text("x${item['quantity']}"),
                            );
                          }),

                          // 2. CONFIRM BUTTON (Only appears if Shipped)
                          if (status == 'Shipped') ...[
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _confirmOrderReceived(context, orderId),
                                  icon: const Icon(Icons.check, color: Colors.white),
                                  label: const Text("Confirm Item Received"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          
                          // 3. MESSAGE IF PENDING
                          if (status == 'Pending')
                             const Padding(
                               padding: EdgeInsets.all(8.0),
                               child: Text("Waiting for seller to ship...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
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
}