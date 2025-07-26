// constants/api_paths.dart
class ApiPaths {
  // Update this with your ngrok URL when you run ngrok
  static const baseUrl = 'http://localhost:3001'; // Change to your ngrok URL
  static const registerLandlord = '$baseUrl/api/register/landlord';
  static const registerTenant = '$baseUrl/api/register/tenant';
  static const login = '$baseUrl/api/login';
  static const sendOtp = '$baseUrl/api/send-otp';
  static const verifyOtp = '$baseUrl/api/verify-otp';
  static const resetPassword = '$baseUrl/api/reset-password';

  // Admin endpoints
  static const adminRegister = '$baseUrl/api/admin/register';
  static const adminLogin = '$baseUrl/api/admin/login';
  static const adminStats = '$baseUrl/api/admin/stats';
  static const adminPendingLandlords = '$baseUrl/api/admin/pending-landlords';
  static const adminPendingProperties = '$baseUrl/api/admin/pending-properties';
  static const adminVerifyLandlord = '$baseUrl/api/admin/verify-landlord';
  static const adminVerifyProperty = '$baseUrl/api/admin/verify-property';
}