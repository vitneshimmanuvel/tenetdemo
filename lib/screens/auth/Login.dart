// login_screen.dart
import 'package:flutter/material.dart';

import 'register.dart';
import 'verify_otp_screen.dart';
import 'forgot_password_screen.dart';
import '/constants/auth_service.dart';
import '/screens/user_preferences.dart';
import '../dashboard/landlord_dashboard.dart';
import '../dashboard/tenant_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      final response = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 1. Server says user must verify OTP
      if (response['requiresOtp'] == true) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyOtpScreen(
              email: _emailController.text.trim(),
              purpose: 'login',
              userRole: response['role'],
            ),
          ),
        );
        return;
      }

      // 2. Normal login – save user & go to dashboard
      await UserPreferences.saveUser(response['user']);

      if (!mounted) return;
      final role = response['user']['role'];
      if (role == 'landlord') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LandlordDashboard()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const TenantDashboard()));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  void _register() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Register()),
    );
  }

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.apartment_rounded, size: 90, color: Colors.indigo),
                const SizedBox(height: 15),
                const Text(
                  'Welcome to Tenancy App',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 40),

                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text('Forgot Password?', style: TextStyle(color: Colors.indigo)),
                  ),
                ),
                const SizedBox(height: 20),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Register link
                TextButton(
                  onPressed: _register,
                  child: const Text(
                    'Don’t have an account? Register',
                    style: TextStyle(color: Colors.indigo),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}