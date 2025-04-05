import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static const String userIdKey = 'userId';

  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(userIdKey, userId);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(userIdKey);
  }

  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userIdKey);
  }

  // Add methods to save and get selected address
  static const String selectedAddressKey = 'selectedAddress';

  static Future<void> saveSelectedAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(selectedAddressKey, address);
  }

  static Future<String?> getSelectedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(selectedAddressKey);
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // This will remove all data stored in SharedPreferences
  }
}
