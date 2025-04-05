
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/config.dart';
import '../../providers/auth_provider.dart';

class OrderListPage extends StatefulWidget {
    const OrderListPage({super.key});
  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/orders/confirmed'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _orders = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading orders: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOrder(int orderId) async {
    try {
      final userId = await AuthProvider.getUserId();
      if (userId == null) return;

      final response = await http.post(
        Uri.parse('${Config.baseurl}/orders/$orderId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'shipperId': userId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order accepted successfully')),
        );
        _loadOrders(); // Refresh the list
      } else {
        throw Exception('Failed to accept order');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty) {
      return const Center(child: Text('Không có đơn hàng nào'));
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          // Fix: items is already a List<dynamic>, no need to decode
          final items = order['items'] as List<dynamic>;
          
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text('Order #${order['id']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Khách hàng: ${order['customer_name']}'),
                  Text('Địa chỉ: ${order['address']}'),
                  Text('Tổng tiền: ${order['total_amount']}đ'),
                  const SizedBox(height: 8),
                  Text('Món ăn:'),
                  ...items.map((item) => Text(
                    '- ${item['food_name']} x${item['quantity']} từ ${item['store_name']}'
                  )),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () => _acceptOrder(order['id']),
                child: const Text('Nhận đơn'),
              ),
            ),
          );
        },
      ),
    );
  }
}