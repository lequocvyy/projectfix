class CartService {
  static final CartService _instance = CartService._internal();

  factory CartService() => _instance;

  CartService._internal();

  final List<Map<String, dynamic>> _cart = [];

  List<Map<String, dynamic>> get cart => _cart;

  void addProduct(Map<String, dynamic> product) {
    // Nếu đã có sản phẩm, cộng số lượng
    final index = _cart.indexWhere((p) =>
    p['productId'] == product['productId']);
    if (index >= 0) {
      _cart[index]['quantity'] += product['quantity'];
    } else {
      _cart.add(product);
    }
  }

  void removeProduct(String productId) {
    _cart.removeWhere((p) => p['productId'] == productId);
  }

  void clear() => _cart.clear();
}
