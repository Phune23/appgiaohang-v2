import 'package:flutter/material.dart';
import '../components/bottom_navigation_bar/custom_bottom_navigation_bar.dart';
import 'user/home_page.dart';
import 'user/orders_page.dart';
import 'user/notifications_page.dart';
import 'user/profile_page.dart';

class HomeUserScreen extends StatefulWidget {
  const HomeUserScreen({super.key});

  @override
  State<HomeUserScreen> createState() => _HomeUserScreenState();
}

class _HomeUserScreenState extends State<HomeUserScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      const OrdersPage(),
      const NotificationsPage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ',),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Đơn hàng'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Thông báo'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}