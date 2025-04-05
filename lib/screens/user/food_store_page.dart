import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../components/app_bar/custom_app_bar.dart';
import '../../components/card/custom_card.dart';
import '../../config/config.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';

class FoodStorePage extends StatefulWidget {
  final Map<String, dynamic> store;

  const FoodStorePage({super.key, required this.store});

  @override
  State<FoodStorePage> createState() => _FoodStorePageState();
}

class _FoodStorePageState extends State<FoodStorePage> {
  List<dynamic> foods = [];
  bool isLoading = true;
  int cartCount = 0;

  @override
  void initState() {
    super.initState();
    fetchFoods();
    updateCartCount();
    CartProvider.cartStream.listen((_) => updateCartCount());
  }

  Future<void> fetchFoods() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/foods/store/${widget.store['id']}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          foods = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateCartCount() async {
    final count = await CartProvider.getCartCount();
    setState(() {
      cartCount = count;
    });
  }

  Future<bool> _onWillPop() async {
    await CartProvider.clearCart();
    return true;
  }

  @override
  void dispose() {
    CartProvider.clearCart();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: CustomAppBar(
          title: widget.store['name'],
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => Navigator.pushNamed(context, '/cart'),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(191, 244, 67, 54),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thực đơn',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (foods.isEmpty)
                const Center(child: Text('Không có món ăn nào'))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: foods.length,
                    itemBuilder: (context, index) {
                      final food = foods[index];
                      return CustomCard(
                        child: ListTile(
                          leading: Image.asset(
                            'assets/images/food_image.png', 
                            width: 50, 
                            height: 50, 
                            fit: BoxFit.cover,
                          ),
                          title: Text(food['name']),
                          subtitle: Text(food['description'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${(double.parse(food['price'].toString()) * 1000).toStringAsFixed(0).replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (Match m) => '${m[1]}.',
                              )}đ'),
                              IconButton(
                                icon: const Icon(Icons.add_shopping_cart),
                                onPressed: () async {
                                  final cartItem = CartItem(
                                    foodId: food['id'],
                                    name: food['name'],
                                    price: double.parse(food['price'].toString()) * 1000,
                                    storeId: widget.store['id'],
                                    storeName: widget.store['name'],
                                  );
                                  await CartProvider.addToCart(cartItem);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}