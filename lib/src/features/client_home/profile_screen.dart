import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart'; 
import 'client_orders_screen.dart';
import '../profile/rewards_screen.dart'; // <--- IMPORT YOUR OLD REWARDS SCREEN
import '../client_home/setting_screen.dart'; // <--- IMPORT THE NEW SETTINGS SCREEN

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text("Please Login")));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("My Profile"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text("Error loading profile"));

          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final name = userData['name'] ?? 'User';
          final email = userData['email'] ?? user.email;
          final points = userData['points'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 1. PROFILE HEADER
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 15),
                      Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(email, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),

                // 2. POINTS CARD (Now Clickable)
                InkWell(
                  onTap: () {
                    // Navigate to the old Rewards/Points Tab
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen()));
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.blue, Colors.purple]),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Loyalty Points", style: TextStyle(color: Colors.white70)),
                            SizedBox(height: 5),
                            Text("Available Balance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        Row(
                          children: [
                            Text("$points pts", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16)
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 3. MENU OPTIONS
                _buildMenuOption(
                  context, 
                  icon: Icons.local_shipping, 
                  title: "Track My Orders", 
                  subtitle: "View order status and history",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientOrdersScreen())),
                ),
                
                _buildMenuOption(
                  context, 
                  icon: Icons.settings, 
                  title: "Settings", 
                  subtitle: "Account preferences",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),

                _buildMenuOption(
                  context, 
                  icon: Icons.logout, 
                  title: "Log Out", 
                  subtitle: "Sign out of your account",
                  isDestructive: true,
                  onTap: () => _signOut(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuOption(BuildContext context, {
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red[50] : Colors.blue[50],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isDestructive ? Colors.red : Colors.blue),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDestructive ? Colors.red : Colors.black)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}