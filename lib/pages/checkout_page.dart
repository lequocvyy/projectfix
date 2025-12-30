import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:projectmain/services/cart_service.dart';

class CheckoutPage extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> cartProducts;

  const CheckoutPage({super.key, required this.userId, required this.cartProducts});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<Map<String, dynamic>> addresses = [];
  Map<String, dynamic>? selectedAddress;
  List<Map<String, dynamic>> newAddresses = []; // lưu tạm địa chỉ mới
  String voucherCode = '';
  int discountAmount = 0;
  int shippingFee = 0;
  String shippingMethod = 'Mặc định';
  final noteController = TextEditingController();
  final fullNameController = TextEditingController(); // thêm fullName cho shippingAddress

  int get totalPrice {
    int total = 0;
    for (var p in widget.cartProducts) {
      int price = (p['price'] ?? 0) is num ? (p['price'] as num).toInt() : 0;
      int quantity = (p['quantity'] ?? 1) is num ? (p['quantity'] as num).toInt() : 1;
      total += price * quantity;
    }
    return total;
  }

  int get finalPrice => totalPrice - discountAmount + shippingFee;

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    final addressSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('Address')
        .get();

    List<Map<String, dynamic>> userAddresses = [];

    for (var addrDoc in addressSnapshot.docs) {
      final data = addrDoc.data();
      userAddresses.add({
        'id': addrDoc.id,
        'fullName': data['Họ và tên'] ?? '',
        'address': data['Địa chỉ'] ?? '',
        'phone': data['Số điện thoại'] ?? '',
        'note': data['Ghi chú'] ?? '',
      });
    }

    setState(() {
      addresses = userAddresses;
      if (addresses.isNotEmpty) selectedAddress = addresses[0];
    });
  }

  Future<void> applyVoucher(int totalPrice) async {
    if (voucherCode.isEmpty) return;

    final code = voucherCode.trim();

    final querySnapshot = await FirebaseFirestore.instance
        .collection('VoucherCoupon')
        .where('Code', isEqualTo: code)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      setState(() => discountAmount = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã voucher không hợp lệ ❌')),
      );
      return;
    }

    final data = querySnapshot.docs.first.data();

    // ✅ Check hạn sử dụng (nếu có)
    if (data.containsKey('expiryDate')) {
      final expiry = (data['expiryDate'] as Timestamp).toDate();
      if (expiry.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voucher đã hết hạn ⏰')),
        );
        return;
      }
    }

    final int discountPercent = data['discountPercent'] ?? 0;

    setState(() {
      discountAmount = (totalPrice * discountPercent / 100).round();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Giảm $discountPercent% thành công ✅')),
    );
  }

  Future<void> placeOrder() async {
    if (widget.userId.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Lỗi: userId trống')));
      return;
    }

    if (selectedAddress == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vui lòng chọn địa chỉ giao hàng')));
      return;
    }

    try {
      // 🔹 Lưu các địa chỉ mới vào Firestore trước
      for (var addr in newAddresses) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('Address')
            .add({
          'Họ và tên': addr['fullName'] ?? '',
          'Địa chỉ': addr['address'] ?? '',
          'Số điện thoại': addr['phone'] ?? '',
          'Ghi chú': addr['note'] ?? '',
        });
      }

      // 🔹 Chuẩn hóa shippingAddress
      final shippingMap = {
        'fullName': selectedAddress!['fullName'] ?? '',
        'address': selectedAddress!['address'] ?? '',
        'phone': selectedAddress!['phone'] ?? '',
        'note': selectedAddress!['note'] ?? '',
      };

      // 🔹 Chuẩn hóa products
      final productsList = widget.cartProducts.map((p) {
        return {
          'productId': p['productId'] ?? '',
          'name': p['name'] ?? '',
          'price': (p['price'] ?? 0) is num ? (p['price'] as num).toInt() : 0,
          'quantity': (p['quantity'] ?? 1) is num ? (p['quantity'] as num).toInt() : 1,
        };
      }).toList();

      // 🔹 Firestore tự sinh ID
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();

      await orderRef.set({
        'orderId': orderRef.id,
        'userId': widget.userId,
        'products': productsList,
        'shippingAddress': shippingMap,
        'totalPrice': totalPrice,
        'discountCode': voucherCode,
        'discountAmount': discountAmount,
        'shippingFee': shippingFee,
        'finalPrice': finalPrice,
        'orderDate': Timestamp.now(),
        'deliveryDate': Timestamp.fromDate(
          shippingMethod == 'Nhanh'
              ? DateTime.now().add(const Duration(hours: 24))
              : DateTime.now().add(const Duration(hours: 72)),
        ),
        'status': 'Đang xử lý',
        'note': noteController.text,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đặt hàng thành công')));
      // 🔹 Giảm số lượng kho sau khi đặt hàng thành công
      for (var p in widget.cartProducts) {
        final productRef = FirebaseFirestore.instance.collection('products').doc(p['productId']);
        final productSnapshot = await productRef.get();
        if (productSnapshot.exists) {
          final currentStock = (productSnapshot.data()!['stock'] ?? 0) as int;
          final newStock = currentStock - (p['quantity'] ?? 1);
          await productRef.update({'stock': newStock < 0 ? 0 : newStock});
        }
      }
      CartService().clear();
      Future.delayed(const Duration(seconds: 5), () {
        orderRef.update({'status': 'Đang chờ vận chuyển'});
      });
      Future.delayed(const Duration(seconds: 13), () {
        orderRef.update({'status': 'Chờ vận chuyển'});
      });
      Future.delayed(const Duration(seconds: 20), () {
        orderRef.update({'status': 'Đã giao thành công'});
      });
      Navigator.pop(context);
    } catch (e) {
      print('Lỗi khi lưu order: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đặt hàng thất bại, thử lại')));
    }
  }
  Future<void> addAddressDialog() async {
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final noteController = TextEditingController();
    final fullNameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm địa chỉ mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: fullNameController, decoration: const InputDecoration(labelText: 'Họ và tên')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Địa chỉ')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Số điện thoại')),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Ghi chú')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (addressController.text.trim().isEmpty || fullNameController.text.trim().isEmpty) return;

              final newAddr = {
                'fullName': fullNameController.text.trim(),
                'address': addressController.text.trim(),
                'phone': phoneController.text.trim(),
                'note': noteController.text.trim(),
              };

              setState(() {
                addresses.add(newAddr);
                selectedAddress = newAddr;
                newAddresses.add(newAddr);
              });

              Navigator.pop(context);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Địa chỉ giao hàng:', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton(onPressed: addAddressDialog, child: const Text('Thêm địa chỉ mới')),
              ],
            ),
            if (addresses.isEmpty)
              const Text('Chưa có địa chỉ nào')
            else
              DropdownButton<Map<String, dynamic>>(
                value: selectedAddress,
                isExpanded: true,
                items: addresses.map((addr) {
                  return DropdownMenuItem(
                    value: addr,
                    child: Text('${addr['fullName']} - ${addr['address']} - ${addr['phone']}'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedAddress = val),
              ),
            const SizedBox(height: 20),
            const Text('Sản phẩm:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...widget.cartProducts.map((p) {
              final price = ((p['price'] ?? 0) as num).toInt();
              final quantity = ((p['quantity'] ?? 1) as num).toInt();
              return ListTile(
                title: Text(p['name']),
                subtitle: Text('Số lượng: $quantity'),
                trailing: Text(currency.format(price * quantity)),
              );
            }),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Mã voucher'),
                    onChanged: (val) => voucherCode = val,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    applyVoucher(totalPrice);
                  },
                  child: const Text("Áp dụng voucher"),
                )

              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
            ),
            const SizedBox(height: 20),
            const Text('Phương thức vận chuyển:', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile(
              title: const Text('Nhanh (24h) +15.000 ₫'),
              value: 'Nhanh',
              groupValue: shippingMethod,
              onChanged: (val) {
                setState(() {
                  shippingMethod = val.toString();
                  shippingFee = 15000;
                });
              },
            ),
            RadioListTile(
              title: const Text('Mặc định (72h)'),
              value: 'Mặc định',
              groupValue: shippingMethod,
              onChanged: (val) {
                setState(() {
                  shippingMethod = val.toString();
                  shippingFee = 0;
                });
              },
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng giá: ${currency.format(totalPrice)}'),
                    Text('Voucher giảm: -${currency.format(discountAmount)}'),
                    Text('Phí vận chuyển: ${currency.format(shippingFee)}'),
                    Text('Tổng thanh toán: ${currency.format(finalPrice)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: placeOrder,
                child: const Text('Đặt hàng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
