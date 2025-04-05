class CartItem {
  final int foodId;
  final String name;
  final double price;
  final int storeId;
  final String storeName;
  int quantity;

  CartItem({
    required this.foodId,
    required this.name,
    required this.price,
    required this.storeId,
    required this.storeName,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'name': name,
      'price': price,
      'storeId': storeId,
      'storeName': storeName,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      foodId: json['foodId'],
      name: json['name'],
      price: json['price'],
      storeId: json['storeId'],
      storeName: json['storeName'],
      quantity: json['quantity'],
    );
  }
}
