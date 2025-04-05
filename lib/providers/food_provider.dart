import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';

class FoodProvider {
  static Future<Map<String, dynamic>> createFood(Map<String, dynamic> foodData) async {
    final response = await http.post(
      Uri.parse('${Config.baseurl}/foods'),
      body: json.encode(foodData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create food item');
  }

  static Future<List<Map<String, dynamic>>> getStoreFoods(int storeId) async {
    final response = await http.get(
      Uri.parse('${Config.baseurl}/foods/store/$storeId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('Failed to fetch foods');
  }

  static Future<void> updateFood(int foodId, Map<String, dynamic> foodData) async {
    final response = await http.put(
      Uri.parse('${Config.baseurl}/foods/$foodId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(foodData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update food');
    }
  }

  static Future<void> deleteFood(int foodId) async {
    final response = await http.delete(
      Uri.parse('${Config.baseurl}/foods/$foodId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete food');
    }
  }
}