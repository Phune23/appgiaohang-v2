import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../components/app_bar/custom_app_bar.dart';
import '../../components/buttons/custom_elevated_button.dart';
import '../../config/config.dart';

class ShipperRegistrationScreen extends StatefulWidget {
  const ShipperRegistrationScreen({super.key});

  @override
  State<ShipperRegistrationScreen> createState() => _ShipperRegistrationScreenState();
}

class _ShipperRegistrationScreenState extends State<ShipperRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _licensePlateController = TextEditingController();

  Future<void> _registerShipper() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('${Config.baseurl}/auth/shipper/register'), // Remove 'api' prefix
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user': {
              'name': _nameController.text,
              'email': _emailController.text,
              'password': _passwordController.text,
              'role': 'shipper',
            },
            'shipper': {
              'phone': _phoneController.text,
              'vehicleType': _vehicleTypeController.text,
              'licensePlate': _licensePlateController.text,
              'status': 'pending' // Add status for admin approval
            }
          }),
        );

        if (!mounted) return;

        if (response.statusCode == 201) { // Changed to 201 for created
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Registration Submitted'),
              content: const Text('Your registration request has been submitted. You will receive an email when the admin reviews your application.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Ký Tài Xế',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.white],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Thông Tin Đăng Ký',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Họ và tên',
                          icon: Icons.person,
                          validator: (value) => value?.isEmpty ?? true 
                            ? 'Vui lòng nhập họ tên' : null,
                        ),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => value?.isEmpty ?? true 
                            ? 'Vui lòng nhập email' : null,
                        ),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Số điện thoại',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) => value?.isEmpty ?? true 
                            ? 'Vui lòng nhập số điện thoại' : null,
                        ),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Mật khẩu',
                          icon: Icons.lock,
                          obscureText: true,
                          validator: (value) => value?.isEmpty ?? true 
                            ? 'Vui lòng nhập mật khẩu' : null,
                        ),
                        _buildTextField(
                          controller: _vehicleTypeController,
                          label: 'Loại xe',
                          icon: Icons.directions_bike,
                          validator: (value) => value?.isEmpty ?? true 
                            ? 'Vui lòng nhập loại xe' : null,
                        ),
                        _buildTextField(
                          controller: _licensePlateController,
                          label: 'Biển số xe',
                          icon: Icons.confirmation_number,
                          validator: (value) => value?.isEmpty ?? true 
                            ? 'Vui lòng nhập biển số xe' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CustomElevatedButton(
                  onPressed: _registerShipper,
                  text: 'Đăng Ký Ngay',
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: validator,
      ),
    );
  }
}
