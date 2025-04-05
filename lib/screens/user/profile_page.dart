import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../components/app_bar/custom_app_bar.dart';
import '../../components/buttons/custom_elevated_button.dart';
import '../../config/config.dart';
import '../../providers/auth_provider.dart';
import 'user_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<Map<String, dynamic>?> _userFuture = Future.value(null);

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final userId = await AuthProvider.getUserId();
    if (userId != null && mounted) {
      setState(() {
        _userFuture = getUserById(userId);
      });
    }
  }

  Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/auth/user/$userId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      print('Get user response: ${response.body}'); // Debug log
      return json.decode(response.body);
    } catch (e) {
      print('Get user error: $e'); // Debug log
      throw Exception('Failed to load user data');
    }
  }

  Future<void> _editProfile() async {
    final userData = await _userFuture;
    final TextEditingController nameController =
        TextEditingController(text: userData?['fullName'] ?? '');
    final TextEditingController phoneController =
        TextEditingController(text: userData?['phoneNumber'] ?? '');
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chỉnh Sửa Hồ Sơ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và Tên',
                  prefixIcon: Icon(Icons.person),
                ),
                enabled: !isLoading,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số Điện Thoại',
                  prefixIcon: Icon(Icons.phone),
                ),
                enabled: !isLoading,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Số điện thoại không được để trống';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(value!)) {
                    return 'Vui lòng nhập số điện thoại hợp lệ (10 số)';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty ||
                          phoneController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Vui lòng điền đầy đủ thông tin')),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final url = Uri.parse(
                            '${Config.baseurl}/auth/user/${userData?['id'] ?? ''}');
                        print('Sending PUT request to: $url'); // Debug log

                        final response = await http.put(
                          url,
                          headers: {
                            'Content-Type': 'application/json',
                            'Accept': 'application/json',
                          },
                          body: json.encode({
                            'fullName': nameController.text.trim(),
                            'phoneNumber': phoneController.text.trim(),
                          }),
                        );

                        print(
                            'Response headers: ${response.headers}'); // Debug log
                        print('Response status: ${response.statusCode}');
                        print('Response body: ${response.body}');

                        if (response.statusCode == 200) {
                          if (!mounted) return;
                          Navigator.pop(context);
                          setState(() {
                            _userFuture = getUserById(userData?['id'] ?? '');
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cập nhật hồ sơ thành công'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          var errorMessage = 'Failed to update profile';
                          try {
                            final errorData = json.decode(response.body);
                            errorMessage = errorData['error'] ?? errorMessage;
                          } catch (e) {
                            print('Error parsing response: $e');
                          }
                          throw Exception(errorMessage);
                        }
                      } catch (e) {
                        print('Update error: $e'); // Debug log
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Error: ${e.toString().replaceAll('Exception:', '')}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _buildLoginCard() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_circle,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn chưa đăng nhập',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(context, '/login');
                  if (result == true && mounted) {
                    _initializeUser(); // Reload user data after successful login
                  }
                },
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 350,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFFFF8C00),  // Bright orange
                Color(0xFFFF6B00),  // Deep orange
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 80, color: Color(0xFFFF8C00)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userData['fullName'] ?? '',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userData['email'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null) {
            return _buildLoginCard();
          }

          final userData = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(userData),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildInfoCard(
                        'Thông tin cá nhân',
                        [
                          _buildInfoTile(
                              Icons.email, 'Email', userData['email'] ?? ''),
                          _buildInfoTile(Icons.phone, 'Số điện thoại',
                              userData['phoneNumber'] ?? ''),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomElevatedButton(
                        onPressed: _editProfile,
                        text: 'Chỉnh sửa hồ sơ',
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserSettingsPage()),
          );
        },
        backgroundColor: const Color(0xFFFF8C00),
        child: const Icon(Icons.settings, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF8C00),
              ),
            ),
            const Divider(height: 25, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8C00).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: const Color(0xFFFF8C00)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
