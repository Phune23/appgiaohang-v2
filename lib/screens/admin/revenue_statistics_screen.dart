import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/config.dart';

class RevenueStatisticsScreen extends StatefulWidget {
  const RevenueStatisticsScreen({super.key});

  @override
  State<RevenueStatisticsScreen> createState() => _RevenueStatisticsScreenState();
}

class _RevenueStatisticsScreenState extends State<RevenueStatisticsScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic> statistics = {};
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchStatistics() async {
    try {
      print('Tải thống kê doanh thu admin từ: ${Config.baseurl}/earnings/admin');
      
      final response = await http.get(
        Uri.parse('${Config.baseurl}/earnings/admin'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          statistics = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading statistics: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    } catch (e) {
      print('Exception in fetchStatistics: $e');
      setState(() {
        isLoading = false;
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  // Helper function to format currency with thousands separator
  String formatCurrency(double amount) {
    // Convert to integer if it's a whole number
    if (amount % 1 == 0) {
      // Format with thousands separator
      final formatted = amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},'
      );
      return '$formatted VND';
    }
    
    // For decimal numbers, format with thousands separator
    String priceString = amount.toString().replaceAll(RegExp(r'\.?0*$'), '');
    priceString = priceString.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    );
    return '$priceString VND';
  }

  Widget _buildStatisticCard(String title, dynamic value, IconData icon) {
    double amount = 0.0;
    if (value != null) {
      if (value is String) {
        amount = double.tryParse(value) ?? 0.0;
      } else if (value is num) {
        amount = value.toDouble();
      }
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 245, 176, 66), const Color.fromARGB(255, 210, 133, 25)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 30),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              formatCurrency(amount),
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionTileContent(Map<String, dynamic> breakdown) {
    // Helper function to convert and format amounts
    double convertAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lợi nhuận từ đơn hàng(30%): ${formatCurrency(convertAmount(breakdown['itemRevenue']))}',
            style: const TextStyle(color: Colors.blue),
          ),
          const SizedBox(height: 4),
          Text(
            'Lợi nhuận từ vận chuyển (20%): ${formatCurrency(convertAmount(breakdown['shippingRevenue']))}',
            style: const TextStyle(color: Colors.blue),
          ),
          const Divider(),
          Text(
            'Tổng đơn hàng: ${formatCurrency(convertAmount(breakdown['totalOrder']))}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'Phí Ship: ${formatCurrency(convertAmount(breakdown['shippingFee']))}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSection(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatisticCard('Hôm nay', data['today'], Icons.today),
            _buildStatisticCard('Tuần này', data['week'], Icons.calendar_view_week),
            _buildStatisticCard('Tháng này', data['month'], Icons.calendar_month),
            _buildStatisticCard('Tổng', data['total'], Icons.account_balance_wallet),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê doanh thu'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lợi nhuận từ đơn hàng (30%)'),
            Tab(text: 'Lợi nhuận từ shipping (20%)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Item Revenue Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRevenueSection('Vật phẩm lợi nhuận',
                    statistics['itemRevenue'] ?? {}),
                const SizedBox(height: 24),
                _buildTransactionList(true),
              ],
            ),
          ),
          // Shipping Revenue Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRevenueSection('Doanh thu vận chuyển', 
                    statistics['shippingRevenue'] ?? {}),
                const SizedBox(height: 24),
                _buildTransactionList(false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(bool isItemRevenue) {
    // Helper function to convert amount
    double convertToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Những giao dịch gần đây',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: (statistics['history'] as List?)?.length ?? 0,
          itemBuilder: (context, index) {
            final transaction = statistics['history'][index];
            final amount = convertToDouble(isItemRevenue 
                ? transaction['itemRevenue']
                : transaction['shippingRevenue']);
            final total = convertToDouble(isItemRevenue
                ? transaction['itemTotal']
                : transaction['shippingFee']);

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.receipt, color: Colors.blue),
                ),
                title: Text(
                  'Đơn hàng #${transaction['orderId']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateTime.parse(transaction['date'].toString())
                        .toLocal()
                        .toString()
                        .split('.')[0]),
                    Text(
                      'Tổng: ${formatCurrency(total)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                trailing: Text(
                  formatCurrency(amount),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
