import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../../constants/theme.dart';
import 'cart_screen.dart';
import 'product_model.dart';
import 'cart_provider.dart';
import '../client_home/profile_screen.dart'; // <--- UPDATED IMPORT
import '../auth/login_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = ""; 
  final TextEditingController _searchController = TextEditingController();

  // Helper to check if user is guest
  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(imagePath, fit: BoxFit.cover, errorBuilder: (c,o,s) => const Icon(Icons.error));
    } else if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.split(',').last; 
        return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
      } catch (e) {
        return const Icon(Icons.broken_image);
      }
    } else {
      return Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (c,o,s) => const Icon(Icons.fastfood, color: Colors.grey));
    }
  }

  // --- LOGIC: FORCE LOGIN ---
  void _requireLogin(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Login Required"),
        content: const Text("You need to log in to shop."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              // Go to Login Screen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Log In Now"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("KedaiKita", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
           IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              if (_isGuest) {
                _requireLogin(context);
              } else {
                // <--- UPDATED NAVIGATION: Go to Profile Screen --->
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              }
            },
          ),
          
          // POINTS DISPLAY (Hidden for Guests)
          if (!_isGuest)
             StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
              builder: (context, snapshot) {
                int points = 0;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  points = data?['points'] ?? 0;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 10, top: 15),
                  child: Text("$points pts", style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),

          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
               if (_isGuest) {
                 _requireLogin(context);
               } else {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
               }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // 1. SEARCH BAR
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // 2. CATEGORY SELECTOR
          _buildCategorySection(),

          // 3. PRODUCT GRID
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading products"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final products = docs.map((doc) => 
                  Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)
                ).toList();

                final filteredProducts = products.where((p) {
                  final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
                  final matchesSearch = p.name.toLowerCase().contains(_searchQuery);
                  return matchesCategory && matchesSearch;
                }).toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 50, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text("No items found."),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(filteredProducts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = ['All', 'Snack', 'Pastry', 'Candy', 'Drinks'];
    return SizedBox(
      height: 60,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              selectedColor: kPrimaryColor,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
              onSelected: (selected) {
                setState(() => _selectedCategory = cat);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isOutOfStock = product.stock <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE SECTION
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: _buildImage(product.imageUrl),
                    ),
                  ),
                  if (isOutOfStock)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: Colors.black54,
                        child: const Text("SOLD OUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                ],
              ),
            ),
          ),
          
          // DETAILS
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  product.category,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "RM ${product.price.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
                    ),
                    
                    isOutOfStock
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Text("No Stock", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    : InkWell(
                      onTap: () {
                          // --- SAFETY CHECK FOR GUESTS ---
                          if (_isGuest) {
                            _requireLogin(context);
                            return; // Stop here
                          }

                          final cart = Provider.of<CartProvider>(context, listen: false);
                          cart.addToCart(product);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Added ${product.name} to cart"),
                              duration: const Duration(seconds: 1),
                            )
                          );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: kPrimaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}