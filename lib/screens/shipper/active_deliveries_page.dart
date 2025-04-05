import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/config.dart';
import '../../providers/auth_provider.dart';
import '../chat_screen.dart';
import './delivery_navigation_page.dart';

class ActiveDeliveriesPage extends StatefulWidget {
  @override
  _ActiveDeliveriesPageState createState() => _ActiveDeliveriesPageState();
}

class _ActiveDeliveriesPageState extends State<ActiveDeliveriesPage> {
  List<dynamic> _activeOrders = [];
  bool _isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadActiveOrders();
  }

  Future<void> _loadActiveOrders() async {
    setState(() => _isLoading = true);
    try {
      final id = await AuthProvider.getUserId();
      userId = id?.toString();
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('${Config.baseurl}/orders/shipper/$userId/active'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _activeOrders = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        print('Error: ${response.body}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading active orders: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startDelivery(Map<String, dynamic> order) async {
    try {
      final shipperId = await AuthProvider.getUserId();
      if (shipperId == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('${Config.baseurl}/orders/${order['id']}/start-delivery'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'shipperId': shipperId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery started successfully')),
        );
        _loadActiveOrders();
      } else {
        final error = json.decode(response.body)['error'];
        throw Exception(error ?? 'Failed to start delivery');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _completeDelivery(Map<String, dynamic> order) async {
    try {
      final shipperId = await AuthProvider.getUserId();
      if (shipperId == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('${Config.baseurl}/orders/${order['id']}/complete-delivery'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'shipperId': shipperId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã giao hàng thành công')),
        );
        _loadActiveOrders();
      } else {
        final error = json.decode(response.body)['error'];
        throw Exception(error ?? 'Failed to complete delivery');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có đơn hàng đang giao',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActiveOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _activeOrders.length,
        itemBuilder: (context, index) {
          final order = _activeOrders[index];
          final items = order['items'] as List<dynamic>;

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: order['status'] == 'preparing' 
                        ? Colors.blue[50] 
                        : Colors.green[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        order['status'] == 'preparing'
                            ? Icons.pending_actions
                            : Icons.delivery_dining,
                        color: order['status'] == 'preparing'
                            ? Colors.blue
                            : Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Order #${order['id']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: order['status'] == 'preparing'
                              ? Colors.blue[700]
                              : Colors.green[700],
                        ),
                      ),
                      const Spacer(),
                      _buildStatusChip(order['status']),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.person, order['customer_name']),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.phone, order['customer_phone']),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.location_on, order['address']),
                      const Divider(height: 24),
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Text(
                                  '- ${item['food_name']} x${item['quantity']} từ ${item['store_name']}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (order['status'] == 'preparing')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delivery_dining, size: 24),
                            label: const Text(
                              'Đã nhận hàng giao',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _startDelivery(order),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      if (order['status'] == 'delivering')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle, size: 24),
                            label: const Text(
                              'Đã giao hàng',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _completeDelivery(order),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Nhắn tin'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      orderId: order['id'],
                                      currentUserId: int.parse(userId!),
                                      otherUserId: order['user_id'],
                                      otherUserName: order['customer_name'],
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue[700],
                                side: BorderSide(color: Colors.blue[700]!),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.navigation),
                              label: const Text('Chỉ đường'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DeliveryNavigationPage(
                                      order: order,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    late final Color color;
    late final String text;
    late final IconData icon;

    switch (status) {
      case 'preparing':
        color = const Color(0xFF2196F3);
        text = 'Đang chờ lấy hàng';
        icon = Icons.pending_actions;
        break;
      case 'delivering':
        color = const Color(0xFF4CAF50);
        text = 'Đang giao hàng';
        icon = Icons.delivery_dining;
        break;
      default:
        color = Colors.grey;
        text = 'Không xác định';
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
