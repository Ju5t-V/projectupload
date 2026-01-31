import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart'; 

class MentorScreen extends StatefulWidget {
  const MentorScreen({super.key});

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _currentAdminId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _handleLogout() {
    FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // --- ACTIONS ---
  Future<void> _approveProduct(String docId) async {
    await FirebaseFirestore.instance.collection('products').doc(docId).update({
      'status': 'approved',
      'approved_by': _currentAdminId,
      'approved_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _rejectProduct(String docId) async {
    await FirebaseFirestore.instance.collection('products').doc(docId).update({
      'status': 'rejected',
      'rejected_by': _currentAdminId,
    });
  }

  Future<void> _approveAdmin(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'status': 'approved',
      'admin_id': _currentAdminId, 
    });
  }

  Future<void> _rejectAdmin(String userId) async {
     await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'status': 'rejected',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: "Logout",
            onPressed: _handleLogout,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
          tabs: const [
            Tab(text: "Product Approval "),
            Tab(text: "Requests"), 
            Tab(text: "Reports"),  
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMedicineApprovalTab(),
          _buildAdminApprovalTab(),
          _buildReportsTab(), 
        ],
      ),
    );
  }

  // --- TAB 1: MEDICINE APPROVAL ---
  Widget _buildMedicineApprovalTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: 'Medicine')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final products = snapshot.data?.docs ?? [];
        if (products.isEmpty) {
           return _buildEmptyState("No pending approvals", Icons.check_circle_outline);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (ctx, i) {
            final data = products[i].data() as Map<String, dynamic>;
            final docId = products[i].id;
            final name = data['name'] ?? 'Unknown';
            final price = data['price'] ?? 0.0;
            final imageString = data['image_url'] ?? '';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImage(imageString),
                      ),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("Restricted Item (Medicine)", style: TextStyle(color: Colors.orange[800], fontSize: 12)),
                        Text("RM $price", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _rejectProduct(docId),
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text("Reject", style: TextStyle(color: Colors.red)),
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[200]),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _approveProduct(docId),
                          icon: const Icon(Icons.check, color: Colors.green),
                          label: const Text("Approve", style: TextStyle(color: Colors.green)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  //admin request
  Widget _buildAdminApprovalTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Seller')
          .where('status', isEqualTo: 'Pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final users = snapshot.data?.docs ?? [];
        if (users.isEmpty) {
          return _buildEmptyState("No new seller requests", Icons.person_add_disabled);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (ctx, i) {
            final data = users[i].data() as Map<String, dynamic>;
            final userId = users[i].id;
            final name = data['name'] ?? 'Unknown User';
            final email = data['email'] ?? 'No Email';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.blue[50],
                      child: const Icon(Icons.person_add, color: Colors.blue),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(email),
                  ),
                  const Divider(height: 1),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _rejectAdmin(userId),
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text("Decline", style: TextStyle(color: Colors.red)),
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[200]),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _approveAdmin(userId),
                          icon: const Icon(Icons.check, color: Colors.green),
                          label: const Text("Approve", style: TextStyle(color: Colors.green)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // reports
  Widget _buildReportsTab() {
    return StreamBuilder<QuerySnapshot>(
      
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('admin_id', isEqualTo: _currentAdminId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final myMentees = snapshot.data?.docs ?? [];
        
        // --- 1. Calculate Aggregates ---
        double totalNetworkSales = 0;
        double totalMyCommission = 0;

        for (var doc in myMentees) {
          final data = doc.data() as Map<String, dynamic>;
          final sales = (data['total_sales'] ?? 0).toDouble();
          totalNetworkSales += sales;
        }
        totalMyCommission = totalNetworkSales * 0.05; // 5% Cut

        return Column(
          children: [
            
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Network Sales", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text("\$${totalNetworkSales.toStringAsFixed(2)}", 
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("My Commission (5%)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text("\$${totalMyCommission.toStringAsFixed(2)}", 
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // list
            Expanded(
              child: myMentees.isEmpty 
              ? _buildEmptyState("You haven't approved any sellers yet.", Icons.analytics_outlined)
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: myMentees.length,
                itemBuilder: (ctx, i) {
                  final data = myMentees[i].data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'seller';
                  final email = data['email'] ?? 'No Email';
                  final sales = (data['total_sales'] ?? 0).toDouble();
                  final commission = sales * 0.05;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal[50],
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "A",
                          style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email, style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text("Sales Generated: \$${sales.toStringAsFixed(2)}", 
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("My Cut", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text("+\$${commission.toStringAsFixed(2)}", 
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildImage(String imageString) {
    if (imageString.isEmpty) return const Icon(Icons.image, color: Colors.grey);
    try {
      if (imageString.contains(',')) {
        final base64String = imageString.split(',').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
      }
      return Image.memory(base64Decode(imageString), fit: BoxFit.cover);
    } catch (e) {
      return const Icon(Icons.broken_image, color: Colors.grey);
    }
  }
}