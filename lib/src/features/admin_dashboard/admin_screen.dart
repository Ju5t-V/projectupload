import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart'; // Ensure this path is correct for your project
import 'admin_orders.dart';
import 'admin_inventory.dart';
import 'add_product_screen.dart';
import 'admin_reports.dart';
import 'admin_approvals.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  void _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user to optionally show their name in the header
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Seller Dashboard", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _handleLogout(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional: Welcome Text
            Text(
              "Welcome, ${user?.displayName ?? 'Seller'}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // 1. ORDERS CARD (Red - Urgent)
            _buildDashboardCard(
              context,
              title: "Incoming Orders",
              icon: Icons.notifications_active,
              color: Colors.redAccent,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrdersScreen())),
            ),
            const SizedBox(height: 15),

            // 2. INVENTORY CARD (Blue - Management)
            _buildDashboardCard(
              context,
              title: "My Inventory",
              icon: Icons.inventory,
              color: Colors.blueAccent,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminInventoryScreen())),
            ),
            const SizedBox(height: 15),

            // 3. ADD PRODUCT CARD (Green - Action)
            _buildDashboardCard(
              context,
              title: "Add New Product",
              icon: Icons.add_circle,
              color: Colors.green,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())),
            ),
            const SizedBox(height: 15),

            // 4. REPORTS CARD (Purple - Analysis)
            _buildDashboardCard(
              context,
              title: "Sales Reports",
              icon: Icons.bar_chart,
              color: Colors.deepPurple,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportsScreen())),
            ),
            const SizedBox(height: 15),

            // 5. APPROVALS CARD (Orange - Status)
            _buildDashboardCard(
              context,
              title: "Restricted Items",
              icon: Icons.history_edu,
              color: Colors.orange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminApprovalsScreen())),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper Widget for consistent Card Design
  Widget _buildDashboardCard(BuildContext context, {
    required String title, 
    required IconData icon, 
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}