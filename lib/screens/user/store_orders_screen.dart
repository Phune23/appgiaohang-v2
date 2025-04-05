import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../components/app_bar/custom_app_bar.dart';
import '../../config/config.dart';

class StoreOrdersScreen extends StatefulWidget {
  final int storeId;

  const StoreOrdersScreen({super.key, required this.storeId});

  @override
  State<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/orders/store/${widget.storeId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _orders = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading orders: $e')),
      );
    }
  }

  Future<void> _reviewOrder(int orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.baseurl}/orders/$orderId/review'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted' 
                ? 'Đã xác nhận đơn hàng và thông báo cho khách hàng' 
                : 'Đã từ chối đơn hàng và thông báo cho khách hàng'
            ),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
          ),
        );
      }
      
      _loadOrders(); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật đơn hàng: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Quản Lý Đơn Hàng'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có đơn hàng nào',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _orders.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final items = order['items'];
                    final status = order['status'];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                'Đơn hàng #${order['id']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      'Trạng thái: ${_getVietnameseStatus(status)}',
                                      style: TextStyle(
                                        color: status == 'confirmed'
                                            ? Colors.green
                                            : status == 'cancelled'
                                                ? Colors.red
                                                : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tổng tiền: ${_formatCurrency(order['total_amount'])}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'Số lượng món: ${items.length}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            if (status == 'pending')
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          _reviewOrder(order['id'], 'rejected'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: const Text('Từ chối'),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _reviewOrder(order['id'], 'accepted'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: const Text('Xác nhận'),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _getVietnameseStatus(String status) {
    switch (status) {
      case 'pending':
        return 'ĐANG CHỜ';
      case 'confirmed':
        return 'ĐÃ XÁC NHẬN';
      case 'cancelled':
        return 'ĐÃ HỦY';
      default:
        return status.toUpperCase();
    }
  }

  String _formatCurrency(dynamic amount) {
    return '${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}đ';
  }
}
