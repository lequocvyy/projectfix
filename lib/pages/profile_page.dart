import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  final String userId; // UID user hiện tại
  const ProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final addressColRef = userDocRef.collection('Address');
    final ordersColRef = FirebaseFirestore.instance.collection('orders').where('userId', isEqualTo: userId);

    return Scaffold(
      appBar: AppBar(title: const Text('Trang cá nhân')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Thông tin cơ bản
            StreamBuilder<DocumentSnapshot>(
              stream: userDocRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final data = snapshot.data!.data() as Map<String, dynamic>;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Họ tên: ${data['fullName'] ?? ""}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Email: ${data['email'] ?? ""}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Số điện thoại: ${data['phone'] ?? ""}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // 🔹 Danh sách Address
            const Text('Địa chỉ:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: addressColRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final addresses = snapshot.data!.docs;

                if (addresses.isEmpty) return const Text('Chưa có địa chỉ nào.');

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final addr = addresses[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        title: Text(addr['Địa chỉ'] ?? ""),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Số điện thoại: ${addr['Số điện thoại'] ?? ""}'),
                            Text('Ghi chú: ${addr['Ghi chú'] ?? ""}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // 🔹 Danh sách đơn hàng
            const Text('Đơn hàng:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: ordersColRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final orders = snapshot.data!.docs;

                if (orders.isEmpty) return const Text('Chưa có đơn hàng nào.');

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index].data() as Map<String, dynamic>;
                    final products = order['products'] as List<dynamic>? ?? [];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ExpansionTile(
                        title: Text('Đơn hàng: ${order['orderId'] ?? ''} - ${order['status'] ?? ''}'),
                        subtitle: Text('Tổng: ${order['finalPrice'] ?? 0} ₫'),
                        children: products.map((p) {
                          return ListTile(
                            title: Text(p['name'] ?? ''),
                            subtitle: Text('Số lượng: ${p['quantity'] ?? 0} - Giá: ${p['price'] ?? 0} ₫'),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
