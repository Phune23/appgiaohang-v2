import 'package:flutter/material.dart';
import '../../components/app_bar/custom_app_bar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';

class StoreRegistrationPage extends StatefulWidget {
  const StoreRegistrationPage({super.key});

  @override
  State<StoreRegistrationPage> createState() => _StoreRegistrationPageState();
}

class _StoreRegistrationPageState extends State<StoreRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? selectedAddress;
  double? latitude;
  double? longitude;

  Future<void> _submitStore() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a store address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = await AuthProvider.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final storeData = {
        'name': _nameController.text,
        'address': selectedAddress,
        'phone_number': _phoneController.text,
        'owner_id': userId,
        'latitude': latitude,
        'longitude': longitude,
      };

      await StoreProvider.registerStore(storeData);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store registered successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register store: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectAddress() async {
    final result = await Navigator.pushNamed(context, '/store-address-map')
        as Map<String, dynamic>?;

    if (result != null) {
      setState(() {
        selectedAddress = result['address'];
        latitude = result['latitude'];
        longitude = result['longitude'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Đăng Ký Cửa Hàng Mới'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Tên Cửa Hàng',
                                  prefixIcon: const Icon(Icons.store),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Vui lòng nhập tên cửa hàng'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.5),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: _selectAddress,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.location_on,
                                                color: Theme.of(context)
                                                    .primaryColor),
                                            const SizedBox(width: 8),
                                            Text('Địa Chỉ Cửa Hàng',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium),
                                          ],
                                        ),
                                        if (selectedAddress != null) ...[
                                          const SizedBox(height: 8),
                                          Text(selectedAddress!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: 'Số Điện Thoại',
                                  prefixIcon: const Icon(Icons.phone),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Vui lòng nhập số điện thoại'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submitStore,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Đăng Ký Cửa Hàng',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
