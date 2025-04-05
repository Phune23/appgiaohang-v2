import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../components/app_bar/custom_app_bar.dart';
import '../components/bottom_navigation_bar/custom_bottom_navigation_bar.dart';
import '../config/config.dart';
import '../providers/auth_provider.dart';
import 'shipper/settings_page.dart';
import 'shipper/order_list_page.dart';
import 'shipper/active_deliveries_page.dart';
import 'shipper/earnings_page.dart';

class HomeShipperScreen extends StatefulWidget {
  const HomeShipperScreen({super.key});

  @override
  State<HomeShipperScreen> createState() => _HomeShipperScreenState();
}

class _HomeShipperScreenState extends State<HomeShipperScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [];
  Position? _currentPosition;
  late IO.Socket socket;
  Map<String, dynamic>? _activeDelivery;

  @override
  void initState() {
    super.initState();
    _initSocket();
    _initLocationTracking();
    _loadActiveDelivery();
    _pages.addAll([
      OrderListPage(),
      ActiveDeliveriesPage(),
      const EarningsPage(),
      const SettingsPage(),
    ]);
  }

  void _initSocket() {
    socket = IO.io('${Config.baseurl}', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
  }

  Future<void> _initLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Notify user to enable location services
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Handle permission denied
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Handle permission permanently denied
      return;
    }

    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
      
      // Send location to socket server
      if (_currentPosition != null) {
        _sendLocationUpdate(_currentPosition!);
      }
    });
  }

  Future<void> _loadActiveDelivery() async {
    try {
      final userId = await AuthProvider.getUserId();
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('${Config.baseurl}/orders/shipper/$userId/active'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> orders = json.decode(response.body);
        if (orders.isNotEmpty) {
          setState(() {
            _activeDelivery = orders.first;
          });
        }
      }
    } catch (e) {
      print('Error loading active delivery: $e');
    }
  }

  void _sendLocationUpdate(Position position) {
    if (_activeDelivery != null) {
      final connectionString = generateConnectionString(_activeDelivery!);
      socket.emit('shipper-location', {
        'connectionString': connectionString,
        'latitude': position.latitude,
        'longitude': position.longitude
      });
    }
  }

  String generateConnectionString(Map<String, dynamic> order) {
    return 'delivery_${order['id']}_${order['store_latitude']}_${order['store_longitude']}_${order['latitude']}_${order['longitude']}';
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Bảng Điều Khiển Shipper',
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Đơn Hàng'),
            BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Giao Hàng'),
            BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Thu Nhập'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài Đặt'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
