import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'points_history_screen.dart'; 
import '../auth/login_screen.dart'; // <--- MAKE SURE THIS IMPORT IS CORRECT

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  // --- LOGOUT FUNCTION ---
  void _handleLogout(BuildContext context) async {
    // 1. Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    // 2. Navigate to Login Screen and remove all previous history
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Logo Title
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront, color: Colors.black),
            const SizedBox(width: 8),
            const Text("KEDAI KITA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          // 1. Points Counter (Existing)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
            builder: (context, snapshot) {
              int points = 0;
              if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data != null && data.containsKey('points')) {
                  points = data['points'];
                }
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PointsHistoryScreen(currentPoints: points)));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0), // Reduced padding slightly
                  child: Row(
                    children: [
                      Text("$points pts", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      const Icon(Icons.chevron_right, color: Colors.black),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. NEW LOGOUT BUTTON
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red), // Red color for visibility
            tooltip: "Log Out",
            onPressed: () => _handleLogout(context),
          ),
          
          const SizedBox(width: 8), // Small spacing at the end
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // 1. ORANGE QR CODE CARD
            _buildQRCard(user?.uid ?? "Unknown"),

            const SizedBox(height: 25),

            // 2. REWARDS SECTION TITLE
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text("Rewards", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            
            const SizedBox(height: 15),

            // 3. HORIZONTAL REWARDS LIST
            SizedBox(
              height: 240, 
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildRewardItem("Nabati Milk Creamy", 500, "assets/images/nabati.png", Colors.blue[50]!),
                  _buildRewardItem("Choco Albab", 10000, "assets/images/choco.png", Colors.pink[50]!),
                  _buildRewardItem("Nescafe Can", 300, "assets/images/nescafe.png", Colors.brown[50]!),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS (Unchanged) ---

  Widget _buildQRCard(String uid) {
    final displayId = uid.length > 5 ? "AI${uid.substring(0, 5).toUpperCase()}" : "AI12345";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      height: 380, 
      decoration: BoxDecoration(
        color: Colors.orange[400], 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.info_outline, color: Colors.black54),
            ),
          ),
          Container(
            width: 200,
            height: 200,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_2, size: 130, color: Colors.black),
                const SizedBox(height: 5),
                Text(
                  displayId,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Scan code to collect points",
            style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(String title, int cost, String imagePath, Color bgColor) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(
                  imagePath, 
                  fit: BoxFit.contain,
                  errorBuilder: (c,o,s) => const Icon(Icons.card_giftcard, size: 50, color: Colors.grey),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text("$cost pts", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}