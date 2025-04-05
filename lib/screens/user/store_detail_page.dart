import 'package:flutter/material.dart';
import '../../components/app_bar/custom_app_bar.dart';
import '../../components/card/custom_card.dart';
import 'store_orders_screen.dart';

class StoreDetailPage extends StatelessWidget {
  final Map<String, dynamic> store;
  
  const StoreDetailPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Thông Tin Cửa Hàng',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomCard(
              elevation: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/store-detail-info',
                      arguments: store,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                store['address'] ?? '',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              store['phone_number'] ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Text(
                              'Xem chi tiết',
                              style: TextStyle(color: Colors.blue),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (store['status'] == 'approved') ...[
              const SizedBox(height: 16),
              _buildActionCard(
                icon: Icons.restaurant_menu,
                title: 'Quản lý món ăn',
                onTap: () => Navigator.pushNamed(
                  context,
                  '/food-management',
                  arguments: store['id'],
                ),
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.shopping_bag,
                title: 'Đơn hàng',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoreOrdersScreen(
                      storeId: store['id'],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.bar_chart,
                title: 'Thống kê',
                onTap: () => Navigator.pushNamed(
                  context,
                  '/store-statistics',
                  arguments: store['id'],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required VoidCallback onTap}) {
    return CustomCard(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(color: Colors.blue)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
        onTap: onTap,
      ),
    );
  }
}