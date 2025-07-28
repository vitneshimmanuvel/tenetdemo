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
      print('Starting landlord registration...'); // Debug log
      print('API URL: ${ApiPaths.registerLandlord}'); // Debug log

      final requestBody = {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'address': address,
        'postalCode': postalCode,
        'city': city,
      };

      print('Request body: $requestBody'); // Debug log

      final response = await http.post(
        Uri.parse(ApiPaths.registerLandlord),
        body: jsonEncode(requestBody),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
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
      print('Registration error: $e'); // Debug log
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
        return {
          'success': true,
          'user': data['user'],
          'message': data['message'],
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'requiresApproval': data['requiresApproval'] ?? false,
          'requiresVerification': data['requiresVerification'] ?? false,
          'isVerified': data['isVerified'] ?? false,
          'message': data['error'] ?? 'Account access denied',
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
      print('Sending OTP to: $email for purpose: $purpose'); // Debug log

      final response = await http.post(
        Uri.parse(ApiPaths.sendOtp),
        body: jsonEncode({
          'email': email,
          'purpose': purpose,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('OTP Response status: ${response.statusCode}'); // Debug log
      print('OTP Response body: ${response.body}'); // Debug log

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Failed to send OTP',
      };
    } catch (e) {
      print('Send OTP error: $e'); // Debug log
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
      print('Verifying OTP for: $email with purpose: $purpose'); // Debug log

      final response = await http.post(
        Uri.parse(ApiPaths.verifyOtp),
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'purpose': purpose,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('Verify OTP Response status: ${response.statusCode}'); // Debug log
      print('Verify OTP Response body: ${response.body}'); // Debug log

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Map<String, dynamic> result = {
          'success': true,
          'message': data['message'],
        };

        // Handle different purposes response data
        if (data['resetToken'] != null) {
          result['resetToken'] = data['resetToken'];
        }

        if (data['user'] != null) {
          result['user'] = data['user'];
        }

        if (data['admin'] != null) {
          result['admin'] = data['admin'];
        }

        return result;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'OTP verification failed',
        };
      }
    } catch (e) {
      print('Verify OTP error: $e'); // Debug log
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
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Password reset failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ========== ADMIN METHODS ==========

  static Future<Map<String, dynamic>> registerAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiPaths.adminRegister),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Admin registration failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

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

  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      print('Fetching admin stats from: ${ApiPaths.adminStats}');

      final response = await http.get(
        Uri.parse(ApiPaths.adminStats),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('Stats response status: ${response.statusCode}');
      print('Stats response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Ensure we have proper integer values
        return {
          'totalTenants': _parseToInt(data['totalTenants']),
          'totalLandlords': _parseToInt(data['totalLandlords']),
          'totalProperties': _parseToInt(data['totalProperties']),
        };
      } else {
        print('Stats API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Get admin stats error: $e');
      // Return default values on error
      return {
        'totalTenants': 0,
        'totalLandlords': 0,
        'totalProperties': 0,
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingLandlords() async {
    try {
      print('Fetching pending landlords from: ${ApiPaths.adminPendingLandlords}');

      final response = await http.get(
        Uri.parse(ApiPaths.adminPendingLandlords),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('Pending landlords response status: ${response.statusCode}');
      print('Pending landlords response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Safely handle the landlords array
        if (data is Map<String, dynamic> && data['landlords'] is List) {
          return List<Map<String, dynamic>>.from(
              data['landlords'].map((item) => Map<String, dynamic>.from(item))
          );
        } else {
          print('Unexpected response format for pending landlords');
          return [];
        }
      } else {
        print('Pending landlords API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get pending landlords: ${response.statusCode}');
      }
    } catch (e) {
      print('Get pending landlords error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingProperties() async {
    try {
      print('Fetching pending properties from: ${ApiPaths.adminPendingProperties}');

      final response = await http.get(
        Uri.parse(ApiPaths.adminPendingProperties),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('Pending properties response status: ${response.statusCode}');
      print('Pending properties response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Safely handle the properties array
        if (data is Map<String, dynamic> && data['properties'] is List) {
          return List<Map<String, dynamic>>.from(
              data['properties'].map((item) => Map<String, dynamic>.from(item))
          );
        } else {
          print('Unexpected response format for pending properties');
          return [];
        }
      } else {
        print('Pending properties API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get pending properties: ${response.statusCode}');
      }
    } catch (e) {
      print('Get pending properties error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllTenants() async {
    try {
      print('Fetching all tenants from: ${ApiPaths.adminTenants}');

      final response = await http.get(
        Uri.parse(ApiPaths.adminTenants),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('All tenants response status: ${response.statusCode}');
      print('All tenants response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Safely handle the tenants array
        if (data is Map<String, dynamic> && data['tenants'] is List) {
          return List<Map<String, dynamic>>.from(
              data['tenants'].map((item) => Map<String, dynamic>.from(item))
          );
        } else {
          print('Unexpected response format for tenants');
          return [];
        }
      } else {
        print('Tenants API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get tenants: ${response.statusCode}');
      }
    } catch (e) {
      print('Get tenants error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllLandlords() async {
    try {
      print('Fetching all landlords from: ${ApiPaths.adminLandlords}');

      final response = await http.get(
        Uri.parse(ApiPaths.adminLandlords),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('All landlords response status: ${response.statusCode}');
      print('All landlords response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Safely handle the landlords array
        if (data is Map<String, dynamic> && data['landlords'] is List) {
          return List<Map<String, dynamic>>.from(
              data['landlords'].map((item) => Map<String, dynamic>.from(item))
          );
        } else {
          print('Unexpected response format for landlords');
          return [];
        }
      } else {
        print('Landlords API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get landlords: ${response.statusCode}');
      }
    } catch (e) {
      print('Get landlords error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getTenantDetails(String tenantId) async {
    try {
      print('Fetching tenant details for ID: $tenantId');

      final response = await http.get(
        Uri.parse('${ApiPaths.adminTenantDetails}/$tenantId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('Tenant details response status: ${response.statusCode}');
      print('Tenant details response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'tenant': data['tenant'] ?? {},
          'ratings': data['ratings'] is List
              ? List<Map<String, dynamic>>.from(
              data['ratings'].map((item) => Map<String, dynamic>.from(item))
          )
              : [],
        };
      } else {
        print('Tenant details API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get tenant details: ${response.statusCode}');
      }
    } catch (e) {
      print('Get tenant details error: $e');
      return {
        'tenant': {},
        'ratings': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getLandlordDetails(String landlordId) async {
    try {
      print('Fetching landlord details for ID: $landlordId');

      final response = await http.get(
        Uri.parse('${ApiPaths.adminLandlordDetails}/$landlordId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('Landlord details response status: ${response.statusCode}');
      print('Landlord details response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'landlord': data['landlord'] ?? {},
          'properties': data['properties'] is List
              ? List<Map<String, dynamic>>.from(
              data['properties'].map((item) => Map<String, dynamic>.from(item))
          )
              : [],
        };
      } else {
        print('Landlord details API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get landlord details: ${response.statusCode}');
      }
    } catch (e) {
      print('Get landlord details error: $e');
      return {
        'landlord': {},
        'properties': [],
      };
    }
  }

  static Future<void> verifyLandlord(int landlordId, bool approve) async {
    try {
      print('${approve ? 'Approving' : 'Rejecting'} landlord ID: $landlordId');

      final response = await http.post(
        Uri.parse('${ApiPaths.adminVerifyLandlord}/$landlordId'),
        body: jsonEncode({'approve': approve}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('Verify landlord response status: ${response.statusCode}');
      print('Verify landlord response body: ${response.body}');

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to verify landlord');
      }
    } catch (e) {
      print('Verify landlord error: $e');
      throw Exception('Failed to verify landlord: $e');
    }
  }

  static Future<void> verifyProperty(int propertyId, bool approve) async {
    try {
      print('${approve ? 'Approving' : 'Rejecting'} property ID: $propertyId');

      final response = await http.post(
        Uri.parse('${ApiPaths.adminVerifyProperty}/$propertyId'),
        body: jsonEncode({'approve': approve}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('Verify property response status: ${response.statusCode}');
      print('Verify property response body: ${response.body}');

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to verify property');
      }
    } catch (e) {
      print('Verify property error: $e');
      throw Exception('Failed to verify property: $e');
    }
  }

  // ========== PROPERTY METHODS ==========

  static Future<Map<String, dynamic>> requestProperty({
    required int landlordId,
    required String address,
    required String street,
    required String city,
    required String postalCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiPaths.propertyRequest),
        body: jsonEncode({
          'landlordId': landlordId,
          'address': address,
          'street': street,
          'city': city,
          'postalCode': postalCode,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Property request submitted',
          'propertyId': data['propertyId'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to submit property request',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Helper method to safely parse integers
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }
}