import 'package:appgiaohang/config/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../components/app_bar/custom_app_bar.dart';
import '../components/buttons/custom_elevated_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOTPSent = false;

  Future<void> _sendOTP() async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseurl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
        }),
      );

      if (response.statusCode == 200) {
        setState(() => _isOTPSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to your email!!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send OTP')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('${Config.baseurl}/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text,
            'password': _passwordController.text,
            'fullName': _fullNameController.text,
            'phoneNumber': _phoneController.text,
            'otp': _otpController.text,
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration failed')),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color.fromARGB(255, 225, 140, 22), Color.fromARGB(255, 204, 146, 52)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0), // reduced vertical padding
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10), // reduced margin
              padding: const EdgeInsets.all(15), // reduced padding
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10), // reduced spacing
                    const Text(
                      'Tạo tài khoản',
                      style: TextStyle(
                        fontSize: 24, // reduced font size
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15), // reduced spacing
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          suffixIcon: !_isOTPSent
                              ? IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: _sendOTP,
                                )
                              : const Icon(Icons.check, color: Colors.green),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Hãy nhập email' : null,
                      ),
                    ),
                    const SizedBox(height: 12), // reduced spacing between fields
                    if (_isOTPSent)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          controller: _otpController,
                          decoration: const InputDecoration(
                            labelText: 'Gửi OTP',
                            prefixIcon: Icon(Icons.password),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Nhập OTP được gửi về gmail của bạn' : null,
                        ),
                      ),
                    const SizedBox(height: 12), // reduced spacing between fields
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Mât khẩu',
                          prefixIcon: Icon(Icons.lock),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        obscureText: true,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Hãy nhập mật khẩu' : null,
                      ),
                    ),
                    const SizedBox(height: 12), // reduced spacing between fields
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Xác nhận mật khẩu',
                          prefixIcon: Icon(Icons.lock),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Hãy xác nhận mật khẩu';
                          }
                          if (value != _passwordController.text) {
                            return 'Mật khẩu không khớp';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12), // reduced spacing between fields
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên',
                          prefixIcon: Icon(Icons.person),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Hãy nhập họ và tên'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12), // reduced spacing between fields
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: Icon(Icons.phone),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Hãy nhập số điện thoại'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12), // reduced spacing between fields
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Đăng ký',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12), // reduced spacing between fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Đã có tài khoản?"),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đăng nhập'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
