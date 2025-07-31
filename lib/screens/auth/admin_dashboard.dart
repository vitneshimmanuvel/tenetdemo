import 'package:flutter/material.dart';
import '/constants/auth_service.dart';
import '/screens/user_preferences.dart';
import 'Login.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pendingLandlords = [];
  List<Map<String, dynamic>> _pendingProperties = [];
  List<Map<String, dynamic>> _allTenants = [];
  List<Map<String, dynamic>> _allLandlords = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Loading dashboard data...');

      // Load all data with individual error handling
      await Future.wait([
        _loadStats(),
        _loadPendingLandlords(),
        _loadPendingProperties(),
        _loadAllTenants(),
        _loadAllLandlords(),
      ]);

      print('All data loaded successfully');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await AuthService.getAdminStats();
      setState(() {
        _stats = stats ?? {
          'totalTenants': 0,
          'totalLandlords': 0,
          'totalProperties': 0,
        };
      });
      print('Stats loaded: $_stats');
    } catch (e) {
      print('Error loading stats: $e');
      setState(() {
        _stats = {
          'totalTenants': 0,
          'totalLandlords': 0,
          'totalProperties': 0,
        };
      });
    }
  }

  Future<void> _loadPendingLandlords() async {
    try {
      final landlords = await AuthService.getPendingLandlords();
      setState(() {
        _pendingLandlords = landlords ?? [];
      });
      print('Pending landlords loaded: ${_pendingLandlords.length}');
    } catch (e) {
      print('Error loading pending landlords: $e');
      setState(() {
        _pendingLandlords = [];
      });
    }
  }

  Future<void> _loadPendingProperties() async {
    try {
      final properties = await AuthService.getPendingProperties();
      setState(() {
        _pendingProperties = properties ?? [];
      });
      print('Pending properties loaded: ${_pendingProperties.length}');
    } catch (e) {
      print('Error loading pending properties: $e');
      setState(() {
        _pendingProperties = [];
      });
    }
  }

  Future<void> _loadAllTenants() async {
    try {
      final tenants = await AuthService.getAllTenants();
      setState(() {
        _allTenants = tenants ?? [];
      });
      print('All tenants loaded: ${_allTenants.length}');
    } catch (e) {
      print('Error loading tenants: $e');
      setState(() {
        _allTenants = [];
      });
    }
  }

  Future<void> _loadAllLandlords() async {
    try {
      final landlords = await AuthService.getAllLandlords();
      setState(() {
        _allLandlords = landlords ?? [];
      });
      print('All landlords loaded: ${_allLandlords.length}');
    } catch (e) {
      print('Error loading landlords: $e');
      setState(() {
        _allLandlords = [];
      });
    }
  }

  Future<void> _handleLandlordVerification(int landlordId, bool approve) async {
    try {
      await AuthService.verifyLandlord(landlordId, approve);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Landlord ${approve ? 'approved' : 'rejected'} successfully'),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
        // Reload data after verification
        _loadDashboardData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePropertyRequest(int propertyId, bool approve) async {
    try {
      await AuthService.verifyProperty(propertyId, approve);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Property ${approve ? 'approved' : 'rejected'} successfully'),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
        // Reload data after verification
        _loadDashboardData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewTenantDetails(Map<String, dynamic> tenant) async {
    try {
      final tenantId = tenant['id'];
      if (tenantId == null) {
        throw Exception('Tenant ID is null');
      }

      final details = await AuthService.getTenantDetails(tenantId.toString());
      if (mounted) {
        _showTenantDetailsDialog(details);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tenant details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewLandlordDetails(Map<String, dynamic> landlord) async {
    try {
      final landlordId = landlord['id'];
      if (landlordId == null) {
        throw Exception('Landlord ID is null');
      }

      final details = await AuthService.getLandlordDetails(landlordId.toString());
      if (mounted) {
        _showLandlordDetailsDialog(details);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load landlord details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTenantDetailsDialog(Map<String, dynamic> details) {
    final tenant = details['tenant'] ?? {};
    final ratings = details['ratings'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            minHeight: 300,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tenant Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tenant Basic Info Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Basic Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow('Name', _getSafeString(tenant['name'])),
                              _buildDetailRow('Email', _getSafeString(tenant['email'])),
                              _buildDetailRow('Phone', _getSafeString(tenant['phone'])),
                              _buildDetailRow('Tenancy ID', _getSafeString(tenant['tenancy_id'])),
                              _buildDetailRow('Joined', _formatDate(_getSafeString(tenant['created_at']))),
                              _buildDetailRow(
                                  'Status',
                                  _getSafeString(tenant['verified']) == 'true' ? 'Verified' : 'Unverified'
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Rating Summary Card
                      if (_getSafeInt(tenant['total_ratings']) > 0) ...[
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rating Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildRatingSummaryItem(
                                        'Overall Rating',
                                        _getSafeDouble(tenant['average_rating']).toStringAsFixed(1),
                                        Icons.star,
                                        _getRatingColor(tenant['average_rating']),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildRatingSummaryItem(
                                        'Total Ratings',
                                        _getSafeInt(tenant['total_ratings']).toString(),
                                        Icons.rate_review,
                                        Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow('Rent Payment', '${_getSafeDouble(tenant['avg_rent_payment']).toStringAsFixed(1)}/5'),
                                _buildDetailRow('Communication', '${_getSafeDouble(tenant['avg_communication']).toStringAsFixed(1)}/5'),
                                _buildDetailRow('Property Care', '${_getSafeDouble(tenant['avg_property_care']).toStringAsFixed(1)}/5'),
                                _buildDetailRow('Utilities', '${_getSafeDouble(tenant['avg_utilities']).toStringAsFixed(1)}/5'),
                                _buildDetailRow('Property Handover', '${_getSafeDouble(tenant['avg_property_handover']).toStringAsFixed(1)}/5'),
                                _buildDetailRow('Respect Others', '${_getSafeDouble(tenant['respect_others_percentage']).toStringAsFixed(1)}%'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Rating History Section
                      Text(
                        'Rating History (${ratings.length} ratings)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Ratings List
                      if (ratings.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No ratings available',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'This tenant has not been rated by any landlord yet.',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ...ratings.map((rating) {
                          final ratingMap = rating as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Property and Rating Header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getSafeString(ratingMap['property_address'], 'Property'),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              '${_getSafeString(ratingMap['property_city'])}, ${_getSafeString(ratingMap['property_postal_code'])}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getRatingColor(ratingMap['overall_rating']),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${_getSafeDouble(ratingMap['overall_rating']).toStringAsFixed(1)}/5',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Landlord and Date Info
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Landlord: ${_getSafeString(ratingMap['landlord_name'])}',
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Rated: ${_formatDate(_getSafeString(ratingMap['created_at']))}',
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),

                                  // Stay Period
                                  if (_getSafeString(ratingMap['stay_period_start']).isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Stay: ${_formatDate(_getSafeString(ratingMap['stay_period_start']))} - ${_getSafeString(ratingMap['stay_period_end']).isNotEmpty ? _formatDate(_getSafeString(ratingMap['stay_period_end'])) : 'Current'}',
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                  ],

                                  // Detailed Ratings
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Detailed Ratings:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildRatingDetailRow('Rent Payment', _getSafeInt(ratingMap['rent_payment'])),
                                  _buildRatingDetailRow('Communication', _getSafeInt(ratingMap['communication'])),
                                  _buildRatingDetailRow('Property Care', _getSafeInt(ratingMap['property_care'])),
                                  _buildRatingDetailRow('Utilities', _getSafeInt(ratingMap['utilities'])),
                                  _buildRatingDetailRow('Property Handover', _getSafeInt(ratingMap['property_handover'])),

                                  // Respect Others
                                  if (ratingMap['respect_others'] != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Respect Others:', style: TextStyle(color: Colors.grey[700])),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: ratingMap['respect_others'] == true ? Colors.green : Colors.red,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            ratingMap['respect_others'] == true ? 'Yes' : 'No',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  // Comments
                                  if (_getSafeString(ratingMap['comments']).isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Comments:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[200]!),
                                      ),
                                      child: Text(
                                        ratingMap['comments'],
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLandlordDetailsDialog(Map<String, dynamic> details) {
    final landlord = details['landlord'] ?? {};
    final properties = details['properties'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            minHeight: 300,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Landlord Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Landlord Info
                      _buildDetailRow('Name', _getSafeString(landlord['name'])),
                      _buildDetailRow('Email', _getSafeString(landlord['email'])),
                      _buildDetailRow('Phone', _getSafeString(landlord['phone'])),
                      _buildDetailRow('Address', _getSafeString(landlord['address'])),
                      _buildDetailRow('City', _getSafeString(landlord['city'])),
                      _buildDetailRow('Postal Code', _getSafeString(landlord['postal_code'])),
                      _buildDetailRow('Joined', _formatDate(_getSafeString(landlord['created_at']))),

                      const SizedBox(height: 20),
                      Text(
                        'Properties (${properties.length} properties)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Properties List
                      if (properties.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No properties available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...properties.map((property) {
                          final propertyMap = property as Map<String, dynamic>;
                          final avgRating = _getSafeDouble(propertyMap['average_rating']);
                          final totalRatings = _getSafeInt(propertyMap['total_ratings']);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _getSafeString(propertyMap['address'], 'Property'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (avgRating > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getRatingColor(avgRating),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${avgRating.toStringAsFixed(1)}/5',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_getSafeString(propertyMap['city'])}, ${_getSafeString(propertyMap['postal_code'])}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'Total Ratings: $totalRatings',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'Added: ${_formatDate(_getSafeString(propertyMap['created_at']))}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods to safely handle null values
  String _getSafeString(dynamic value, [String defaultValue = 'N/A']) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  int _getSafeInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  double _getSafeDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Color _getRatingColor(dynamic rating) {
    final double ratingValue = _getSafeDouble(rating);
    if (ratingValue >= 4.0) return Colors.green;
    if (ratingValue >= 3.0) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString == 'N/A') return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  void _logout() async {
    await UserPreferences.clearUser();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color adminColor = Color(0xFF1976D2);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: adminColor,
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Tenants'),
            Tab(icon: Icon(Icons.business), text: 'Landlords'),
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading dashboard data...'),
          ],
        ),
      )
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTenantsTab(),
          _buildLandlordsTab(),
          _buildPendingTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Stats Cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Tenants', _getSafeInt(_stats['totalTenants']).toString(), Icons.people, Colors.green)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('Total Landlords', _getSafeInt(_stats['totalLandlords']).toString(), Icons.business, Colors.blue)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildStatCard('Pending Approvals', (_pendingLandlords.length + _pendingProperties.length).toString(), Icons.pending_actions, Colors.orange)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('Total Properties', _getSafeInt(_stats['totalProperties']).toString(), Icons.home, Colors.purple)),
            ],
          ),
          const SizedBox(height: 20),

          // Recent Activity
          const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _pendingLandlords.isEmpty && _pendingProperties.isEmpty
                  ? const Center(
                child: Text(
                  'No pending requests',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
                  : ListView(
                children: [
                  if (_pendingLandlords.isNotEmpty) ...[
                    const Text('Pending Landlord Approvals:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._pendingLandlords.take(3).map((landlord) => _buildActivityItem(
                      'New landlord registration: ${_getSafeString(landlord['name'], 'Unknown')}',
                      _getSafeString(landlord['email']),
                      Icons.person_add,
                      Colors.blue,
                    )),
                  ],
                  if (_pendingProperties.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Pending Property Requests:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._pendingProperties.take(3).map((property) => _buildActivityItem(
                      'New property request: ${_getSafeString(property['address'], 'Unknown')}',
                      'by ${_getSafeString(property['landlord_name'], 'Unknown')}',
                      Icons.home_work,
                      Colors.green,
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'All Tenants',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_allTenants.length} total',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _allTenants.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tenants registered yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _allTenants.length,
              itemBuilder: (context, index) {
                final tenant = _allTenants[index];
                final avgRating = _getSafeDouble(tenant['average_rating']);
                final totalRatings = _getSafeInt(tenant['total_ratings']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, color: Colors.blue),
                    ),
                    title: Text(
                      _getSafeString(tenant['name'], 'Unknown'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${_getSafeString(tenant['tenancy_id'])}'),
                        Text('Email: ${_getSafeString(tenant['email'])}'),
                        Text('Ratings: $totalRatings${avgRating > 0 ? ' (Avg: ${avgRating.toStringAsFixed(1)})' : ''}'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _viewTenantDetails(tenant),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandlordsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'All Landlords',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_allLandlords.length} approved',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _allLandlords.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No approved landlords yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _allLandlords.length,
              itemBuilder: (context, index) {
                final landlord = _allLandlords[index];
                final totalProperties = _getSafeInt(landlord['total_properties']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      child: const Icon(Icons.business, color: Colors.green),
                    ),
                    title: Text(
                      _getSafeString(landlord['name'], 'Unknown'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${_getSafeString(landlord['email'])}'),
                        Text('City: ${_getSafeString(landlord['city'])}'),
                        Text('Properties: $totalProperties'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _viewLandlordDetails(landlord),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Pending Landlords'),
              Tab(text: 'Pending Properties'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPendingLandlordsTab(),
                _buildPendingPropertiesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingLandlordsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pending Landlord Approvals',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_pendingLandlords.length} pending',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _pendingLandlords.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No pending landlord approvals', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _pendingLandlords.length,
              itemBuilder: (context, index) {
                final landlord = _pendingLandlords[index];
                return _buildLandlordCard(landlord);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPropertiesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pending Property Requests',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_pendingProperties.length} pending',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _pendingProperties.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  Text('No pending property requests', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _pendingProperties.length,
              itemBuilder: (context, index) {
                final property = _pendingProperties[index];
                return _buildPropertyCard(property);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final totalUsers = _getSafeInt(_stats['totalTenants']) + _getSafeInt(_stats['totalLandlords']);
    final pendingRequests = _pendingLandlords.length + _pendingProperties.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildAnalyticsCard('Total Users', totalUsers, Icons.people, Colors.indigo),
                _buildAnalyticsCard('Active Properties', _getSafeInt(_stats['totalProperties']), Icons.home, Colors.green),
                _buildAnalyticsCard('Pending Requests', pendingRequests, Icons.pending, Colors.orange),
                _buildAnalyticsCard('System Health', 100, Icons.health_and_safety, Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandlordCard(Map<String, dynamic> landlord) {
    final landlordId = _getSafeInt(landlord['id']);
    if (landlordId == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getSafeString(landlord['name'], 'Unknown'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _getSafeString(landlord['email']),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Phone: ${_getSafeString(landlord['phone'], 'Not provided')}'),
            Text('Address: ${_getSafeString(landlord['address'], 'Not provided')}'),
            Text('City: ${_getSafeString(landlord['city'], 'Not provided')}'),
            Text('Postal Code: ${_getSafeString(landlord['postal_code'], 'Not provided')}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handleLandlordVerification(landlordId, false),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _handleLandlordVerification(landlordId, true),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    final propertyId = _getSafeInt(property['id']);
    if (propertyId == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  child: const Icon(Icons.home_work, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getSafeString(property['address'], 'Unknown Address'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Requested by: ${_getSafeString(property['landlord_name'], 'Unknown')}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('City: ${_getSafeString(property['city'], 'Not provided')}'),
            Text('Postal Code: ${_getSafeString(property['postal_code'], 'Not provided')}'),
            Text('Landlord Email: ${_getSafeString(property['landlord_email'], 'Not provided')}'),
            if (_getSafeString(property['street']).isNotEmpty && _getSafeString(property['street']) != 'N/A')
              Text('Street: ${property['street']}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handlePropertyRequest(propertyId, false),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _handlePropertyRequest(propertyId, true),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

Widget _buildRatingSummaryItem(String title, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// Helper widget for detailed rating rows
Widget _buildRatingDetailRow(String label, int rating) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(color: Colors.grey[700]),
        ),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              Icons.star,
              size: 16,
              color: index < rating ? Colors.amber : Colors.grey[300],
            );
          }),
        ),
      ],
    ),
  );
}