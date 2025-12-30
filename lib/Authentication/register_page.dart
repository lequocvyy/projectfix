import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  Future<void> register() async {
    setState(() => loading = true);

    try {
      final fullName = fullNameController.text.trim();
      final email = emailController.text.trim();
      final password = passwordController.text.trim(); // tạm lưu để login

      // 🔹 Tạo user document
      final userDocRef = FirebaseFirestore.instance.collection('users').doc();

      await userDocRef.set({
        'fullName': fullName,
        'email': email,
        'password': password, // tạm lưu, không an toàn
        'role': 'User',
      });

      // 🔹 Tạo subcollection Address rỗng
      final addressRef = userDocRef.collection('Address');

      // Tạo 1 document mặc định rỗng
      await addressRef.doc().set({
        'Ghi chú': '',
        'Số điện thoại': '',
        'Địa chỉ': '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công')),
      );

      Navigator.pop(context); // quay lại Login
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Đăng ký thất bại: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
            ),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: register,
                child: const Text('Đăng ký'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
