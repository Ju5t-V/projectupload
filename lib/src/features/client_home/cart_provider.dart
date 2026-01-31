import 'package:flutter/material.dart';
import 'product_model.dart';

// A simple class to hold the Product + Quantity
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
  
  // Helper getters to access product properties easily
  String get ownerId => product.ownerId;
  String get productId => product.id;
  String get name => product.name;
  double get price => product.price;
  String get imageUrl => product.imageUrl;
}

class CartProvider extends ChangeNotifier {
  // The private list of items in the cart
  final List<CartItem> _items = [];

  // A way for screens to read the list (but not modify it directly)
  List<CartItem> get items => _items;

  // Calculate the total price automatically
  double get totalPrice {
    double total = 0;
    for (var item in _items) {
      total += item.product.price * item.quantity;
    }
    return total;
  }

  // FUNCTION: Add item to cart
  void addToCart(Product product) {
    // Check if item is already in cart
    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      // If yes, just increase quantity
      _items[index].quantity++;
    } else {
      // If no, add it as a new item
      _items.add(CartItem(product: product));
    }
    
    // IMPORTANT: Tell the UI to update!
    notifyListeners();
  }

  // FUNCTION: Remove or Decrease item
  void removeOrDecrease(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // FUNCTION: Clear cart (after checkout)
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}