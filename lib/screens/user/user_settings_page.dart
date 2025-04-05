import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/app_bar/custom_app_bar.dart';
import '../../components/switch_list_tile/custom_switch_list_tile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  bool notificationsEnabled = true;
  // bool darkModeEnabled = false;
  String selectedLanguage = 'English';
  bool showLogout = false;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final userId = await AuthProvider.getUserId();
    final userRole = await AuthProvider.getUserRole();
    setState(() {
      showLogout = userId != null;
      isAdmin = userRole == 'admin';
    });
  }

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                await AuthProvider.logout();
                if (!mounted) return;
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/user_home', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Cài đặt'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsSection(
              'Tùy chỉnh ứng dụng',
              [
                CustomSwitchListTile(
                  title: 'Thông báo',
                  subtitle: 'Bật/tắt thông báo',
                  value: notificationsEnabled,
                  onChanged: (value) =>
                      setState(() => notificationsEnabled = value),
                ),
                const Divider(height: 1),
                CustomSwitchListTile(
                  title: 'Chế độ tối',
                  subtitle: 'Bật/tắt giao diện tối',
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(),
                ),
              ],
            ),
            _buildSettingsSection(
              'Tài khoản',
              [
                ListTile(
                  leading: const Icon(Icons.store),
                  title: const Text('Cửa hàng của tôi'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.pushNamed(context, '/my-store'),
                ),
                if (isAdmin) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Chuyển sang giao diện Admin'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/admin', (route) => false),
                  ),
                ],
              ],
            ),
            if (showLogout)
              _buildSettingsSection(
                'Khác',
                [
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Đăng xuất',
                        style: TextStyle(color: Colors.red)),
                    onTap: _showLogoutDialog,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
