import 'package:shared_preferences/shared_preferences.dart';
import '../utils/shared_prefs.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';

class AuthProvider {
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('userId');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final fcmToken = await FirebaseMessaging.instance.getToken();

    // Notify backend about logout to cleanup FCM token
    if (userId != null && fcmToken != null) {
      try {
        await http.post(
          Uri.parse('${Config.baseurl}/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'fcmToken': fcmToken,
          }),
        );
      } catch (e) {
        print('Error notifying backend about logout: $e');
      }
    }

    // Delete the token from Firebase Messaging
    await FirebaseMessaging.instance.deleteToken();
    
    // Clear local storage
    await SharedPrefs.clearAllData();
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userData['id']);
    await prefs.setString('role', userData['role']);
    await prefs.setString('email', userData['email']);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }
}