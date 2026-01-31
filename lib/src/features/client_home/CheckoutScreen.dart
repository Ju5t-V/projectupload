import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/theme.dart'; 
import 'cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _addressController = TextEditingController();
  String _selectedPaymentMethod = 'Cash on Delivery'; 
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // LOGIC: Process Order
  Future<void> _placeOrder(CartProvider cart) async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a delivery address")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. INITIALIZE BATCH (Must be done before loops)
      final batch = FirebaseFirestore.instance.batch();

      // 2. Group items by Seller
      Map<String, List<Map<String, dynamic>>> ordersBySeller = {};
      Map<String, double> totalsBySeller = {};

      for (var item in cart.items) {
        String sellerId = item.ownerId; 

        // --- A. GROUPING LOGIC ---
        if (!ordersBySeller.containsKey(sellerId)) {
          ordersBySeller[sellerId] = [];
          totalsBySeller[sellerId] = 0.0;
        }

        ordersBySeller[sellerId]!.add({
          'product_id': item.productId,
          'product_name': item.name,
          'quantity': item.quantity,
          'price_each': item.price,
          'image_url': item.imageUrl,
        });

        totalsBySeller[sellerId] = (totalsBySeller[sellerId] ?? 0) + (item.price * item.quantity);

        // --- B. STOCK DEDUCTION LOGIC (ADDED) ---
        // This tells Firebase to find the product and subtract the quantity
        DocumentReference productRef = FirebaseFirestore.instance.collection('products').doc(item.productId);
        batch.update(productRef, {
          'stock': FieldValue.increment(-item.quantity) // Negative number subtracts
        });
      }

      // 3. Create Order Documents (One per Seller)
      ordersBySeller.forEach((sellerId, items) {
        DocumentReference orderRef = FirebaseFirestore.instance.collection('orders').doc();

        batch.set(orderRef, {
          'user_id': user.uid,
          'buyer_name': user.displayName ?? 'Customer',
          'seller_id': sellerId,
          'items': items,
          'total_amount': totalsBySeller[sellerId],
          'delivery_address': _addressController.text.trim(),
          'payment_method': _selectedPaymentMethod,
          'status': 'Pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      // 4. COMMIT EVERYTHING AT ONCE (Orders + Stock Updates)
      await batch.commit();

      // 5. Clear Cart & Success
      cart.clearCart();
      
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 50),
            SizedBox(height: 10),
            Text("Order Placed!"),
          ],
        ),
        content: const Text("Thank you for your purchase. You can track your order status in the orders tab."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close Dialog
              Navigator.pop(context); // Close Checkout
              Navigator.pop(context); // Close Cart (Back to Home)
            },
            child: const Text("Back to Home"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION 1: DELIVERY ADDRESS
                  const Text("Delivery Address", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Enter full address...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.location_on),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // SECTION 2: PAYMENT METHOD
                  const Text("Payment Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        RadioListTile(
                          title: const Text("Cash on Delivery (COD)"),
                          secondary: const Icon(Icons.money, color: Colors.green),
                          value: "Cash on Delivery",
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) => setState(() => _selectedPaymentMethod = value.toString()),
                        ),
                        const Divider(height: 0),
                        RadioListTile(
                          title: const Text("Online Banking / E-Wallet"),
                          secondary: const Icon(Icons.account_balance, color: Colors.blue),
                          value: "Online Banking",
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) => setState(() => _selectedPaymentMethod = value.toString()),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // SECTION 3: ORDER SUMMARY
                  const Text("Order Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Subtotal (${cart.items.length} items)"),
                            Text("RM ${cart.totalPrice.toStringAsFixed(2)}"),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Delivery Fee"),
                            Text("RM 5.00", style: TextStyle(fontWeight: FontWeight.bold)), 
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Payment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                              "RM ${(cart.totalPrice + 5.00).toStringAsFixed(2)}", 
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Spacing for bottom button
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _placeOrder(cart),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Place Order", style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ),
      ),
    );
  }
}