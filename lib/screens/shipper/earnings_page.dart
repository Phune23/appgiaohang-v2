import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/config.dart';
import '../../providers/auth_provider.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  Future<Map<String, dynamic>>? _earningsFuture;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    final userId = await AuthProvider.getUserId();
    if (userId != null) {
      setState(() {
        _earningsFuture = _fetchEarnings(userId);
      });
    }
  }

  Future<Map<String, dynamic>> _fetchEarnings(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/earnings/shipper/$userId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Không thể tải dữ liệu thu nhập');
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: TabBar(
              labelColor: Colors.blue.shade700,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue.shade700,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Thu Nhập'),
                Tab(text: 'Đơn Hoàn Thành'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildEarningsTab(),
            _buildCompletedOrdersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _earningsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final earnings = snapshot.data ?? {};
        
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildEarningsSummary(earnings),
              _buildEarningsHistory(earnings),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedOrdersTab() {
    return FutureBuilder<List<dynamic>>(
      future: _fetchCompletedOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return const Center(child: Text('Chưa có đơn hàng hoàn thành'));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('Đơn hàng #${order['id']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Khách hàng: ${order['customer_name']}'),
                    Text('Địa chỉ: ${order['address']}'),
                    Text('Ngày giao: ${_formatDate(order['updated_at'])}'),
                  ],
                ),
                trailing: Text(
                  formatCurrency(order['shipping_fee']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Future<List<dynamic>> _fetchCompletedOrders() async {
    try {
      final userId = await AuthProvider.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await http.get(
        Uri.parse('${Config.baseurl}/orders/shipper/$userId/completed'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Không thể tải danh sách đơn hàng');
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
  
  String formatCurrency(dynamic amount) {
    if (amount == null) return '0 ₫';
    if (amount is String) {
      amount = double.parse(amount);
    }
    // Convert to integer (remove decimal places)
    final intAmount = (amount as num).toInt();
    // Format with thousand separators
    final formatted = intAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$formatted ₫';
  }

  Widget _buildEarningsSummary(Map<String, dynamic> earnings) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade700],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Tổng Thu Nhập',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            formatCurrency(earnings['totalEarnings']),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Hôm nay', formatCurrency(earnings['todayEarnings']), true),
                _buildVerticalDivider(),
                _buildStatItem('Tuần này', formatCurrency(earnings['weekEarnings']), true),
                _buildVerticalDivider(),
                _buildStatItem('Tháng này', formatCurrency(earnings['monthEarnings']), true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildStatItem(String label, String value, bool isWhite) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isWhite ? Colors.white70 : Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isWhite ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsHistory(Map<String, dynamic> earnings) {
    final List<dynamic> history = earnings['history'] ?? [];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            leading: const Icon(Icons.delivery_dining),
            title: Text('Đơn hàng #${item['orderId']}'),
            subtitle: Text(_formatDate(item['date'])),
            trailing: Text(
              formatCurrency(item['amount']),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiền ship nhận được (80%): ${formatCurrency(item['shippingFee'])}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}