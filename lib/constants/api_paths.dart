  class ApiPaths {
    // Update this to match your server URL
    static const String baseUrl = 'https://tenetback.vercel.app';

    // Authentication endpoints
    static const String login = '$baseUrl/api/auth/login';
    static const String sendOtp = '$baseUrl/api/auth/send-otp';
    static const String verifyOtp = '$baseUrl/api/auth/verify-otp';
    static const String resetPassword = '$baseUrl/api/auth/reset-password';

    // Registration endpoints
    static const String registerLandlord = '$baseUrl/api/landlord/register';
    static const String registerTenant = '$baseUrl/api/tenant/register';

    // Admin endpoints - CORRECTED
    static const String adminRegister = '$baseUrl/api/admin/register';
    static const String adminLogin = '$baseUrl/api/admin/login';
    static const String adminStats = '$baseUrl/api/admin/dashboard-stats';

    // Admin tenant/landlord management - FIXED ROUTES
    static const String adminTenants = '$baseUrl/api/admin/tenants';
    static const String adminLandlords = '$baseUrl/api/admin/landlords';
    static const String adminTenantDetails = '$baseUrl/api/admin/tenant'; // /{id}
    static const String adminLandlordDetails = '$baseUrl/api/admin/landlord'; // /{id}

    // Admin approval endpoints - CORRECTED
    static const String adminPendingLandlords = '$baseUrl/api/admin/pending-landlords';
    static const String adminPendingProperties = '$baseUrl/api/admin/pending-properties';
    static const String adminVerifyLandlord = '$baseUrl/api/admin/verify-landlord'; // /{id}
    static const String adminVerifyProperty = '$baseUrl/api/admin/approve-property'; // /{id}

    // Landlord endpoints - NO CONFLICTS
    static String landlordProfile(int id) => '$baseUrl/api/landlord/profile/$id';
    static String updateLandlordProfile(int id) => '$baseUrl/api/landlord/profile/$id';
    static const String addProperty = '$baseUrl/api/landlord/add-property';
    static String landlordProperties(int id) => '$baseUrl/api/landlord/properties/$id';
    static String propertyHistory(int propertyId) => '$baseUrl/api/landlord/property-history/$propertyId';

    // Landlord tenant search endpoints - SEPARATED FROM ADMIN
    static const String landlordSearchTenant = '$baseUrl/api/landlord/search-tenant';
    static String landlordAllTenants(int landlordId) => '$baseUrl/api/landlord/all-tenants/$landlordId';
    static String landlordSearchHistory(int landlordId) => '$baseUrl/api/landlord/search-history/$landlordId';
    static const String rateTenant = '$baseUrl/api/landlord/rate-tenant';

    // Tenant endpoints - ENHANCED
    static String tenantProfile(int id) => '$baseUrl/api/tenant/profile/$id';
    static String tenantRatings(int id) => '$baseUrl/api/tenant/ratings/$id'; // Now includes last 2 stays

    // Property endpoints
    static const String propertyRequest = '$baseUrl/api/landlord/add-property'; // CORRECTED

    // Utility endpoints
    static const String searchTenant = '$baseUrl/landlord/search-tenant';
    static const String health = '$baseUrl/api/health';
    static const String testTables = '$baseUrl/api/test/tables';
    static const String searchHistory = '$baseUrl/landlord/search-history';
  }