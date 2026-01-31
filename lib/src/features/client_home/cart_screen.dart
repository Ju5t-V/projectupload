import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart'; // Ensure this path matches your project
import 'cart_provider.dart';
import 'payment_screen.dart'; // IMPORT THE FAKE PAYMENT SCREEN

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the cart for changes
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart"),
        centerTitle: true,
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Your cart is empty"),
                ],
              ),
            )
          : Column(
              children: [
                // 1. LIST OF ITEMS
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Image Placeholder
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.fastfood, color: Colors.grey),
                                // Note: If using real images, verify your Product model handles Base64 or Assets
                                // child: Image.asset(item.product.imageUrl, fit: BoxFit.cover),
                              ),
                              const SizedBox(width: 16),

                              // Name & Price
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    Text(
                                        "RM ${item.product.price.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                            color: kPrimaryColor)),
                                  ],
                                ),
                              ),

                              // +/- Buttons
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle,
                                        color: Colors.red),
                                    onPressed: () =>
                                        cart.removeOrDecrease(item.product),
                                  ),
                                  Text("${item.quantity}",
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle,
                                        color: Colors.green),
                                    onPressed: () =>
                                        cart.addToCart(item.product),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 2. TOTAL & CHECKOUT BUTTON
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 2)
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("RM ${cart.totalPrice.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // THE PAYMENT BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor),
                          onPressed: () {
                            if (cart.items.isEmpty) return;

                            // A. Prepare Data for Firestore
                            List<Map<String, dynamic>> cartItemsForOrder = cart.items.map((item) {
                              return {
                                'product_name': item.product.name,
                                'quantity': item.quantity,
                                'price': item.product.price,
                                // IMPORTANT: This ensures the specific seller gets the order
                                'owner_id': item.product.ownerId, 
                                'image_url': item.product.imageUrl,
                              };
                            }).toList();

                            // B. Go to Payment Simulation
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentSimulationScreen(
                                    totalAmount: cart.totalPrice,
                                    cartItems: cartItemsForOrder
                                ),
                              ),
                            );
                          },
                          child: const Text("Proceed to Payment",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18)),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}