import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projectmain/pages/CartPage.dart';

import 'package:projectmain/pages/checkout_page.dart';
import 'package:projectmain/services/cart_service.dart';

class ProductDetailsPage extends StatefulWidget {
  final DocumentSnapshot product;
  final String userId; // Thêm dòng này


  const ProductDetailsPage({super.key, required this.product, required this.userId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final data = widget.product.data() as Map<String, dynamic>;
    final name = data['name'] ?? '';
    final price = data['price'] ?? 0;
    final imageUrl = data['imageUrl'] ?? '';
    final description = data['description'] ?? '';
    final stock = data['stock'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey[200],
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 100),
              ),
            ),
            const SizedBox(height: 16),

            // Tên & Giá
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Giá: $price đ', style: const TextStyle(fontSize: 20, color: Colors.redAccent)),
            ),

            // Kho
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text('Số lượng còn: $stock', style: const TextStyle(fontSize: 16)),
            ),

            const Divider(),

            // Mô tả sản phẩm
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(description, style: const TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 16),

            // Chọn số lượng
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Số lượng:', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (quantity > 1) setState(() => quantity--);
                    },
                  ),
                  Text(quantity.toString(), style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (quantity < stock) setState(() => quantity++);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Button đặt hàng
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: // ProductDetailsPage.dart
                ElevatedButton.icon(
                  onPressed: () {
                    final cartProduct = {
                      'productId': widget.product.id,
                      'name': name,
                      'price': price,
                      'quantity': quantity,
                    };

                    CartService().addProduct(cartProduct); // thêm vào giỏ hàng
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã thêm vào giỏ hàng'))
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Thêm vào giỏ hàng', style: TextStyle(fontSize: 18)),
                ),


              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
