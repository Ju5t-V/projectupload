import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  // --- NEW FUNCTION: Sync Calculated Sales to User Profile ---
  Future<void> _updateUserTotalSales(String userId, double calculatedTotal) async {
    // This writes the total found in orders to the 'total_sales' field in the 'users' collection
    // so the Mentor can see it.
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'total_sales': calculatedTotal,
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      appBar: AppBar(title: const Text("My Analytics")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('seller_id', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final orders = snapshot.data?.docs ?? [];
          
          double totalRevenue = 0;
          int completedOrders = 0;
          int pendingOrders = 0;

          // 1. Calculate the real numbers
          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Pending';
            final amount = (data['total_amount'] ?? 0).toDouble();

            if (status == 'Completed') {
              totalRevenue += amount;
              completedOrders++;
            } else if (status == 'Pending') {
              pendingOrders++;
            }
          }

          // 2. AUTO-SYNC: Update the database so the Mentor sees this number
          // We wrap this in a microtask to avoid calling setState during build
          Future.delayed(Duration.zero, () {
             _updateUserTotalSales(user.uid, totalRevenue);
          });

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bar_chart, size: 100, color: Colors.deepPurple),
                const SizedBox(height: 20),
                const Text("Sales Overview", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                
                // Add a small indicator so you know it is syncing
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Syncing with Mentor Dashboard...", 
                    style: TextStyle(color: Colors.grey, fontSize: 10)
                  ),
                ),

                const SizedBox(height: 10),
                
                // DATA CARDS
                _buildStatCard("Total Revenue", "RM ${totalRevenue.toStringAsFixed(2)}", Colors.green),
                _buildStatCard("Completed Orders", "$completedOrders", Colors.blue),
                _buildStatCard("Pending Orders", "$pendingOrders", Colors.orange),
                
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back to Dashboard"),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}