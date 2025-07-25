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
  static const adminLogin = '$baseUrl/api/admin/login';
  static const getPendingLandlords = '$baseUrl/api/admin/pending-landlords';
  static const approveLandlord = '$baseUrl/api/admin/approve-landlord';
  static const rejectLandlord = '$baseUrl/api/admin/reject-landlord';
}