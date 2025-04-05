import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/card/custom_card.dart';
import '../../components/switch_list_tile/custom_switch_list_tile.dart';
import '../../providers/auth_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsAdminScreen extends StatefulWidget {
  const SettingsAdminScreen({super.key});

  @override
  State<SettingsAdminScreen> createState() => _SettingsAdminScreenState();
}

class _SettingsAdminScreenState extends State<SettingsAdminScreen> {
  bool _darkMode = false;
  bool _notifications = true;

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              child: const Text('Hủy'),

              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Đăng xuất'),
              onPressed: () async {
                await AuthProvider.logout();
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/user_home', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          CustomCard(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Hồ sơ quản trị viên'),
              subtitle: const Text('Quản lý thông tin cá nhân'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to profile management
              },
            ),
          ),
          const SizedBox(height: 16),
          CustomCard(
            child: Column(
              children: [
                CustomSwitchListTile(
                  title: 'Chế độ tối',
                  subtitle: 'Bật/tắt giao diện tối',
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
                CustomSwitchListTile(
                  title: 'Thông báo',
                  secondary: const Icon(Icons.notifications),
                  value: _notifications,
                  onChanged: (value) {
                    setState(() {
                      _notifications = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomCard(
            child: ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Cài đặt bảo mật'),
              subtitle: const Text('Mật khẩu và xác thực'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to security settings
              },
            ),
          ),
          CustomCard(
            child: ListTile(
              leading: const Icon(Icons.switch_account),
              title: const Text('Chuyển sang giao diện người dùng'),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/user_home', (route) => false);
              },
            ),
          ),
          CustomCard(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: _showLogoutDialog,
            ),
          ),
        ],
      ),
    );
  }
}