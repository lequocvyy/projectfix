import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projectmain/pages/CartPage.dart';
import 'package:projectmain/pages/product_details.dart';
import 'package:projectmain/pages/profile_page.dart';
import 'package:projectmain/services/cart_service.dart';
import '../authentication/login_page.dart';
import 'package:intl/intl.dart';

class ProductPageWrapper extends StatelessWidget {
  final String uid;
  final bool isAdminUser;

  const ProductPageWrapper({super.key, required this.uid, required this.isAdminUser});

  @override
  Widget build(BuildContext context) {
    return ProductPage(uid: uid, isAdminUser: isAdminUser);
  }
}

class ProductPage extends StatelessWidget {
  final String uid;
  final bool isAdminUser;

  const ProductPage({super.key, required this.uid, required this.isAdminUser});

  // Hàm format giá có dấu phẩy
  String formatPrice(int price) {
    final formatter = NumberFormat('#,###');
    return formatter.format(price);
  }

  Future<void> addVoucher(BuildContext context) async {
    final codeController = TextEditingController();
    final discountController = TextEditingController();
    DateTime? expiryDate;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Tạo Voucher"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: "Mã voucher"),
              ),
              TextField(
                controller: discountController,
                decoration: const InputDecoration(labelText: "Giảm giá (%)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      expiryDate == null
                          ? "Chưa chọn hạn"
                          : "Hết hạn: ${DateFormat('dd/MM/yyyy').format(expiryDate!)}",
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => expiryDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (codeController.text.isEmpty ||
                    discountController.text.isEmpty ||
                    expiryDate == null) {
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('VoucherCoupon')
                    .add({
                  "Code": codeController.text.trim(),
                  "discountPercent":
                  int.tryParse(discountController.text) ?? 0,
                  "expiryDate": Timestamp.fromDate(expiryDate!),
                  "isActive": true,
                  "createdAt": Timestamp.now(),
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tạo voucher thành công 🎉")),
                );
              },
              child: const Text("Tạo"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addProduct(BuildContext context) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final imageUrlController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm sản phẩm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên sản phẩm')),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Giá'), keyboardType: TextInputType.number),
            TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Kho'), keyboardType: TextInputType.number),
            TextField(controller: imageUrlController, decoration: const InputDecoration(labelText: 'Link ảnh')),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Mô tả sản phẩm')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('products').add({
                'name': nameController.text,
                'price': int.tryParse(priceController.text) ?? 0,
                'stock': int.tryParse(stockController.text) ?? 0,
                'imageUrl': imageUrlController.text,
                'description': descriptionController.text,
              });
              Navigator.pop(context);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> editProduct(BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name']);

    // Lấy giá gốc và format có dấu phẩy
    final priceController = TextEditingController(
        text: NumberFormat('#,###').format(data['price'] ?? 0));

    final stockController = TextEditingController(text: data['stock'].toString());
    final imageUrlController = TextEditingController(text: data['imageUrl']);
    final descriptionController = TextEditingController(text: data['description']);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sửa sản phẩm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên sản phẩm')),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Giá'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                // Xoá dấu phẩy khi nhập, rồi format lại
                String digits = value.replaceAll(',', '');
                if (digits.isEmpty) digits = '0';
                int val = int.tryParse(digits) ?? 0;
                priceController.value = TextEditingValue(
                  text: NumberFormat('#,###').format(val),
                  selection: TextSelection.collapsed(offset: NumberFormat('#,###').format(val).length),
                );
              },
            ),
            TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Kho'), keyboardType: TextInputType.number),
            TextField(controller: imageUrlController, decoration: const InputDecoration(labelText: 'Link ảnh')),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Mô tả sản phẩm')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              // Lấy giá gốc (xoá dấu phẩy) trước khi lưu
              int price = int.tryParse(priceController.text.replaceAll(',', '')) ?? 0;

              await FirebaseFirestore.instance.collection('products').doc(doc.id).update({
                'name': nameController.text,
                'price': price,
                'stock': int.tryParse(stockController.text) ?? 0,
                'imageUrl': imageUrlController.text,
                'description': descriptionController.text,
              });
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách sản phẩm'),
        actions: [
          if (isAdminUser)

          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userId: uid),
                  ),
                );
              } else if (value == 'logout') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 18),
                    SizedBox(width: 8),
                    Text('Hồ sơ'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            onSelected: (value) {
              if (value == 'product') addProduct(context);
              if (value == 'voucher') addVoucher(context);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'product',
                child: Text('Thêm sản phẩm'),
              ),
              PopupMenuItem(
                value: 'voucher',
                child: Text('Tạo voucher'),
              ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartPage(userId: uid),
                    ),
                  );
                },
              ),
              if (CartService().cart.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      CartService().cart.fold<int>(0, (sum, p) => sum + (p['quantity'] as int)).toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có sản phẩm'));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: Image.network(data['imageUrl'] ?? '', width: 60, height: 60),
                  title: Text(data['name'] ?? ''),
                  subtitle: Text('Giá: ${formatPrice(data['price'] ?? 0)} đ | Kho: ${data['stock']}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsPage(product: doc, userId: uid),
                      ),
                    );
                  },
                  trailing: isAdminUser
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => editProduct(context, doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('products').doc(doc.id).delete();
                        },
                      ),
                    ],
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
