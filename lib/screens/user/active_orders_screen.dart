import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/config.dart';
import '../../providers/auth_provider.dart';

class ActiveOrdersScreen extends StatefulWidget {
  const ActiveOrdersScreen({super.key});

  @override
  State<ActiveOrdersScreen> createState() => _ActiveOrdersScreenState();
}

class _ActiveOrdersScreenState extends State<ActiveOrdersScreen> {
  Future<List<dynamic>>? _ordersFuture;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final userId = await AuthProvider.getUserId();
    if (userId != null) {
      setState(() {
        _ordersFuture = _getActiveOrders(userId);
      });
    }
  }

  Future<List<dynamic>> _getActiveOrders(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/orders/user/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> orders = json.decode(response.body);
        return orders
            .where((order) => ['confirmed', 'preparing', 'delivering']
                .contains(order['status']))
            .toList();
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Đã xác nhận';
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'delivering':
        return 'Đang giao';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'delivering':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: SafeArea(
          child: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Đơn hàng đang giao',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: _fetchOrders,
              ),
            ],
            backgroundColor: Colors.white,
            elevation: 0.5,
            centerTitle: true,
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có đơn hàng nào đang giao'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final order = snapshot.data![index];
              final items = json.decode(order['items']);

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đơn hàng #${order['id']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Chip(
                            label: Text(
                              _getStatusText(order['status']),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: _getStatusColor(order['status']),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('Địa chỉ: ${order['address']}'),
                      Text('Tổng tiền: ${order['total_amount']} VNĐ'),
                      Text(
                          'Phương thức thanh toán: ${order['payment_method']}'),
                      if (order['note'] != null && order['note'].isNotEmpty)
                        Text('Ghi chú: ${order['note']}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
