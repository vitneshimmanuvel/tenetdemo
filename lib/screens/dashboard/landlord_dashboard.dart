import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import ' search_tenant.dart';
import 'propertiesopp.dart';
import '/screens/user_preferences.dart';

class LandlordDashboard extends StatefulWidget {
  const LandlordDashboard({super.key});

  @override
  State<LandlordDashboard> createState() => _LandlordDashboardState();
}

class _LandlordDashboardState extends State<LandlordDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? _user;
  bool _isLoading = true;

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
  }

  void _showProfileDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _showAddPropertyDialog() {
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
              children: [
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
                    hintText: "Street",
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
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.pin),
                    hintText: "Pincode",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B4FD5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Save property logic
              },
              child: const Text("Register", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController(text: _user?['name'] ?? '');
        TextEditingController addressController = TextEditingController(
            text: _user?['address'] ?? '');
        TextEditingController emailController = TextEditingController(
            text: _user?['email'] ?? '');
        TextEditingController phoneController = TextEditingController(
            text: _user?['phone'] ?? '');

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Edit Profile", style: TextStyle(color: Color(0xFF5B4FD5))),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))
                  ],
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person),
                    hintText: "Name",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.home),
                    hintText: "Address",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email),
                    hintText: "Email",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone),
                    hintText: "Phone Number",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B4FD5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Save profile logic
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
        ),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF5B4FD5),
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                _user?['name'] ?? 'Name',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.home, color: Color(0xFF5B4FD5)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_user?['address'] ?? 'Address'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.email, color: Color(0xFF5B4FD5)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_user?['email'] ?? 'Email'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.phone, color: Color(0xFF5B4FD5)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_user?['phone'] ?? 'Phone'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Icon(Icons.notifications_active, color: Color(0xFF5B4FD5)),
                  SizedBox(width: 10),
                  Expanded(child: Text("Notifications enabled")),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B4FD5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showEditProfileDialog,
                child: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
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
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 200),
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
                  const SizedBox(height: 100),
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
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const SearchTenant()));
                        }),
                        const SizedBox(height: 20),
                        _buildButton(context, 'My Properties', Icons.home, () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const PropertiesOpp()));
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
}