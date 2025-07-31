import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import ' search_tenant.dart';
import 'propertiesopp.dart';
import '/screens/user_preferences.dart';
import '/constants/auth_service.dart';
import '../auth/login.dart';
import '/screens/logout_helper.dart'; // Add this import

class LandlordDashboard extends StatefulWidget {
  const LandlordDashboard({super.key});

  @override
  State<LandlordDashboard> createState() => _LandlordDashboardState();
}

class _LandlordDashboardState extends State<LandlordDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isAddingProperty = false;
  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await UserPreferences.getUser();
    setState(() {
      _user = user;
      _isLoading = false;
    });

    // Load fresh data from server
    if (user != null && user['id'] != null) {
      await _refreshProfile();
      await _loadProperties();
      await _loadSearchHistory();
    }
  }

  Future<void> _refreshProfile() async {
    if (_user == null || _user!['id'] == null) return;

    try {
      final result = await AuthService.getLandlordProfile(_user!['id']);
      if (result['success'] == true && result['profile'] != null) {
        final profile = Map<String, dynamic>.from(result['profile'] as Map);
        final updatedUser = {
          ..._user!,
          ...profile,
        };
        await UserPreferences.saveUser(updatedUser);
        setState(() {
          _user = updatedUser;
        });
      }
    } catch (e) {
      print('Error refreshing profile: $e');
    }
  }

  Future<void> _loadProperties() async {
    if (_user == null || _user!['id'] == null) return;

    try {
      final result = await AuthService.getLandlordProperties(_user!['id']);
      if (result['success'] == true) {
        setState(() {
          _properties = List<Map<String, dynamic>>.from(result['properties'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading properties: $e');
    }
  }

  double _getSafeRating(dynamic rating) {
    if (rating == null) return 0.0;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) return double.tryParse(rating) ?? 0.0;
    return 0.0;
  }

  String _getSafeString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  Future<void> _loadSearchHistory() async {
    if (_user == null || _user!['id'] == null) return;

    try {
      final result = await AuthService.getSearchHistory(_user!['id']);
      if (result['success'] == true) {
        setState(() {
          _searchHistory = List<Map<String, dynamic>>.from(result['searchHistory'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading search history: $e');
    }
  }

  void _showProfileDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _showAddPropertyDialog() {
    if (_user == null) {
      _showErrorSnackBar('User not found. Please login again.');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController addressController = TextEditingController();
        TextEditingController streetController = TextEditingController();
        TextEditingController cityController = TextEditingController();
        TextEditingController pincodeController = TextEditingController();

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Add Property", style: TextStyle(color: Color(0xFF5B4FD5))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Your property will be sent for admin approval",
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on),
                    hintText: "Full Address",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: streetController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.streetview),
                    hintText: "Street (Optional)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cityController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))
                  ],
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_city),
                    hintText: "City",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pincodeController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.local_post_office),
                    hintText: "Postal Code",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B4FD5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (addressController.text.isEmpty ||
                    cityController.text.isEmpty ||
                    pincodeController.text.isEmpty) {
                  _showErrorSnackBar('Please fill all required fields');
                  return;
                }

                setState(() => _isAddingProperty = true);

                final result = await AuthService.addProperty(
                  landlordId: _user!['id'],
                  address: addressController.text.trim(),
                  street: streetController.text.trim(),
                  city: cityController.text.trim(),
                  postalCode: pincodeController.text.trim(),
                );

                setState(() => _isAddingProperty = false);
                Navigator.of(context).pop();

                if (result['success'] == true) {
                  _showSuccessSnackBar(result['message'] ?? 'Property request submitted for approval');
                  await _loadProperties();
                } else {
                  _showErrorSnackBar(result['message'] ?? 'Failed to add property');
                }
              },
              child: _isAddingProperty
                  ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
                  : const Text("Submit for Approval", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Updated logout methods using LogoutHelper
  void _showLogoutDialog() {
    LogoutHelper.showLogoutDialog(context);
  }

  void _logout() {
    LogoutHelper.logout(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('User not found. Please login again.')),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      // Optional: Add logout to AppBar
      appBar: AppBar(
        title: const Text('Landlord Dashboard'),
        backgroundColor: const Color(0xFF5B4FD5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showLogoutDialog, // Shows confirmation dialog
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      endDrawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
        ),
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF5B4FD5), Color(0xFF9F95EC)],
                  ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 35, color: Color(0xFF5B4FD5)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _user!['name'] ?? 'Landlord',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _user!['email'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.account_circle, color: Color(0xFF5B4FD5)),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  _showProfileDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Color(0xFF5B4FD5)),
                title: const Text('My Properties'),
                trailing: Text('${_properties.length}'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertiesOpp(
                        properties: _properties,
                        landlordId: _user!['id'],
                      ),
                    ),
                  ).then((_) => _loadProperties());
                },
              ),
              ListTile(
                leading: const Icon(Icons.search, color: Color(0xFF5B4FD5)),
                title: const Text('Search Tenants'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchTenant(landlordId: _user!['id']),
                    ),
                  ).then((_) => _loadSearchHistory());
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Color(0xFF5B4FD5)),
                title: const Text('Search History'),
                trailing: Text('${_searchHistory.length}'),
                onTap: () {
                  Navigator.pop(context);
                  _showSearchHistoryDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh, color: Color(0xFF5B4FD5)),
                title: const Text('Refresh Data'),
                onTap: () {
                  Navigator.pop(context);
                  _refreshAllData();
                },
              ),
              // Updated logout ListTile using LogoutHelper
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context); // Close drawer first
                  _showLogoutDialog(); // Then show logout dialog
                },
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Decorative circles from second design
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 100,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFE7E29B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: 60,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF57D2A0),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main content
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 150),
                  // Profile section - centered like in second design
                  GestureDetector(
                    onTap: _showProfileDrawer,
                    child: Container(
                      width: 300,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B4FD5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Text(
                              _user?['name']?.isNotEmpty == true
                                  ? _user!['name'][0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                color: Color(0xFF5B4FD5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _user?['name'] ?? 'Name',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                  // Action buttons section
                  Container(
                    height: 300,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B4FD5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        _buildButton(context, 'Search Tenant', Icons.search, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchTenant(landlordId: _user!['id']),
                            ),
                          ).then((_) => _loadSearchHistory());
                        }),
                        const SizedBox(height: 20),
                        _buildButton(context, 'My Properties', Icons.home, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PropertiesOpp(
                                properties: _properties,
                                landlordId: _user!['id'],
                              ),
                            ),
                          ).then((_) => _loadProperties());
                        }),
                        const SizedBox(height: 30),
                        GestureDetector(
                          onTap: _showAddPropertyDialog,
                          child: Container(
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.redAccent,
                            ),
                            child: const Center(
                              child: Text(
                                "+ add properties",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.all(10),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E29B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF5B4FD5), size: 24),
            ),
            Expanded(
              child: Center(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF5B4FD5),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // All the dialog methods from the first file
  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Profile Information", style: TextStyle(color: Color(0xFF5B4FD5))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileInfoRow("Name", _user!['name'] ?? 'N/A'),
              _profileInfoRow("Email", _user!['email'] ?? 'N/A'),
              _profileInfoRow("Phone", _user!['phone'] ?? 'N/A'),
              _profileInfoRow("Address", _user!['address'] ?? 'N/A'),
              _profileInfoRow("City", _user!['city'] ?? 'N/A'),
              _profileInfoRow("Postal Code", _user!['postalCode'] ?? 'N/A'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    _user!['verified'] == true ? Icons.verified : Icons.pending,
                    color: _user!['verified'] == true ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _user!['verified'] == true ? 'Verified' : 'Pending Verification',
                    style: TextStyle(
                      color: _user!['verified'] == true ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    _user!['adminApproved'] == true ? Icons.admin_panel_settings : Icons.pending_actions,
                    color: _user!['adminApproved'] == true ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _user!['adminApproved'] == true ? 'Admin Approved' : 'Pending Admin Approval',
                    style: TextStyle(
                      color: _user!['adminApproved'] == true ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _profileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Recent Searches", style: TextStyle(color: Color(0xFF5B4FD5))),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: _searchHistory.isEmpty
                ? const Center(child: Text('No search history yet'))
                : ListView.builder(
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                final tenant = _searchHistory[index];
                final averageRating = _getSafeRating(tenant['average_rating']);
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF5B4FD5),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(_getSafeString(tenant['name']).isEmpty ? 'Unknown' : _getSafeString(tenant['name'])),
                  subtitle: Text(_getSafeString(tenant['tenancy_id'])),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(
                        averageRating > 0 ? averageRating.toStringAsFixed(1) : 'N/A',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshAllData() async {
    setState(() => _isLoading = true);
    await _refreshProfile();
    await _loadProperties();
    await _loadSearchHistory();
    setState(() => _isLoading = false);
    _showSuccessSnackBar('Data refreshed successfully');
  }
}