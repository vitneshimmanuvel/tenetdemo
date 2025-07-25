import 'dart:convert';
import 'package:http/http.dart' as http;
import '/constants/api_paths.dart';
import '/screens/user_preferences.dart';

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
    try {
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

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent to your email',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> registerTenant({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
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

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiPaths.login),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Check if OTP is required
        if (data['requiresOtp'] == true) {
          return {
            'success': true,
            'requiresOtp': true,
            'email': data['email'],
            'role': data['role'],
            'message': data['message'],
          };
        }

        // Check if verification is required
        if (response.statusCode == 403 && data['requiresVerification'] == true) {
          return {
            'success': false,
            'requiresVerification': true,
            'message': data['message'],
          };
        }

        // Normal login success
        return {
          'success': true,
          'user': data['user'],
          'message': data['message'],
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'requiresVerification': data['requiresVerification'] ?? false,
          'message': data['message'] ?? 'Account not verified',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> sendOtp({
    required String email,
    required String purpose,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiPaths.sendOtp),
        body: jsonEncode({
          'email': email,
          'purpose': purpose,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Failed to send OTP',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    required String purpose,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiPaths.verifyOtp),
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'purpose': purpose,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Map<String, dynamic> result = {
          'success': true,
          'message': data['message'],
        };

        if (data['resetToken'] != null) {
          result['resetToken'] = data['resetToken'];
        }

        if (data['user'] != null) {
          result['user'] = data['user'];
        }

        return result;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'OTP verification failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiPaths.resetPassword),
        body: jsonEncode({
          'email': email,
          'resetToken': resetToken,
          'newPassword': newPassword,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Password reset failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Admin methods
  static Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiPaths.adminLogin),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'admin': data['admin'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Admin login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}