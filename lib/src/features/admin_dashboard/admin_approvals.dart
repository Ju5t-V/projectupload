import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminApprovalsScreen extends StatelessWidget {
  const AdminApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Restricted Item Status"),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // <--- KEY FIX: Filter by owner_id and Category --->
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('owner_id', isEqualTo: user.uid) 
            .where('category', isEqualTo: 'Medicine') 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading status"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(child: Text("No restricted items submitted."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              
              // Colors based on status
              Color statusColor = Colors.orange;
              if (status == 'approved') statusColor = Colors.green;
              if (status == 'rejected') statusColor = Colors.red;

              return Card(
                child: ListTile(
                  leading: SizedBox(
                    width: 50, height: 50,
                    child: _buildImage(data['image_url'] ?? ''),
                  ),
                  title: Text(data['name'] ?? 'Item'),
                  subtitle: Text("Status: ${status.toUpperCase()}", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImage(String imageString) {
    if (imageString.isEmpty) return const Icon(Icons.image, color: Colors.grey);
    try {
      if (imageString.contains(',')) {
        return Image.memory(base64Decode(imageString.split(',').last), fit: BoxFit.cover);
      }
      return Image.memory(base64Decode(imageString), fit: BoxFit.cover);
    } catch (e) {
      return const Icon(Icons.broken_image, color: Colors.grey);
    }
  }
}