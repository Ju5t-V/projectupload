import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';      // REQUIRED for account creation
import 'package:cloud_firestore/cloud_firestore.dart';  // REQUIRED to save data
import '../auth/login_screen.dart'; // Ensure this matches your login file name

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Role Selection
  String _selectedRole = 'Customer'; 
  final List<String> _roles = ['Customer', 'Seller'];

  bool _isLoading = false; // Controls the loading spinner

  Future<void> _handleSignUp() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String role = _selectedRole; 

    // 1. Basic Validation
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. ACTUAL FIREBASE CREATION (This talks to the internet)
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Logic: Sellers are 'Pending', Customers are 'Approved'
      // Note: We check for 'Seller' (Capital S) to match the dropdown list
      String status = (role == 'Seller') ? 'Pending' : 'Approved';

      // 4. SAVE TO DATABASE
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'role': role,      
        'status': status,  
        'created_at': FieldValue.serverTimestamp(),
        'points': 0,       
        'total_sales': 0, 
        'mentor_id': '',   // Empty until assigned
      });

      if (!mounted) return;

      // 5. SUCCESS MESSAGE
      String message = (role == 'Seller') 
          ? "Account created! Waiting for Mentor approval." 
          : "Account created successfully!";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));

      // 6. NAVIGATE TO LOGIN
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen())
      );

    } on FirebaseAuthException catch (e) {
      // Handle Firebase specific errors (e.g., email already in use)
      String errorMessage = e.message ?? "An error occurred";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.person_add, size: 80, color: Colors.blue),
            const SizedBox(height: 20),

            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 15),

            // Email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 15),

            // Password
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 15),

            // Role Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: "I want to register as a...",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
              ),
              items: _roles.map((String role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRole = newValue!;
                });
              },
            ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Create Account", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}