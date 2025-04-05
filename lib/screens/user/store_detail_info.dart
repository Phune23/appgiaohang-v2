
import 'package:flutter/material.dart';
import '../../components/app_bar/custom_app_bar.dart';
import '../../providers/store_provider.dart';

class StoreDetailInfo extends StatefulWidget {
  final Map<String, dynamic> store;
  
  const StoreDetailInfo({super.key, required this.store});

  @override
  State<StoreDetailInfo> createState() => _StoreDetailInfoState();
}

class _StoreDetailInfoState extends State<StoreDetailInfo> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store['name']);
    _addressController = TextEditingController(text: widget.store['address']);
    _phoneController = TextEditingController(text: widget.store['phone_number']);
  }

  bool _isStoreActive() {
    final active = widget.store['is_active'];
    return active == 1;
  }

  Future<void> _updateStore() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final storeData = {
        'name': _nameController.text,
        'address': _addressController.text,
        'phone_number': _phoneController.text,
      };

      await StoreProvider.updateStore(widget.store['id'], storeData);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật cửa hàng thành công')),
      );
      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật cửa hàng thất bại')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStoreStatus() async {
    final newStatus = !_isStoreActive();
    
    try {
      await StoreProvider.toggleStoreStatus(widget.store['id'], newStatus);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'Store activated' : 'Store deactivated'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('cập nhật trạng thái cửa hàng thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title:  'Chi tiết cửa hàng',
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isEditing ? _updateStore : () => setState(() => _isEditing = true),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Tên cửa hàng'),
                      enabled: _isEditing,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Điền tên cửa hàng' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Địa chỉ'),
                      enabled: _isEditing,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Điền địa chỉ' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Số điện thoại'),
                      enabled: _isEditing,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Điền số điện thoại' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _toggleStoreStatus,
                      icon: Icon(_isStoreActive()
                          ? Icons.visibility_off
                          : Icons.visibility),
                      label: Text(_isStoreActive()
                          ? 'Deactivate Store'
                          : 'Activate Store'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: _isStoreActive()
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}