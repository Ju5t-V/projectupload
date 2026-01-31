import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert'; // For Base64 images

class AdminInventoryScreen extends StatelessWidget {
  const AdminInventoryScreen({super.key});

  // LOGIC: Delete Product
  Future<void> _deleteProduct(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Product?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('products').doc(docId).delete();
    }
  }

  // LOGIC: Show Edit Dialog (Simplified for example)
  void _showEditDialog(BuildContext context, Map<String, dynamic> data, String docId) {
    // You can implement the full edit form here similar to AddProductScreen
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Edit feature coming soon!")));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Safety check
    if (user == null) return const Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      appBar: AppBar(title: const Text("My Inventory")),
      body: StreamBuilder<QuerySnapshot>(
        // <--- KEY FIX: Filter by owner_id --->
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('owner_id', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading products"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(child: Text("You haven't added any products yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index].data() as Map<String, dynamic>;
              final id = products[index].id;
              
              final stock = data['stock'] ?? 0;
              final imageString = data['image_url'] ?? '';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 50, height: 50,
                    color: Colors.grey[200],
                    child: _buildImage(imageString),
                  ),
                  title: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    stock > 0 ? "In Stock: $stock" : "OUT OF STOCK",
                    style: TextStyle(
                      color: stock > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDialog(context, data, id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProduct(context, id),
                      ),
                    ],
                  ),
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