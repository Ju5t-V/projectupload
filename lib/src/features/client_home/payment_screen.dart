import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../client_home/client_orders_screen.dart'; // To navigate after success

class PaymentSimulationScreen extends StatefulWidget {
  final double totalAmount;
  final List<Map<String, dynamic>> cartItems;

  const PaymentSimulationScreen({
    super.key,
    required this.totalAmount,
    required this.cartItems,
  });

  @override
  State<PaymentSimulationScreen> createState() => _PaymentSimulationScreenState();
}

class _PaymentSimulationScreenState extends State<PaymentSimulationScreen> {
  // Controllers for Card Input
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  
  // Controller for OTP
  final _otpController = TextEditingController();

  bool _isLoading = false;

  // --- STEP 1: VALIDATE CARD & SHOW OTP ---
  void _initiatePayment() async {
    if (_cardNumberController.text.isEmpty || 
        _expiryController.text.isEmpty || 
        _cvvController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in card details")));
      return;
    }

    setState(() => _isLoading = true);

    // 1. Simulate "Connecting to Bank"
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (!mounted) return;

    // 2. Show the Fake Bank OTP Dialog
    _showBankOTPDialog();
  }

  // --- STEP 2: THE FAKE BANK OTP DIALOG ---
  void _showBankOTPDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must enter OTP or cancel
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Column(
            children: [
              const Icon(Icons.lock, color: Colors.blue, size: 40),
              const SizedBox(height: 10),
              const Text("Secure Bank Verification", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Divider(color: Colors.grey[300]),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Merchant: KedaiKita App", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text("Amount: RM ${widget.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text("Enter the OTP sent to your mobile ending in **** 8888"),
              const SizedBox(height: 10),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "One-Time Password (OTP)",
                  border: OutlineInputBorder(),
                  hintText: "Try 123456",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Cancelled"), backgroundColor: Colors.red));
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // 3. Verify OTP (Any code works for simulation, or force '123456')
                if (_otpController.text.length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid OTP")));
                } else {
                  Navigator.pop(context); // Close dialog
                  _finalizeOrder(); // PROCEED TO SAVE ORDER
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  // --- STEP 3: SAVE TO FIRESTORE (REAL BACKEND) ---
  Future<void> _finalizeOrder() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Create the Order in Firestore
      // IMPORTANT: We need to assign the 'seller_id' for each item if possible.
      // For simplicity, we assume the cart items already have 'owner_id' inside them from your product data.
      
      // Note: If you have items from multiple sellers, you usually split orders. 
      // For this simulation, we'll assume 1 seller or save the first seller found.
      String sellerId = widget.cartItems.isNotEmpty ? widget.cartItems[0]['owner_id'] : '';

      await FirebaseFirestore.instance.collection('orders').add({
        'user_id': user.uid,
        'user_email': user.email,
        'seller_id': sellerId, // Needed for Admin Dashboard to see it
        'items': widget.cartItems,
        'total_amount': widget.totalAmount,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending', // Initial status
      });

      // 2. Simulate Success Delay
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // 3. Navigate to Order History
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Successful!"), backgroundColor: Colors.green));
      
      // Clear navigation stack and go to Orders
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientOrdersScreen()));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Secure Checkout")),
      body: _isLoading 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Processing Payment...", style: TextStyle(fontSize: 16)),
                  Text("Do not close this app", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Column(
                      children: [
                        const Text("Total Payable Amount"),
                        Text(
                          "RM ${widget.totalAmount.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Card Form
                  const Text("Enter Card Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 15),
                  
                  TextField(
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    decoration: const InputDecoration(
                      labelText: "Card Number",
                      prefixIcon: Icon(Icons.credit_card),
                      border: OutlineInputBorder(),
                      counterText: "",
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expiryController,
                          keyboardType: TextInputType.datetime,
                          decoration: const InputDecoration(
                            labelText: "Expiry (MM/YY)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 3,
                          decoration: const InputDecoration(
                            labelText: "CVV",
                            border: OutlineInputBorder(),
                            counterText: "",
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _initiatePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Pay Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  const Center(child: Icon(Icons.lock_outline, size: 16, color: Colors.grey)),
                  const Center(child: Text("Payments are secured by 256-bit encryption", style: TextStyle(color: Colors.grey, fontSize: 10))),
                ],
              ),
            ),
    );
  }
}