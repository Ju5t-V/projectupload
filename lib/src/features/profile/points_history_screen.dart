import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PointsHistoryScreen extends StatelessWidget {
  final int currentPoints;

  const PointsHistoryScreen({super.key, required this.currentPoints});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("My points", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
           
            Text(
              "$currentPoints points",
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "Points expire 12 months after they were earned",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 30),

            
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Points history", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 15),

            
            user == null
                ? const Center(child: Text("Please log in"))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('user_id', isEqualTo: user.uid)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 20.0),
                          child: Text("No orders found."),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;

                          
                          final int points = (data['total_amount'] ?? 0).toInt();

                          
                          final Timestamp? timestamp = data['timestamp'];
                          final String dateString = timestamp != null
                              ? DateFormat('dd-MM-yyyy').format(timestamp.toDate())
                              : "Unknown Date";
                          
                          
                          String displayTitle = "Order Processed"; // Fallback
                          
                          
                          final List<dynamic> items = data['items'] ?? [];
                          
                          if (items.isNotEmpty) {
                           
                            final firstItem = items[0] as Map<String, dynamic>;
                            final String productName = firstItem['product_name'] ?? 'Unknown Item';
                            
                            
                            if (items.length > 1) {
                              displayTitle = "Purchased $productName & ${items.length - 1} more";
                            } else {
                              displayTitle = "Purchased $productName";
                            }
                          } else {
                             
                             if (data['product_name'] != null) {
                               displayTitle = "Purchased ${data['product_name']}";
                             }
                          }

                          return _buildHistoryItem(
                            isEarned: true, 
                            date: dateString, 
                            points: points,
                            description: displayTitle
                          );
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem({
    required bool isEarned, 
    required String date, 
    required int points, 
    required String description
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEarned ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEarned ? Icons.arrow_upward : Icons.arrow_downward,
              color: isEarned ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "+$points",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[700]),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.stars, color: Colors.orange, size: 18),
        ],
      ),
    );
  }
}