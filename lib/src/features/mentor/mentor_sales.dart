import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MentorSalesScreen extends StatelessWidget {
  const MentorSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Store Sales")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text("No orders found in the system."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              
              // We use this variable now in the text below
              final orderId = orders[index].id; 
              
              final total = (data['total_amount'] ?? 0).toDouble();
              final email = data['user_email'] ?? 'Unknown Customer';
              final items = data['items'] as List<dynamic>;

              int totalItemsCount = 0;
              for (var item in items) {
                totalItemsCount += (item['quantity'] as int);
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: const Icon(Icons.attach_money, color: Colors.green),
                  ),
                  // <--- UPDATED: Showing Order ID here
                  title: Text("RM ${total.toStringAsFixed(2)}  (#${orderId.substring(0,4)})", 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("$email • $totalItemsCount items"),
                  children: [
                    Container(
                      color: Colors.grey[50],
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items.map<Widget>((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text("${item['quantity']}x ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(child: Text(item['product_name'])),
                                Text("RM ${item['price']}"),
                              ],
                            ),
                          );
                        }).toList(),
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