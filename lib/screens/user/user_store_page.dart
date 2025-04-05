import 'package:flutter/material.dart';
import '../../components/app_bar/custom_app_bar.dart';
import '../../components/card/custom_card.dart';
import '../../providers/store_provider.dart';
import 'store_orders_screen.dart';

class UserStorePage extends StatefulWidget {
  const UserStorePage({super.key});

  @override
  State<UserStorePage> createState() => _UserStorePageState();
}

class _UserStorePageState extends State<UserStorePage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _stores = [];

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() => _isLoading = true);
    try {
      final stores = await StoreProvider.getUserStores();
      setState(() => _stores = stores);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load stores: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return '🟢 Đã duyệt';
      case 'pending':
        return '🟡 Đang chờ duyệt';
      case 'rejected':
        return '🔴 Đã từ chối';
      default:
        return '⚪ Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:const CustomAppBar(
        title: 'Cửa hàng của bạn',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stores.isEmpty
              ? _buildEmptyState()
              : _buildStoreList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/register-store');
          if (result == true) {
            _loadStores(); // Refresh store list after registration
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            'Bạn chưa có cửa hàng nào',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nhấn nút + để đăng ký cửa hàng mới',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreList() {
    return ListView.builder(
      itemCount: _stores.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final store = _stores[index];
        return CustomCard(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                store['name'],
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
                  Text(
                    '📍 ${store['address']}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📞 ${store['phone_number']}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
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
                      _getStatusColor(store['status']),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/store-detail',
                  arguments: store,
                );
              },
            ),
          ),
        );
      },
    );
  }
}