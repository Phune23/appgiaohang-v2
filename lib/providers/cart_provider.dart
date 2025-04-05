import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

class CartProvider {
  static const String _cartKey = 'shopping_cart';
  static final _cartController = StreamController<int>.broadcast();
  static Stream<int> get cartStream => _cartController.stream;

  static Future<List<CartItem>> getCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartJson = prefs.getString(_cartKey);
    if (cartJson == null) return [];
    
    List<dynamic> cartList = json.decode(cartJson);
    return cartList.map((item) => CartItem.fromJson(item)).toList();
  }

  static Future<void> addToCart(CartItem item) async {
    final cart = await getCart();
    final existingItemIndex = cart.indexWhere((i) => i.foodId == item.foodId);
    
    if (existingItemIndex >= 0) {
      cart[existingItemIndex].quantity += item.quantity;
    } else {
      cart.add(item);
    }
    
    await _saveCart(cart);
  }

  static Future<void> updateQuantity(int foodId, int quantity) async {
    final cart = await getCart();
    final index = cart.indexWhere((item) => item.foodId == foodId);
    if (index >= 0) {
      cart[index].quantity = quantity;
      if (quantity <= 0) {
        cart.removeAt(index);
      }
      await _saveCart(cart);
    }
  }

  static Future<void> removeFromCart(int foodId) async {
    final cart = await getCart();
    cart.removeWhere((item) => item.foodId == foodId);
    await _saveCart(cart);
  }

  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }

  static Future<int> getCartCount() async {
    final cart = await getCart();
    return cart.fold<int>(0, (sum, item) => sum + item.quantity as int);
  }

  static Future<void> _saveCart(List<CartItem> cart) async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = json.encode(cart.map((item) => item.toJson()).toList());
    await prefs.setString(_cartKey, cartJson);
    _cartController.add(cart.fold(0, (sum, item) => sum + item.quantity));
  }
}