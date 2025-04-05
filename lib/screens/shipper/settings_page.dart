import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                await AuthProvider.logout();
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                    context, '/user_home', (route) => false);
              },
              child:
                  const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade700],
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 40, color: Colors.blue.shade700),
                    ),
                    const SizedBox(width: 15),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tài xế',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Quản lý tài khoản của bạn',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSettingsGroup(
              'Tài khoản',
              [
                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: 'Thông tin cá nhân',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.security,
                  title: 'Bảo mật',
                  onTap: () {},
                ),
              ],
            ),
            _buildSettingsGroup(
              'Ứng dụng',
              [
                _buildSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Thông báo',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.language,
                  title: 'Ngôn ngữ',
                  trailing: 'Tiếng Việt',
                  onTap: () {},
                ),
              ],
            ),
            _buildSettingsGroup(
              'Khác',
              [
                _buildSettingsTile(
                  icon: Icons.help_outline,
                  title: 'Trợ giúp & Hỗ trợ',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: 'Về ứng dụng',
                  trailing: 'v1.0.0',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.logout,
                  title: 'Đăng xuất',
                  titleColor: Colors.red,
                  onTap: (context) => _handleLogout(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...tiles,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? trailing,
    required Function onTap,
    Color? titleColor,
  }) {
    return Builder(
      builder: (BuildContext context) => ListTile(
        leading: Icon(icon, color: Colors.blue.shade700),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing != null
            ? Text(trailing, style: const TextStyle(color: Colors.grey))
            : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => onTap(context),
      ),
    );
  }
}
