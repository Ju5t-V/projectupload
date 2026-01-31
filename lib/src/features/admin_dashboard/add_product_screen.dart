import 'dart:io';
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  File? _selectedImage; 
  final _picker = ImagePicker();

  // 1. ADDED "Medicine" TO THE LIST
  String _selectedCategory = 'Snack'; 
  final List<String> _categories = ['Snack', 'Pastry', 'Candy', 'Drinks', 'Medicine'];
  
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50, 
      maxWidth: 600,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitProduct() async {
    if (_nameController.text.isEmpty || 
        _priceController.text.isEmpty || 
        _stockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all text fields")));
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please pick an image")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final ownerId = user?.uid ?? 'unknown';

      // Convert Image
      final bytes = await _selectedImage!.readAsBytes();
      final String base64Image = base64Encode(bytes);
      final String imageString = "data:image/jpeg;base64,$base64Image"; 

      // 2. DETERMINE STATUS BASED ON CATEGORY
      // If it is 'Medicine', it needs approval ('pending').
      // Otherwise, it is auto-approved ('approved').
      String productStatus = (_selectedCategory == 'Medicine') ? 'pending' : 'approved';

      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'stock': int.parse(_stockController.text.trim()),
        'category': _selectedCategory,
        'image_url': imageString,
        'created_at': FieldValue.serverTimestamp(),
        'status': productStatus, // <--- SAVING THE DYNAMIC STATUS
        'owner_id': ownerId,
      });

      if (!mounted) return;

      // 3. SHOW DIFFERENT MESSAGES BASED ON STATUS
      if (productStatus == 'pending') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Submission Successful! Pending Mentor Approval."),
            backgroundColor: Colors.orange,
          )
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product Added to Shop!"),
            backgroundColor: Colors.green,
          )
        );
      }
      
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                          Text("Tap to pick image", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price (RM)", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Initial Stock", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            
            // DROPDOWN CATEGORY
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            
            // HELPER TEXT FOR MEDICINE
            if (_selectedCategory == 'Medicine')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      "Restricted Item: Requires Mentor Approval",
                      style: TextStyle(color: Colors.orange[800], fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitProduct,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit Product"),
              ),
            )
          ],
        ),
      ),
    );
  }
}