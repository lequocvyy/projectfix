import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projectmain/pages/CartPage.dart';
import 'package:projectmain/services/cart_service.dart';

class ProductDetailsPage extends StatefulWidget {
  final DocumentSnapshot product;
  final String userId;

  const ProductDetailsPage({super.key, required this.product, required this.userId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1;
  int userRating = 0;
  final commentController = TextEditingController();
  bool canReview = false;
  bool alreadyReviewed = false;
  bool loadingReviewStatus = true;

  @override
  void initState() {
    super.initState();
    checkReviewEligibility();
  }

  // Kiểm tra xem user đã mua sản phẩm và đã review chưa
  Future<void> checkReviewEligibility() async {
    bool bought = await hasBoughtProduct();
    bool reviewed = await hasReviewedProduct();

    setState(() {
      canReview = bought;
      alreadyReviewed = reviewed;
      loadingReviewStatus = false;
    });
  }

  // Kiểm tra user đã mua sản phẩm chưa
  Future<bool> hasBoughtProduct() async {
    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: widget.userId)
        .where('status', isEqualTo: 'Đã giao thành công') // chỉ tính đơn đã giao
        .get();

    for (var orderDoc in ordersSnapshot.docs) {
      final products = orderDoc['products'] as List<dynamic>;
      if (products.any((p) => p['productId'] == widget.product.id)) {
        return true;
      }
    }
    return false;
  }

  // Kiểm tra user đã review sản phẩm chưa
  Future<bool> hasReviewedProduct() async {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.product.id)
        .collection('reviews')
        .where('userId', isEqualTo: widget.userId)
        .get();

    return reviewsSnapshot.docs.isNotEmpty;
  }

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

            // Button thêm vào giỏ hàng
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final cartProduct = {
                      'productId': widget.product.id,
                      'name': name,
                      'price': price,
                      'quantity': quantity,
                    };

                    CartService().addProduct(cartProduct);
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

            // --- PHẦN REVIEWS ---
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text('Đánh giá sản phẩm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),

            // Form review với điều kiện
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: loadingReviewStatus
                  ? const Center(child: CircularProgressIndicator())
                  : !canReview
                  ? const Text('Bạn phải mua sản phẩm này mới được đánh giá.')
                  : alreadyReviewed
                  ? const Text('Bạn đã đánh giá sản phẩm này rồi.')
                  : Column(
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < userRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () => setState(() => userRating = index + 1),
                      );
                    }),
                  ),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Bình luận',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (userRating == 0 || commentController.text.isEmpty) return;

                      await FirebaseFirestore.instance
                          .collection('products')
                          .doc(widget.product.id)
                          .collection('reviews')
                          .add({
                        'userId': widget.userId,
                        'rating': userRating,
                        'comment': commentController.text.trim(),
                        'createdAt': Timestamp.now(),
                      });

                      setState(() {
                        userRating = 0;
                        commentController.clear();
                        alreadyReviewed = true; // update trạng thái
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã gửi đánh giá 🎉')));
                    },
                    child: const Text('Gửi đánh giá'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Hiển thị danh sách reviews
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .doc(widget.product.id)
                  .collection('reviews')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final reviews = snapshot.data!.docs;
                if (reviews.isEmpty) return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có đánh giá nào.'),
                );

                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index].data() as Map<String, dynamic>;
                    final rating = review['rating'] ?? 0;
                    final comment = review['comment'] ?? '';
                    return ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) => Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        )),
                      ),
                      title: Text(comment),
                      subtitle: Text('Đánh giá bởi: ${review['userId']}'),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
