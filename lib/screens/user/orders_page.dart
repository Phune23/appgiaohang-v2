import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../components/tab_bar/custom_tab_bar.dart';
import '../../config/config.dart';
import '../../utils/shared_prefs.dart';
import '../chat_screen.dart';

class Order {
  final int id;
  final String status;
  final double totalAmount;
  final String address;
  final double? latitude;  // Add these fields
  final double? longitude; // Add these fields
  final double? storeLat; // Add these fields 
  final double? storeLng; // Add these fields
  final int? shipperId; // Add this field
  final List<OrderItem> items;
  final String createdAt;

  Order({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.address,
    this.latitude,
    this.longitude,
    this.storeLat,
    this.storeLng,
    this.shipperId,
    required this.items,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List;
    return Order(
      id: json['id'],
      status: json['status'],
      totalAmount: double.parse(json['total_amount'].toString()),
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      storeLat: json['store_latitude']?.toDouble(),
      storeLng: json['store_longitude']?.toDouble(),
      shipperId: json['shipper_id'], // Add this line
      createdAt: json['created_at'],
      items: itemsList.map((item) => OrderItem.fromJson(item)).toList(),
    );
  }
}

class OrderItem {
  final int foodId;
  final int quantity;
  final double price;
  final int storeId;

  OrderItem({
    required this.foodId,
    required this.quantity,
    required this.price,
    required this.storeId,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      foodId: json['foodId'],
      quantity: json['quantity'],
      price: double.parse(json['price'].toString()),
      storeId: json['storeId'],
    );
  }
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;
  int? userId; // Add this field

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      userId = await SharedPrefs.getUserId(); // Assign userId here
      if (userId == null) throw Exception('User not logged in');

      final response = await http.get(
        Uri.parse('${Config.baseurl}/orders/user/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> ordersJson = json.decode(response.body);
        setState(() {
          _orders = ordersJson.map((json) => Order.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Order> _getCurrentOrders() {
    return _orders.where((order) => 
      ['pending', 'confirmed', 'preparing', 'delivering'].contains(order.status)
    ).toList();
  }

  List<Order> _getPastOrders() {
    return _orders.where((order) => 
      ['completed', 'cancelled'].contains(order.status)
    ).toList();
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/user-delivery-tracking',
            arguments: {
              'id': order.id,
              'orderId': order.id,
              'store_latitude': order.storeLat ?? 10.762622,
              'store_longitude': order.storeLng ?? 106.660172,
              'latitude': order.latitude ?? 10.762622,
              'longitude': order.longitude ?? 106.660172,
              'status': order.status,
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đơn hàng #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(Icons.location_on, order.address),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.attach_money,
                '${order.totalAmount.toStringAsFixed(2)} VND',
                isBold: true,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.access_time,
                _formatDate(order.createdAt),
                color: Colors.grey[600],
              ),
              if (order.status == 'delivering' && order.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat với người giao hàng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            orderId: order.id,
                            currentUserId: userId!,
                            otherUserId: order.shipperId ?? 0,
                            otherUserName: 'Shipper',
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

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isBold = false, Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'delivering':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(
              onPressed: _loadOrders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color(0xFFFF8C00),
                    Color(0xFFFF6B00),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center( // Center the title
                        child: const Text(
                          'Đơn hàng của tôi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TabBar(
                        tabs: const [
                          Tab(text: 'Đơn hàng hiện tại'),
                          Tab(text: 'Lịch sử đơn hàng'),
                        ],
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: Colors.white.withOpacity(0.2),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.7),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Current Orders Tab
                  _getCurrentOrders().isEmpty
                      ? const Center(child: Text('Không có đơn hàng nào'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: _getCurrentOrders().length,
                          itemBuilder: (context, index) {
                            return _buildOrderCard(_getCurrentOrders()[index]);
                          },
                        ),
                  // Order History Tab
                  _getPastOrders().isEmpty
                      ? const Center(child: Text('Không có lịch sử đơn hàng'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: _getPastOrders().length,
                          itemBuilder: (context, index) {
                            return _buildOrderCard(_getPastOrders()[index]);
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}