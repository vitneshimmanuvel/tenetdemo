import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/screens/user_preferences.dart';
import '../auth/login.dart';

// LogoutHelper class
class LogoutHelper {
  /// Shows a logout confirmation dialog
  static void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Logout", style: TextStyle(color: Colors.red)),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                logout(context); // Perform logout
              },
              child: const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Performs logout without confirmation
  static Future<void> logout(BuildContext context) async {
    try {
      // Clear user preferences
      await UserPreferences.clearUser();

      // Navigate to login screen and remove all previous routes
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      // Handle any errors during logout
      print('Error during logout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error occurred during logout'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({super.key});

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> {
  String? tenancyId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTenancyId();
  }

  void _loadTenancyId() async {
    try {
      final user = await UserPreferences.getUser();
      setState(() {
        tenancyId = user['tenancyId'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tenancy ID: $e')),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tenancy ID copied to clipboard!')),
    );
  }

  // Updated logout method using LogoutHelper
  void _logout() {
    LogoutHelper.showLogoutDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF70A645);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      appBar: AppBar(
        title: const Text('Your Tenancy ID'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 80, color: primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Your Tenancy ID',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share this ID with landlords during rental applications',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor.withOpacity(0.4), width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    tenancyId ?? 'Not Available',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your unique tenant identifier',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: tenancyId != null
                    ? () {
                  // Share functionality - you can implement this later
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share functionality to be implemented'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                    : null,
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text('Share ID with Landlord'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: tenancyId != null
                    ? () => _copyToClipboard(tenancyId!)
                    : null,
                icon: const Icon(Icons.copy),
                label: const Text('Copy Tenancy ID'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Privacy Protected: You do not have access to landlord information. Your data remains confidential.',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}