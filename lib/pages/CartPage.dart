import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/cart_service.dart';
import 'checkout_page.dart';

class CartPage extends StatelessWidget {
  final String userId;
  const CartPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final cart = CartService().cart;
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: cart.isEmpty
          ? const Center(child: Text('Chưa có sản phẩm trong giỏ'))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...cart.map((p) {
            final price = (p['price'] as num).toInt();
            final quantity = (p['quantity'] as num).toInt();
            return ListTile(
              title: Text(p['name']),
              subtitle: Text('Số lượng: $quantity'),
              trailing: Text(currency.format(price * quantity)),
            );
          }),
          const SizedBox(height: 20),
          ElevatedButton(
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
        ],
      ),
    );
  }
}
