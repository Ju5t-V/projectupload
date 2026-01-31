class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final int stock;
  final String ownerId; // Added to track which seller owns this product

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.stock,
    required this.ownerId,
  });

  // A helper to read data from Firebase
  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'General',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['image_url'] ?? '',
      stock: data['stock'] ?? 0,
      ownerId: data['owner_id'] ?? '', // Read owner_id from Firebase document
    );
  }

  // Optional: Helper to convert Product to Map (useful for updates)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'image_url': imageUrl,
      'stock': stock,
      'owner_id': ownerId,
    };
  }
}