import 'package:flutter/material.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final ValueNotifier<List<Map<String, dynamic>>> cartNotifier = ValueNotifier([]);

  List<Map<String, dynamic>> get cart => cartNotifier.value;

  void addProduct(Map<String, dynamic> product) {
    final index = cart.indexWhere((p) => p['productId'] == product['productId']);
    if (index >= 0) {
      cart[index]['quantity'] += product['quantity'];
    } else {
      cart.add(product);
    }
    cartNotifier.value = List.from(cart); // notify listeners
  }

  void removeProduct(String productId) {
    cart.removeWhere((p) => p['productId'] == productId);
    cartNotifier.value = List.from(cart);
  }

  void updateQuantity(String productId, int quantity) {
    final index = cart.indexWhere((p) => p['productId'] == productId);
    if (index >= 0) cart[index]['quantity'] = quantity;
    cartNotifier.value = List.from(cart);
  }

  void clear() {
    cart.clear();
    cartNotifier.value = [];
  }
}
