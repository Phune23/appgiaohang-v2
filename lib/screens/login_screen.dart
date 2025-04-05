import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../components/app_bar/custom_app_bar.dart';
import '../components/buttons/custom_elevated_button.dart';
import '../config/config.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../utils/shared_prefs.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _requestNotificationPermission() async {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Notification permission status: ${settings.authorizationStatus}');
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        final response = await http.post(
          Uri.parse('${Config.baseurl}/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text,
            'password': _passwordController.text,
            'fcmToken': fcmToken,
          }),
        );

        print(response.statusCode);
        if (response.statusCode == 200) {
          final userData = jsonDecode(response.body);
          await SharedPrefs.saveUserId(userData['id']); // Add this line

          // Save user data
          await AuthProvider.saveUserData(userData);
          
          // Check and request notification permissions after login
          await checkAndRequestNotificationPermissions(context);

          if (!mounted) return;

          // Check if we can pop back to previous screen

          // If no previous screen, navigate based on role
          switch (userData['role']) {
            case 'admin':
              Navigator.pushNamedAndRemoveUntil(
                  context, '/admin', (route) => false);
              break;
            case 'user':
              if (Navigator.canPop(context)) {
                Navigator.pop(context, true);
              } else {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/user_home', (route) => false);
              }
              break;
            case 'shipper':
              Navigator.pushNamedAndRemoveUntil(
                  context, '/shipper', (route) => false);
              break;
            default:
              throw Exception('Invalid role');
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.body),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        print(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.fromARGB(255, 225, 140, 22), Color.fromARGB(255, 204, 146, 52)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              padding: const EdgeInsets.all(20),
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
                    const SizedBox(height: 40),
                    // Image.asset(
                    //   'assets/images/logo.png', // Add your logo image
                    //   height: 120,
                    // ),
                    const SizedBox(height: 40),
                    const Text(
                      'Chào mừng trở lại!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Hãy nhập email' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: Icon(Icons.lock),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        obscureText: true,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Hãy nhập mật khẩu' : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Chưa có tài khoản?"),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: const Text('Đăng ký'),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Bạn muốn trở thành tài xế?"),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/shipper-registration'),
                          child: const Text('Đăng ký tài xế'),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/forgot-password'),
                      child: const Text('Quên mật khẩu?'),
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
}
