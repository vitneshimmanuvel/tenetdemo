// services/user_preferences.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // ADD THIS IMPORT

class UserPreferences {
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user)); // Now works
  }

  static Future<Map<String, dynamic>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    return userString != null ? jsonDecode(userString) : {}; // Now works
  }
}