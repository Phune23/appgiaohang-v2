import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../components/card/custom_card.dart';
import '../../config/config.dart';

class ShipperManagementScreen extends StatefulWidget {
  const ShipperManagementScreen({super.key});

  @override
  State<ShipperManagementScreen> createState() => _ShipperManagementScreenState();
}

class _ShipperManagementScreenState extends State<ShipperManagementScreen> {
  List<Map<String, dynamic>> _pendingShippers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingShippers();
  }

  Future<void> _loadPendingShippers() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/auth/shippers/pending'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _pendingShippers = List<Map<String, dynamic>>.from(
            jsonDecode(response.body)['shippers']
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading shippers: $e')),
      );
    }
  }

  Future<void> _updateShipperStatus(int userId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.baseurl}/auth/shipper/$userId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        _loadPendingShippers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shipper $status successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingShippers.isEmpty) {
      return const Center(child: Text('Không có đơn đăng ký shipper mới'));
    }

    return ListView.builder(
      itemCount: _pendingShippers.length,
      itemBuilder: (context, index) {
        final shipper = _pendingShippers[index];
        return CustomCard(
          elevation: 4,
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shipper['full_name'] ?? 'Unknown',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.email, shipper['email'] ?? 'N/A'),
                _buildInfoRow(Icons.phone, shipper['phone_number'] ?? 'N/A'),
                _buildInfoRow(Icons.two_wheeler, shipper['vehicle_type'] ?? 'N/A'),
                _buildInfoRow(Icons.numbers, shipper['license_plate'] ?? 'N/A'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Phê duyệt'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => _updateShipperStatus(shipper['user_id'], 'approved'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Từ chối'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => _updateShipperStatus(shipper['user_id'], 'rejected'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
