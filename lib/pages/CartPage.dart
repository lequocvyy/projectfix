// CartPage.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/cart_service.dart';
import 'checkout_page.dart';

class CartPage extends StatelessWidget {
  final String userId;
  const CartPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final cartService = CartService();
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: cartService.cartNotifier,
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return const Center(child: Text('Chưa có sản phẩm trong giỏ'));
          }

          int totalPrice = cart.fold<int>(
            0,
                (sum, item) {
              int price = (item['price'] ?? 0) is num ? (item['price'] as num).toInt() : 0;
              int quantity = (item['quantity'] ?? 0) is num ? (item['quantity'] as num).toInt() : 0;
              return sum + price * quantity;
            },
          );

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.length,
                  itemBuilder: (context, index) {
                    final p = cart[index];
                    int quantity = (p['quantity'] as num).toInt();
                    final price = (p['price'] as num).toInt();

                    return ListTile(
                      title: Text(p['name']),
                      subtitle: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              if (quantity > 1) {
                                cartService.updateQuantity(p['productId'], quantity - 1);
                              } else {
                                cartService.removeProduct(p['productId']);
                              }
                            },
                          ),
                          Text('$quantity'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              cartService.updateQuantity(p['productId'], quantity + 1);
                            },
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(currency.format(price * quantity)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              cartService.removeProduct(p['productId']);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Tổng: ${currency.format(totalPrice)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutPage(
                                userId: userId,
                                cartProducts: List.from(cart),
                              ),
                            ),
                          );
                        },
                        child: const Text('Thanh toán'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
