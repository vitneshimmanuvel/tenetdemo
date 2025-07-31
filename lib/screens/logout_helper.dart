import 'package:flutter/material.dart';
import '/screens/user_preferences.dart';

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