import 'package:appgiaohang/config/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../components/card/custom_card.dart';

class StoreApprovalScreen extends StatefulWidget {
  const StoreApprovalScreen({super.key});

  @override
  State<StoreApprovalScreen> createState() => _StoreApprovalScreenState();
}

class _StoreApprovalScreenState extends State<StoreApprovalScreen> {
  List<Map<String, dynamic>> pendingStores = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingStores();
  }

  Future<void> _loadPendingStores() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/stores/pending'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          pendingStores = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách cửa hàng: $e')),
      );
    }
  }

  Future<void> _updateStoreStatus(int storeId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('${Config.baseurl}/stores/$storeId/approval'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        setState(() {
          pendingStores.removeWhere((store) => store['id'] == storeId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cửa hàng đã được ${status == 'approved' ? 'phê duyệt' : 'từ chối'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating store: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: pendingStores.length,
      itemBuilder: (context, index) {
        final store = pendingStores[index];
        return CustomCard(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(store['name']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Địa chỉ: ${store['address']}'),
                Text('Số điện thoại: ${store['phone_number']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _updateStoreStatus(store['id'], 'approved'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _updateStoreStatus(store['id'], 'rejected'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}