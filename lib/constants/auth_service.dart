import 'dart:convert';
import 'package:http/http.dart' as http;
import '/constants/api_paths.dart'; // Update with your actual path

class AuthService {
  static Future<Map<String, dynamic>> registerLandlord({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String address,
    required String postalCode,
    required String city,
  }) async {
    final response = await http.post(
      Uri.parse(ApiPaths.registerLandlord),
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'address': address,
        'postalCode': postalCode,
        'city': city,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> registerTenant({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiPaths.registerTenant),
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiPaths.login),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed: ${response.statusCode} - ${response.body}'
      );
    }
  }

  static Future<Map<String, dynamic>> sendOtp({
    required String email,
    required String purpose, // 'login' or 'reset'
  }) async {
    final response = await http.post(
      Uri.parse(ApiPaths.sendOtp),
      body: jsonEncode({
        'email': email,
        'purpose': purpose,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    required String purpose,
  }) async {
    final response = await http.post(
      Uri.parse(ApiPaths.verifyOtp),
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'purpose': purpose,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse(ApiPaths.resetPassword),
      body: jsonEncode({
        'email': email,
        'resetToken': resetToken,
        'newPassword': newPassword,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    return _handleResponse(response);
  }
}