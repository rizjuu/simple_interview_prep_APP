import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:interview_prep/screens/cart_item_model.dart';
import 'package:interview_prep/widgets/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];
  static const _cartKey = 'cartItems';

  CartService() {
    _loadCart();
  }

  List<CartItem> get items => _items;

  double get totalPrice =>
      _items.fold(0, (total, current) => total + current.subtotal);

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    await _saveCart();
    notifyListeners();
  }

  Future<void> removeFromCart(CartItem cartItem) async {
    _items.removeWhere((item) => item.product.id == cartItem.product.id);
    await _saveCart();
    notifyListeners();
  }

  Future<void> incrementQuantity(CartItem cartItem) async {
    final index = _items.indexWhere(
      (item) => item.product.id == cartItem.product.id,
    );
    if (index != -1) {
      _items[index].increment();
      await _saveCart();
      notifyListeners();
    }
  }

  Future<void> decrementQuantity(CartItem cartItem) async {
    final index = _items.indexWhere(
      (item) => item.product.id == cartItem.product.id,
    );
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].decrement();
        await _saveCart();
        notifyListeners();
      }
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    await _saveCart();
    notifyListeners();
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartList = _items.map((item) => json.encode(item.toJson())).toList();
    await prefs.setStringList(_cartKey, cartList);
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartList = prefs.getStringList(_cartKey);
    if (cartList != null) {
      _items.clear();
      for (final itemString in cartList) {
        try {
          final itemJson = json.decode(itemString) as Map<String, dynamic>;
          _items.add(CartItem.fromJson(itemJson));
        } catch (e) {
          // Log the error and skip the malformed item.
          // This prevents a crash if old/bad data is in SharedPreferences.
          debugPrint('Failed to load cart item: $e');
        }
      }
      notifyListeners();
    }
  }
}
