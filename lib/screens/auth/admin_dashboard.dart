import 'package:flutter/material.dart';
import '/constants/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pendingLandlords = [];
  List<Map<String, dynamic>> _pendingProperties = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final stats = await AuthService.getAdminStats();
      final landlords = await AuthService.getPendingLandlords();
      final properties = await AuthService.getPendingProperties();

      setState(() {
        _stats = stats;
        _pendingLandlords = landlords['landlords'] ?? [];
        _pendingProperties = properties['properties'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  Future<void> _handleLandlordVerification(int landlordId, bool approve) async {
    try {
      await AuthService.verifyLandlord(landlordId, approve);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Landlord ${approve ? 'approved' : 'rejected'} successfully')),
      );
      _loadDashboardData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  Future<void> _handlePropertyRequest(int propertyId, bool approve) async {
    try {
      await AuthService.verifyProperty(propertyId, approve);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Property ${approve ? 'approved' : 'rejected'} successfully')),
      );
      _loadDashboardData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.person_add), text: 'Landlords'),
            Tab(icon: Icon(Icons.home_work), text: 'Properties'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildLandlordsTab(),
          _buildPropertiesTab(),
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
    Expanded(child: _buildStatCard('Total Tenants', _stats['totalTenants']?.toString() ?? '0', Icons.people, Colors.green)),
    const SizedBox(width: 10),
    Expanded(child: _buildStatCard('Total Landlords', _stats['totalLandlords']?.toString() ?? '0', Icons.business, Colors.blue)),
    ],
    ),
    const SizedBox(height: 10),
    Row(
    children: [
    Expanded(child: _buildStatCard('Pending Approvals', _pendingLandlords.length.toString(), Icons.pending_actions, Colors.orange)),
    const SizedBox(width: 10),
    Expanded(child: _buildStatCard('Total Properties', _stats['totalProperties']?.toString() ?? '0', Icons.home, Colors.purple)),
    ],
    ),
    const SizedBox(height: 20),

    // Recent Activity
    const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    Expanded(