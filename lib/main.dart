import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login.dart';
import 'screens/dashboard/landlord_dashboard.dart';
import 'screens/dashboard/tenant_dashboard.dart';
import 'screens/auth/admin_dashboard.dart';
import 'screens/user_preferences.dart';
import 'constants/colors.dart';

void main() {
  runApp(const TenantScoreApp());
}

class TenantScoreApp extends StatelessWidget {
  const TenantScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tenant Score App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBackgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      home: const SessionChecker(),
      // Define named routes for navigation
      routes: {
        '/login': (context) => const LoginScreen(),
        '/landlord-dashboard': (context) => const LandlordDashboard(),
        '/tenant-dashboard': (context) => const TenantDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
      },
    );
  }
}

class SessionChecker extends StatefulWidget {
  const SessionChecker({super.key});

  @override
  State<SessionChecker> createState() => _SessionCheckerState();
}

class _SessionCheckerState extends State<SessionChecker> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      // Add a small delay to show splash screen
      await Future.delayed(const Duration(seconds: 2));

      final isLoggedIn = await UserPreferences.isLoggedIn();

      if (isLoggedIn) {
        final userType = await UserPreferences.getUserType();
        final user = await UserPreferences.getUser();

        // Navigate based on user type and verification status
        if (mounted) {
          switch (userType) {
            case 'admin':
              Navigator.pushReplacementNamed(context, '/admin-dashboard');
              break;

            case 'tenant':
              Navigator.pushReplacementNamed(context, '/tenant-dashboard');
              break;

            case 'landlord':
            // Check if landlord is verified and approved
              final status = await UserPreferences.getLandlordStatus();
              if (status['canAccess'] == true) {
                Navigator.pushReplacementNamed(context, '/landlord-dashboard');
              } else {
                // Show waiting screen or redirect to login
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WaitingForApprovalScreen(
                      status: status,
                    ),
                  ),
                );
              }
              break;

            default:
            // Invalid user type, redirect to login
              await UserPreferences.clearUser();
              Navigator.pushReplacementNamed(context, '/login');
          }
        }
      } else {
        // Not logged in, show login screen
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      // Error checking login status, show login screen
      print('Error checking login status: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen(); // Show splash while checking
  }
}

// Waiting screen for landlords pending approval
class WaitingForApprovalScreen extends StatelessWidget {
  final Map<String, dynamic> status;

  const WaitingForApprovalScreen({
    super.key,
    required this.status,
  });

  void _logout(BuildContext context) async {
    await UserPreferences.clearUser();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Account Status';
    String message = status['message'] ?? 'Please wait for approval';
    IconData icon = Icons.pending;
    Color color = Colors.orange;

    switch (status['status']) {
      case 'pending_verification':
        title = 'Email Verification Required';
        icon = Icons.mark_email_unread;
        color = Colors.blue;
        break;
      case 'pending_approval':
        title = 'Waiting for Admin Approval';
        icon = Icons.admin_panel_settings;
        color = Colors.orange;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 100,
                color: color,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  // Refresh the session check
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SessionChecker(),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Check Status Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}