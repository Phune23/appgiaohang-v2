import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import 'auth_provider.dart';

class StoreProvider {
  static Future<Map<String, dynamic>> registerStore(Map<String, dynamic> storeData) async {
    final response = await http.post(
      Uri.parse('${Config.baseurl}/stores'),
      body: json.encode(storeData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to register store');
  }

  static Future<Map<String, dynamic>> updateStore(int id, Map<String, dynamic> storeData) async {
    final response = await http.put(
      Uri.parse('${Config.baseurl}/stores/$id'),
      body: json.encode(storeData),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to update store');
  }

  static Future<void> toggleStoreStatus(int id, bool isActive) async {
    final response = await http.patch(
      Uri.parse('${Config.baseurl}/stores/$id/status'),
      body: json.encode({'is_active': isActive}),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update store status');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserStores() async {
    final userId = await AuthProvider.getUserId();
    if (userId == null) throw Exception('User not logged in');
    
    final response = await http.get(
      Uri.parse('${Config.baseurl}/stores/user/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('Failed to fetch stores');
  }
}