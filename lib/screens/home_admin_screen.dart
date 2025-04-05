import 'package:flutter/material.dart';
import '../components/app_bar/custom_app_bar.dart';
import '../components/bottom_navigation_bar/custom_bottom_navigation_bar.dart';
import 'admin/shipper_management_screen.dart';
import 'admin/settings_admin_screen.dart';
import 'admin/store_approval_screen.dart';
import 'admin/user_management_screen.dart';
import 'admin/revenue_statistics_screen.dart';

class HomeAdminScreen extends StatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    const UserManagementScreen(),
    const StoreApprovalScreen(),
    const ShipperManagementScreen(),
    const RevenueStatisticsScreen(),
    const SettingsAdminScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:const CustomAppBar(title: 'Trang Quản Trị'),
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Người dùng'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Cửa hàng'),
            BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Shipper'),

            BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Báo cáo'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}