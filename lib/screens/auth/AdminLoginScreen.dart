import 'package:flutter/material.dart';
import '/constants/auth_service.dart';
import '/screens/user_preferences.dart';
import 'admin_dashboard.dart';
import 'verify_otp_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isLoading = false;

  Future<void> _adminLogin() async {
    final emailLower = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (emailLower.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.adminLogin(
        email: emailLower,
        password: password,
      );

      if (response['success'] == true && response['admin'] != null) {
        // Save admin data to preferences
        await UserPreferences.saveUser(response['admin']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Login successful')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Login failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _adminRegister() async {
    final name = _nameController.text.trim();
    final emailLower = _emailController.text.trim().toLowerCase();
    final password = _registerPasswordController.text;

    if (name.isEmpty || emailLower.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters long'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.registerAdmin(
        name: name,
        email: emailLower,
        password: password,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'OTP sent to your email'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to OTP verification screen with admin_register purpose
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyOtpScreen(
                email: emailLower,
                purpose: 'admin_register',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Registration failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearFields() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _registerPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    const Color adminColor = Color(0xFF1976D2);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isRegisterMode ? 'Admin Registration' : 'Admin Access',
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 80,
                    color: adminColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isRegisterMode ? 'Create Admin Account' : 'Admin Login',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Registration fields
                  if (_isRegisterMode) ...[
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: adminColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Email field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: adminColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  TextField(
                    controller: _isRegisterMode ? _registerPasswordController : _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: adminColor, width: 2),
                      ),
                      errorText: _isRegisterMode &&
                          _registerPasswordController.text.isNotEmpty &&
                          _registerPasswordController.text.length < 6
                          ? 'Password must be at least 6 characters'
                          : null,
                    ),
                    onChanged: (_) => setState(() {}), // Rebuild to show/hide error
                  ),
                  const SizedBox(height: 32),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : (_isRegisterMode ? _adminRegister : _adminLogin),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: adminColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                        _isRegisterMode ? 'REGISTER' : 'LOGIN',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Toggle button
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegisterMode = !_isRegisterMode;
                        _clearFields();
                      });
                    },
                    child: Text(
                      _isRegisterMode
                          ? 'Already have an account? Login'
                          : 'Need to register? Create Account',
                      style: TextStyle(color: adminColor),
                    ),
                  ),

                  // Warning for registration
                  if (_isRegisterMode) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[300]!),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '⚠️ Admin registration is restricted to authorized personnel only.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'After registration, you will receive an OTP for verification.',
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }
}