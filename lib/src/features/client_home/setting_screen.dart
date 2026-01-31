import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true; // State for the toggle

  // 1. LOGIC: EDIT PROFILE (Update Name)
  void _showEditProfileDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nameController = TextEditingController(text: user?.displayName ?? "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Profile"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                // Update Firebase Auth
                await user?.updateDisplayName(nameController.text.trim());
                
                // Update Firestore
                await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                  'name': nameController.text.trim()
                });

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!")));
                }
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  // 2. LOGIC: CHANGE PASSWORD (Send Reset Email)
  void _changePassword(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Password Reset"),
              content: Text("We have sent a password reset link to ${user.email}. Please check your inbox."),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // 3. LOGIC: LANGUAGE SELECTOR
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Select Language"),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx), child: const Text("English (Default)")),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx), child: const Text("Bahasa Melayu")),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx), child: const Text("Mandarin")),
        ],
      ),
    );
  }

  // 4. LOGIC: HELP / ABOUT
  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          _buildSectionHeader("Account"),
          _buildSettingTile(
            context, 
            Icons.person, 
            "Edit Profile", 
            onTap: () => _showEditProfileDialog(context)
          ),
          _buildSettingTile(
            context, 
            Icons.lock, 
            "Change Password", 
            onTap: () => _changePassword(context)
          ),
          
          _buildSectionHeader("Preferences"),
          SwitchListTile(
            secondary: const Icon(Icons.notifications, color: Colors.blueGrey),
            title: const Text("Notifications"),
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Notifications turned ${val ? 'ON' : 'OFF'}"), duration: const Duration(milliseconds: 500)),
              );
            },
          ),
          _buildSettingTile(
            context, 
            Icons.language, 
            "Language", 
            onTap: () => _showLanguageDialog(context)
          ),
          
          _buildSectionHeader("Support"),
          _buildSettingTile(
            context, 
            Icons.help, 
            "Help & Support", 
            onTap: () => _showInfoDialog(context, "Help", "For support, contact us at:\nsupport@kedaikita.com\n+60 12-345 6789")
          ),
          _buildSettingTile(
            context, 
            Icons.info, 
            "About App", 
            onTap: () => _showInfoDialog(context, "About KedaiKita", "KedaiKita v1.0.0\n\nConnecting local sellers with loyal customers.\n\n© 2026 KedaiKita Inc.")
          ),
          
          const Padding(
            padding: EdgeInsets.all(30),
            child: Text("Version 1.0.0", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey, 
          fontSize: 13, 
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2
        ),
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, IconData icon, String title, {required VoidCallback onTap}) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}