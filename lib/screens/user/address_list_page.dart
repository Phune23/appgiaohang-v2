import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../components/app_bar/custom_app_bar.dart';
import '../../components/card/custom_card.dart';
import '../../config/config.dart';
import '../../utils/shared_prefs.dart';

class AddressListPage extends StatefulWidget {
  const AddressListPage({super.key});

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  String _selectedAddress = '';
  List<Map<String, dynamic>> addresses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final userId = await SharedPrefs.getUserId();
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('${Config.baseurl}/addresses/user/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          addresses = data.map((item) => item as Map<String, dynamic>).toList();
          // Set selected address from database
          final selectedAddress = addresses.firstWhere(
            (addr) => addr['is_selected'] == 1,
            orElse: () => {'address': ''},
          );
          _selectedAddress = selectedAddress['address'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load addresses');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading addresses: $e')),
      );
    }
  }

  Future<void> _updateSelectedAddress(String address) async {
    try {
      final userId = await SharedPrefs.getUserId();
      if (userId == null) return;

      final response = await http.put(
        Uri.parse('${Config.baseurl}/addresses/select'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'address': address,
        }),
      );

      if (response.statusCode == 200) {
        setState(() => _selectedAddress = address);
      } else {
        throw Exception('Failed to update selected address');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating selected address: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedAddress.isNotEmpty) {
          await _updateSelectedAddress(_selectedAddress);
        }
        Navigator.pop(context, _selectedAddress);
        return false;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Chọn Địa Chỉ Giao Hàng',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_selectedAddress.isNotEmpty) {
                await _updateSelectedAddress(_selectedAddress);
              }
              Navigator.pop(context, _selectedAddress);
            },
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CustomCard(
                    child: ListTile(
                      leading: const Icon(Icons.add_circle, color: Color.fromARGB(196, 177, 92, 12)),
                      title: const Text('Thêm Địa Chỉ Mới'),
                      onTap: () async {
                        final result =
                            await Navigator.pushNamed(context, '/add-address');
                        if (result != null) {
                          await _loadAddresses(); // Reload addresses after adding new one
                          if (result is Map<String, dynamic> &&
                              result['address'] != null) {
                            setState(
                                () => _selectedAddress = result['address']);
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...addresses
                      .map((address) => CustomCard(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: RadioListTile<String>(
                              title: Text(address['address']),
                              value: address['address'],
                              groupValue: _selectedAddress,
                              onChanged: (value) async {
                                await _updateSelectedAddress(value!);
                              },
                            ),
                          ))
                      .toList(),
                ],
              ),
      ),
    );
  }
}
