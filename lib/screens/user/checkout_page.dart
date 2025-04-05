import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart'; // Add this import
import 'package:intl/intl.dart'; // Add this import
import '../../components/app_bar/custom_app_bar.dart';
import '../../components/buttons/custom_elevated_button.dart';
import '../../components/card/custom_card.dart';
import '../../config/config.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/stripe_service.dart';
import '../../utils/shared_prefs.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final double total;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.total,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedAddress = '';
  double? _latitude;
  double? _longitude;
  final _noteController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isLoading = true;
  double _shippingFee = 0;
  double _distance = 0;

  @override
  void initState() {
    super.initState();
    _loadSelectedAddress();
  }

  Future<void> _loadSelectedAddress() async {
    try {
      final userId = await SharedPrefs.getUserId();
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('${Config.baseurl}/addresses/user/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> addresses = json.decode(response.body);
        final selectedAddress = addresses.firstWhere(
          (addr) => addr['is_selected'] == 1,
          orElse: () => {'address': '', 'latitude': null, 'longitude': null},
        );

        // Get store details for first item
        if (widget.cartItems.isNotEmpty) {
          final storeResponse = await http.get(
            Uri.parse(
                '${Config.baseurl}/stores/${widget.cartItems.first.storeId}'),
          );

          if (storeResponse.statusCode == 200) {
            final storeData = json.decode(storeResponse.body);

            setState(() {
              _selectedAddress = selectedAddress['address'];
              _latitude = selectedAddress['latitude'];
              _longitude = selectedAddress['longitude'];
              _isLoading = false;
            });

            // Calculate shipping fee after getting both coordinates
            _calculateShippingFee(
              storeData['latitude'],
              storeData['longitude'],
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading address: $e')),
      );
    }
  }

  // Add this method to calculate distance and shipping fee
  void _calculateShippingFee(double storeLat, double storeLng) {
    if (_latitude == null || _longitude == null) return;

    _distance = Geolocator.distanceBetween(
          _latitude!,
          _longitude!,
          storeLat,
          storeLng,
        ) /
        1000; // Convert meters to kilometers

    // Round distance to nearest kilometer
    _distance = (_distance).round().toDouble();

    // Calculate shipping fee:
    // Base fee: 15.000đ for first 2km
    // Additional fee: 5.000đ per extra kilometer
    setState(() {
      _shippingFee = 15000 + ((_distance > 2) ? (_distance - 2).round() * 5000 : 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Thanh toán',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Địa chỉ giao hàng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CustomCard(
                    child: ListTile(
                      title: Text(_selectedAddress.isEmpty
                          ? 'Chọn địa chỉ giao hàng'
                          : _selectedAddress),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () async {
                        final result =
                            await Navigator.pushNamed(context, '/address-list');
                        if (result != null && result is String) {
                          setState(() => _selectedAddress = result);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ghi chú',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      hintText: 'Thêm ghi chú cho đơn hàng (không bắt buộc)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Phương thức thanh toán',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  RadioListTile(
                    title: const Text('Thanh toán khi nhận hàng'),
                    value: 'cash',
                    groupValue: _paymentMethod,
                    onChanged: (value) =>
                        setState(() => _paymentMethod = value!),
                  ),
                  RadioListTile(
                    title: const Text('Thanh toán bằng thẻ'),
                    value: 'stripe',
                    groupValue: _paymentMethod,
                    onChanged: (value) => setState(() => _paymentMethod = value!),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tổng quan đơn hàng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                            '${item.quantity}x ${NumberFormat('#,###').format(item.price)} VNĐ'),
                        trailing: Text(
                            '${NumberFormat('#,###').format(item.price * item.quantity)} VNĐ'),
                      );
                    },
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Khoảng cách giao hàng:'),
                      Text('${_distance.toStringAsFixed(1)} km'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Phí giao hàng:'),
                      Text('${NumberFormat('#,###').format(_shippingFee)} VNĐ'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng cộng:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${NumberFormat('#,###').format(widget.total + _shippingFee)} VNĐ',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: CustomElevatedButton(
          onPressed: _placeOrder,
          text: 'Đặt hàng',
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa chỉ giao hàng')),
      );
      return;
    }

    try {
      if (_paymentMethod == 'stripe') {
        final int amountInVND = ((widget.total + _shippingFee)).round();
        final bool paymentSuccess = await StripeService.instance.makePayment(amountInVND);
        if (!paymentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thanh toán thất bại. Vui lòng thử lại.')),
          );
          return;
        }
      }

      final userId = await SharedPrefs.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // First item in cart
      final firstItem = widget.cartItems.first;

      // Get store details
      final storeResponse = await http.get(
        Uri.parse('${Config.baseurl}/stores/${firstItem.storeId}'),
      );

      if (storeResponse.statusCode != 200) {
        throw Exception('Failed to get store details');
      }

      final storeData = json.decode(storeResponse.body);
      print('Store data: $storeData'); // Debug log

      final orderData = {
        'userId': userId,
        'address': _selectedAddress,
        'latitude': _latitude,
        'longitude': _longitude,
        'store_address': storeData['address'],
        'store_latitude': storeData['latitude'],
        'store_longitude': storeData['longitude'],
        'items': widget.cartItems
            .map((item) => {
                  'foodId': item.foodId,
                  'quantity': item.quantity,
                  'price': item.price,
                  'storeId': item.storeId,
                })
            .toList(),
        'totalAmount': widget.total + _shippingFee,
        'shippingFee': _shippingFee,
        'distance': _distance,
        'paymentMethod': _paymentMethod,
        'note': _noteController.text,
      };

      print('Order data being sent: $orderData'); // Debug log

      final response = await http.post(
        Uri.parse('${Config.baseurl}/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );

      print(
          'Order response: ${response.statusCode} - ${response.body}'); // Debug log

      if (response.statusCode != 201) {
        throw Exception('Failed to create order: ${response.body}');
      }

      await CartProvider.clearCart();
      if (!mounted) return;

      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt hàng thành công!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đặt hàng: $e')),
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
