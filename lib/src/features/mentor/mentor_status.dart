import 'dart:convert'; // <--- REQUIRED for Base64 Images
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MentorStatusScreen extends StatelessWidget {
  const MentorStatusScreen({super.key});

  // --- SAME HELPER FUNCTION ---
  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(imagePath, fit: BoxFit.cover, errorBuilder: (c,o,s) => const Icon(Icons.error));
    } else if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.split(',').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
      } catch (e) {
        return const Icon(Icons.broken_image);
      }
    } else {
      return Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (c,o,s) => const Icon(Icons.image));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Submission Status")),
      body: StreamBuilder<QuerySnapshot>(
        // FILTER: Only show items created by THIS logged-in Mentor
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('owner_id', isEqualTo: uid) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading data"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(child: Text("You haven't submitted any items yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index].data() as Map<String, dynamic>;
              
              final name = data['name'] ?? 'Unknown';
              final price = data['price'] ?? 0.0;
              final status = data['status'] ?? 'pending';
              final imageUrl = data['image_url'] ?? '';

              // Color Logic for Status
              Color statusColor = Colors.orange;
              IconData statusIcon = Icons.access_time;
              if (status == 'approved') {
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
              } else if (status == 'rejected') {
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: Container(
                    width: 50, height: 50,
                    color: Colors.grey[200],
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: _buildImage(imageUrl), // <--- USING HELPER HERE
                    ),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("RM ${price.toStringAsFixed(2)}"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}