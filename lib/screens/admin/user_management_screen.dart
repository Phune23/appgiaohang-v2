import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/config.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> users = [];
  bool isLoading = true;
  String? filterRole;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('${Config.baseurl}/users'));
      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body)['users'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  Future<void> updateUserStatus(int userId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.baseurl}/users/$userId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user status: $e')),
        );
      }
    }
  }

  Future<void> toggleUserActive(int userId, bool isActive) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.baseurl}/users/$userId/active'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'isActive': isActive}),
      );

      if (response.statusCode == 200) {
        fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user active status: $e')),
        );
      }
    }
  }

  Future<void> _createUser(
    String email,
    String password,
    String fullName,
    String phoneNumber,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseurl}/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'role': role,
        }),
      );

      if (response.statusCode == 201) {
        fetchUsers();
      } else {
        throw Exception(json.decode(response.body)['error']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating user: $e')),
        );
      }
    }
  }

  Future<void> _updateUser(
    int userId,
    String fullName,
    String phoneNumber,
    String role,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.baseurl}/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        fetchUsers();
      } else {
        throw Exception(json.decode(response.body)['error']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user: $e')),
        );
      }
    }
  }

  void _showUserDialog([Map<String, dynamic>? user]) {
    final isEditing = user != null;
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final nameController = TextEditingController(text: user?['full_name'] ?? '');
    final phoneController = TextEditingController(text: user?['phone_number'] ?? '');
    final passwordController = TextEditingController();
    String selectedRole = user?['role'] ?? 'user';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Sửa người dùng' : 'Thêm người dùng mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEditing)
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              if (!isEditing)
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('Người dùng')),
                  DropdownMenuItem(value: 'shipper', child: Text('Shipper')),
                  DropdownMenuItem(value: 'admin', child: Text('Quản trị')),
                ],
                onChanged: (value) => selectedRole = value!,
                decoration: const InputDecoration(labelText: 'Vai trò'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (isEditing) {
                await _updateUser(
                  user['id'],
                  nameController.text,
                  phoneController.text,
                  selectedRole,
                );
              } else {
                await _createUser(
                  emailController.text,
                  passwordController.text,
                  nameController.text,
                  phoneController.text,
                  selectedRole,
                );
              }
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(isEditing ? 'Lưu' : 'Tạo'),
          ),
        ],
      ),
    );
  }

  List<dynamic> getFilteredUsers() {
    return users.where((user) {
      final matchesSearch = user['full_name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
                          user['email'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      final matchesRole = filterRole == null || user['role'] == filterRole;
      return matchesSearch && matchesRole;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredUsers = getFilteredUsers();

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm theo tên hoặc email...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        onChanged: (value) => setState(() => searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: filterRole,
                        hint: const Text('Phân loại'),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Tất cả')),
                          DropdownMenuItem(value: 'user', child: Text('Khách hàng')),
                          DropdownMenuItem(value: 'shipper', child: Text('Người giao hàng')),
                          DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                        ],
                        onChanged: (value) => setState(() => filterRole = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _showUserDialog(),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Thêm người dùng mới'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          user['full_name']?[0]?.toUpperCase() ?? 'U',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        user['full_name'] ?? 'N/A',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        user['email'],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  user['role'] == 'user' ? 'Khách hàng' :
                                  user['role'] == 'admin' ? 'Quản trị viên' : 'Người giao hàng',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Trạng thái tài khoản',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Switch(
                                    value: user['is_active'] == 1,
                                    onChanged: (value) => toggleUserActive(user['id'], value),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _showUserDialog(user),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Chỉnh sửa'),
                                  ),
                                  const SizedBox(width: 12),
                                  FilledButton.icon(
                                    onPressed: () => toggleUserActive(user['id'], !user['is_active']),
                                    icon: Icon(user['is_active'] == 1 ? Icons.lock : Icons.lock_open),
                                    label: Text(user['is_active'] == 1 ? 'Khóa' : 'Mở khóa'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: user['is_active'] == 1
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
