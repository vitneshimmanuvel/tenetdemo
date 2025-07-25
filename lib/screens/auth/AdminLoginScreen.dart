import 'package:flutter/material.dart';
import '/constants/auth_service.dart';
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
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.adminLogin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response['requiresOtp'] == true) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyOtpScreen(
                email: _emailController.text.trim(),
                purpose: 'login',
                userRole: 'admin',
              ),
            ),
          );
        }
      } else if (response['user'] != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _adminRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _registerPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (!_emailController.text.toLowerCase().contains('alfa')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin email must contain "alfa"')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.registerAdmin(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _registerPasswordController.text,
      );

      if (response['success'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyOtpScreen(
                email: _emailController.text.trim(),
                purpose: 'register',
                userRole: 'admin',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
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

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: _isRegisterMode ? 'Email (must contain "alfa")' : 'Email',
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
                    ),
                  ),
                  const SizedBox(height: 32),

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

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegisterMode = !_isRegisterMode;
                        // Clear controllers when switching modes
                        _nameController.clear();
                        _emailController.clear();
                        _passwordController.clear();
                        _registerPasswordController.clear();
                      });
                    },
                    child: Text(
                      _isRegisterMode ? 'Already have an account? Login' : 'Need to register? Create Account',
                      style: TextStyle(color: adminColor),
                    ),
                  ),

                  if (_isRegisterMode) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[300]!),
                      ),
                      child: const Text(
                        '⚠️ Admin registration requires email verification and is restricted to authorized personnel only.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                        textAlign: TextAlign.center,
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