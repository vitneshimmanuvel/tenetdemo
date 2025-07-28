import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserPreferences {
  static const String _userKey = 'user';
  static const String _userTypeKey = 'user_type';
  static const String _isLoggedInKey = 'is_logged_in';

  // Save user data
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
    await prefs.setBool(_isLoggedInKey, true);

    // Save user type for easy access
    if (user['role'] != null) {
      await prefs.setString(_userTypeKey, user['role']);
    }
  }

  // Get user data
  static Future<Map<String, dynamic>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    return userString != null ? jsonDecode(userString) : {};
  }

  // Save user type (tenant, landlord, admin)
  static Future<void> saveUserType(String userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTypeKey, userType);
  }

  // Get user type
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get user ID
  static Future<int?> getUserId() async {
    final user = await getUser();
    return user['id'] as int?;
  }

  // Get user name
  static Future<String?> getUserName() async {
    final user = await getUser();
    return user['name'] as String?;
  }

  // Get user email
  static Future<String?> getUserEmail() async {
    final user = await getUser();
    return user['email'] as String?;
  }

  // Get user phone
  static Future<String?> getUserPhone() async {
    final user = await getUser();
    return user['phone'] as String?;
  }

  // Check if landlord is verified
  static Future<bool> isLandlordVerified() async {
    final user = await getUser();
    return user['verified'] ?? false;
  }

  // Check if landlord is approved by admin
  static Future<bool> isLandlordApproved() async {
    final user = await getUser();
    return user['adminApproved'] ?? false;
  }

  // Get tenancy ID for tenants
  static Future<String?> getTenancyId() async {
    final user = await getUser();
    return user['tenancyId'] as String?;
  }

  // Get landlord address details
  static Future<Map<String, String?>> getLandlordAddress() async {
    final user = await getUser();
    return {
      'address': user['address'] as String?,
      'city': user['city'] as String?,
      'postalCode': user['postalCode'] as String?,
    };
  }

  // Clear all user data (for logout)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_userTypeKey);
    await prefs.remove(_isLoggedInKey);
  }

  // Clear only user data but keep login state
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_userTypeKey);
  }

  // Update specific user field
  static Future<void> updateUserField(String key, dynamic value) async {
    final user = await getUser();
    user[key] = value;
    await saveUser(user);
  }

  // Update landlord verification status
  static Future<void> updateVerificationStatus(bool verified) async {
    await updateUserField('verified', verified);
  }

  // Update landlord approval status
  static Future<void> updateApprovalStatus(bool approved) async {
    await updateUserField('adminApproved', approved);
  }

  // Check if user has specific role
  static Future<bool> isAdmin() async {
    final userType = await getUserType();
    return userType == 'admin';
  }

  static Future<bool> isTenant() async {
    final userType = await getUserType();
    return userType == 'tenant';
  }

  static Future<bool> isLandlord() async {
    final userType = await getUserType();
    return userType == 'landlord';
  }

  // Check if landlord can access dashboard
  static Future<bool> canAccessLandlordDashboard() async {
    if (!await isLandlord()) return false;

    final verified = await isLandlordVerified();
    final approved = await isLandlordApproved();

    return verified && approved;
  }

  // Get landlord status for UI display
  static Future<Map<String, dynamic>> getLandlordStatus() async {
    if (!await isLandlord()) {
      return {'canAccess': false, 'status': 'not_landlord'};
    }

    final verified = await isLandlordVerified();
    final approved = await isLandlordApproved();

    if (!verified) {
      return {
        'canAccess': false,
        'status': 'pending_verification',
        'message': 'Please verify your email address'
      };
    }

    if (!approved) {
      return {
        'canAccess': false,
        'status': 'pending_approval',
        'message': 'Your account is waiting for admin approval'
      };
    }

    return {
      'canAccess': true,
      'status': 'approved',
      'message': 'Account approved and ready'
    };
  }

  // Save temporary user data during registration process
  static Future<void> saveTempUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temp_user_data', jsonEncode(userData));
  }

  // Get temporary user data
  static Future<Map<String, dynamic>?> getTempUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final tempData = prefs.getString('temp_user_data');
    return tempData != null ? jsonDecode(tempData) : null;
  }

  // Clear temporary user data
  static Future<void> clearTempUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('temp_user_data');
  }
}