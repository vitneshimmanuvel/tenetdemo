class ApiPaths {
  // Update this to match your server URL
  static const String baseUrl = 'http://localhost:3001'; // Change to your server URL

  // Authentication endpoints
  static const String login = '$baseUrl/api/login';
  static const String registerLandlord = '$baseUrl/api/register/landlord';
  static const String registerTenant = '$baseUrl/api/register/tenant';
  static const String sendOtp = '$baseUrl/api/send-otp';
  static const String verifyOtp = '$baseUrl/api/verify-otp';
  static const String resetPassword = '$baseUrl/api/reset-password';

  // Admin endpoints
  static const String adminRegister = '$baseUrl/api/admin/register';
  static const String adminLogin = '$baseUrl/api/admin/login';
  static const String adminStats = '$baseUrl/api/admin/stats';
  static const String adminTenants = '$baseUrl/api/admin/tenants';
  static const String adminLandlords = '$baseUrl/api/admin/landlords';
  static const String adminTenantDetails = '$baseUrl/api/admin/tenant';
  static const String adminLandlordDetails = '$baseUrl/api/admin/landlord';
  static const String adminPendingLandlords = '$baseUrl/api/admin/pending-landlords';
  static const String adminPendingProperties = '$baseUrl/api/admin/pending-properties';
  static const String adminVerifyLandlord = '$baseUrl/api/admin/verify-landlord';
  static const String adminVerifyProperty = '$baseUrl/api/admin/verify-property';

  // Property endpoints
  static const String propertyRequest = '$baseUrl/api/properties/request';
  static const String landlordProperties = '$baseUrl/api/landlord'; // /{id}/properties

  // Utility endpoints
  static const String health = '$baseUrl/api/health';
  static const String testTables = '$baseUrl/api/test/tables';
}