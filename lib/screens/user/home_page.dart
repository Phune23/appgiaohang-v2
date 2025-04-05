import 'package:appgiaohang/config/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../components/app_bar/custom_app_bar.dart';
import '../../components/card/custom_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> stores = [];
  List<dynamic> filteredStores = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStores();
  }

  Future<void> fetchStores() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/stores/user'),
      );

      if (response.statusCode == 200) {
        setState(() {
          stores = json.decode(response.body);
          filteredStores = stores;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error
    }
  }

  void _filterStores(String query) {
    setState(() {
      filteredStores = stores.where((store) {
        final storeName = store['name'].toString().toLowerCase();
        final storeAddress = store['address'].toString().toLowerCase();
        final searchLower = query.toLowerCase();
        return storeName.contains(searchLower) || 
               storeAddress.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Danh sách cửa hàng',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm cửa hàng...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _filterStores,
            ),
            const SizedBox(height: 20),
            
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (filteredStores.isEmpty)
              const Center(child: Text('Không tìm thấy cửa hàng'))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: filteredStores.length,
                  itemBuilder: (context, index) {
                    final store = filteredStores[index];
                    return CustomCard(
                      child: ListTile(
                        leading: Image.asset(
                          'assets/images/shop_food_image.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(store['name']),
                        subtitle: Text(store['address']),
                        trailing: const Icon(Icons.storefront),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/food-store',
                            arguments: store,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
