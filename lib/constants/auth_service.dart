import 'dart:convert';
import 'package:http/http.dart' as http;
import '/constants/api_paths.dart';

class AuthService {
  // =================== AUTHENTICATION ===================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiPaths.login),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': data['user'],
          'message': data['message'] ?? 'Login successful'
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'requiresApproval': data['requiresApproval'] ?? false,
          'requiresVerification': data['requiresVerification'] ?? false,
          'isVerified': data['isVerified'] ?? false,
          'message': data['error'] ?? 'Account access denied'
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Login failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e'
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
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'purpose': purpose,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Failed to send OTP'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e'
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
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
          'purpose': purpose,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        Map<String, dynamic> result = {
          'success': true,
          'message': data['message'] ?? 'OTP verified successfully'
        };

        // Add optional fields if they exist
        if (data['resetToken'] != null) result['resetToken'] = data['resetToken'];
        if (data['user'] != null) result['user'] = data['user'];
        if (data['admin'] != null) result['admin'] = data['admin'];

        return result;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'OTP verification failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e'
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
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'resetToken': resetToken,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Password reset failed'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  // =================== REGISTRATION ===================

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
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'address': address,
          'postalCode': postalCode,
          'city': city,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful! OTP sent to your email'
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e'
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
      print('🔄 Making API call to register tenant...');

      final response = await http.post(
        Uri.parse(ApiPaths.registerTenant),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Return the exact response from backend
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Unknown response',
          'tenantId': data['tenantId'], // Include tenantId if present
        };
      } else {
        // Handle non-200/201 status codes
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed. Server error.'
        };
      }
    } catch (e) {
      print('❌ Network error in registerTenant: $e');

      String errorMessage = 'Network error. Please check your connection.';

      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout. Please try again.';
      } else if (e.toString().contains('connection') || e.toString().contains('SocketException')) {
        errorMessage = 'Network connection failed. Please check your internet.';
      }

      return {
        'success': false,
        'message': errorMessage
      };
    }
  }

  // =================== ADMIN METHODS ===================

  static Future<Map<String, dynamic>> registerAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiPaths.adminRegister),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Admin registration failed'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e'
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
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'admin': data['admin'],
          'message': data['message'] ?? 'Admin login successful'
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Admin login failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await http.get(
        Uri.parse(ApiPaths.adminStats),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'totalTenants': _parseToInt(data['totalTenants']),
          'totalLandlords': _parseToInt(data['totalLandlords']),
          'totalProperties': _parseToInt(data['totalProperties']),
        };
      } else {
        throw Exception('Failed to get stats: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'totalTenants': 0,
        'totalLandlords': 0,
        'totalProperties': 0,
        'message': 'Failed to load stats: $e'
      };
    }
  }


  static Future<List<Map<String, dynamic>>> getAllTenants() async {
    try {
      final response = await http.get(
        Uri.parse(ApiPaths.adminTenants),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['tenants'] is List) {
          return List<Map<String, dynamic>>.from(
              data['tenants'].map((item) => Map<String, dynamic>.from(item))
          );
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllLandlords() async {
    try {
      final response = await http.get(
        Uri.parse(ApiPaths.adminLandlords), // CORRECTED ROUTE
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['landlords'] is List) {
          return List<Map<String, dynamic>>.from(
              data['landlords'].map((item) => Map<String, dynamic>.from(item))
          );
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getTenantDetails(String tenantId) async {
    try {
      print('🔍 Getting tenant details for: $tenantId');

      final response = await http.get(
        Uri.parse('${ApiPaths.adminTenantDetails}/$tenantId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('📊 Tenant details response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'tenant': data['tenant'] ?? {},
          'ratings': data['ratings'] is List
              ? List<Map<String, dynamic>>.from(
              data['ratings'].map((item) => Map<String, dynamic>.from(item))
          )
              : [],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'tenant': {},
          'ratings': [],
          'message': errorData['error'] ?? 'Failed to get tenant details'
        };
      }
    } catch (e) {
      print('❌ Get tenant details error: $e');
      return {
        'success': false,
        'tenant': {},
        'ratings': [],
        'message': 'Network error: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> getLandlordDetails(String landlordId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiPaths.adminLandlordDetails}/$landlordId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'landlord': data['landlord'] ?? {},
          'properties': data['properties'] is List
              ? List<Map<String, dynamic>>.from(
              data['properties'].map((item) => Map<String, dynamic>.from(item))
          )
              : [],
        };
      } else {
        return {
          'success': false,
          'landlord': {},
          'properties': [],
          'message': 'Failed to get landlord details'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'landlord': {},
        'properties': [],
        'message': 'Network error: $e'
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingLandlords() async {
    try {
      final response = await http.get(
        Uri.parse(ApiPaths.adminPendingLandlords), // NOW EXISTS IN SERVER
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['landlords'] is List) {
          return List<Map<String, dynamic>>.from(
              data['landlords'].map((item) => Map<String, dynamic>.from(item))
          );
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingProperties() async {
    try {
      final response = await http.get(
        Uri.parse(ApiPaths.adminPendingProperties),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['properties'] is List) {
          return List<Map<String, dynamic>>.from(
              data['properties'].map((item) => Map<String, dynamic>.from(item))
          );
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> verifyLandlord(int landlordId, bool approve) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiPaths.adminVerifyLandlord}/$landlordId'), // CORRECTED ROUTE
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'approve': approve}),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? (approve ? 'Landlord approved' : 'Landlord rejected')
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }


  static Future<Map<String, dynamic>> verifyProperty(int propertyId, bool approve) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiPaths.adminVerifyProperty}/$propertyId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'approve': approve}),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? (approve ? 'Property approved' : 'Property rejected')
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  // =================== LANDLORD METHODS ===================

  static Future<Map<String, dynamic>> getLandlordProfile(int landlordId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiPaths.landlordProfile(landlordId)),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'profile': data['profile']
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to get profile'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> updateLandlordProfile({
    required int landlordId,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiPaths.updateLandlordProfile(landlordId)),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'phone': phone,
          'address': address,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'profile': data['profile'],
          'message': data['message'] ?? 'Profile updated successfully'
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to update profile'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> addProperty({
    required int landlordId,
    required String address,
    required String street,
    required String city,
    required String postalCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiPaths.addProperty),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'landlordId': landlordId,
          'address': address,
          'street': street,
          'city': city,
          'postalCode': postalCode,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Property request submitted for admin approval',
          'propertyId': data['propertyId']
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to add property'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> getLandlordProperties(int landlordId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiPaths.landlordProperties(landlordId)),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'properties': data['properties'] ?? []
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to get properties',
          'properties': []
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'properties': []
      };
    }
  }

  static Future<Map<String, dynamic>> searchTenant({
    required String query,
    required int landlordId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiPaths.landlordSearchTenant}?query=$query&landlordId=$landlordId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final tenants = List<Map<String, dynamic>>.from(data['tenants'] ?? []);

        return {
          'success': true,
          'tenants': tenants
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to search tenants',
          'tenants': []
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'tenants': []
      };
    }
  }




// Get search history for landlord
  static Future<Map<String, dynamic>> getSearchHistory(int landlordId) async {
    try {
      print('🔍 Getting search history for landlord: $landlordId');

      final response = await http.get(
        Uri.parse(ApiPaths.landlordSearchHistory(landlordId)),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);
      print('📊 Search history response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'searchHistory': data['searchHistory'] ?? []
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to get search history',
          'searchHistory': []
        };
      }
    } catch (e) {
      print('❌ Search history error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'searchHistory': []
      };
    }
  }



  static Future<Map<String, dynamic>> getTenantRatings(int tenantId) async {
    try {
      print('📋 Getting tenant ratings for: $tenantId');

      final response = await http.get(
        Uri.parse(ApiPaths.tenantRatings(tenantId)),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);
      print('📊 Tenant ratings response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'tenant': data['tenant'] ?? {},
          'ratings': data['ratings'] ?? [],
          'lastTwoStays': data['lastTwoStays'] ?? data['ratings'] ?? []
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to get tenant ratings',
          'tenant': {},
          'ratings': [],
          'lastTwoStays': []
        };
      }
    } catch (e) {
      print('❌ Tenant ratings error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'tenant': {},
        'ratings': [],
        'lastTwoStays': []
      };
    }
  }

  static Future<Map<String, dynamic>> getPropertyHistory(int propertyId) async {
    try {
      print('🏠 Getting property history for: $propertyId');

      final response = await http.get(
        Uri.parse(ApiPaths.propertyHistory(propertyId)),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);
      print('📊 Property history response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'history': data['history'] ?? []
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to get property history',
          'history': []
        };
      }
    } catch (e) {
      print('❌ Property history error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'history': []
      };
    }
  }


  static Future<Map<String, dynamic>> rateTenant({
    required int tenantId,
    required int landlordId,
    required int propertyId,
    required int rentPayment,
    required int communication,
    required int propertyCare,
    required int utilities,
    required bool respectOthers,
    required int propertyHandover,
    required String comments,
    required String stayPeriodStart,
    String? stayPeriodEnd,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiPaths.rateTenant),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'tenantId': tenantId,
          'landlordId': landlordId,
          'propertyId': propertyId,
          'rentPayment': rentPayment,
          'communication': communication,
          'propertyCare': propertyCare,
          'utilities': utilities,
          'respectOthers': respectOthers,
          'propertyHandover': propertyHandover,
          'comments': comments,
          'stayPeriodStart': stayPeriodStart,
          'stayPeriodEnd': stayPeriodEnd,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Tenant rating submitted successfully',
          'ratingId': data['ratingId']
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to submit rating'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  // =================== TENANT METHODS ===================

  static Future<Map<String, dynamic>> getTenantProfile(int tenantId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiPaths.tenantProfile(tenantId)),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'profile': data['profile']
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to get tenant profile'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }





  // =================== UTILITY METHODS ===================

  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String _parseToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }
}
