import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/constants/auth_service.dart';
import '/screens/user_preferences.dart';
import 'input_functions.dart';
import 'verify_otp_screen.dart';
import 'Login.dart';

class RegisterTenantScreen extends StatefulWidget {
  const RegisterTenantScreen({super.key});

  @override
  State<RegisterTenantScreen> createState() => _RegisterTenantScreenState();
}

class _RegisterTenantScreenState extends State<RegisterTenantScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Color _primaryColor = const Color(0xFF4CAF50);
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Format names properly
        String firstName = InputFunctions.formatName(_firstNameController.text);
        String lastName = InputFunctions.formatName(_lastNameController.text);
        String fullName = lastName.isNotEmpty ? '$firstName $lastName' : firstName;

        // Format email
        String email = InputFunctions.formatEmail(_emailController.text);

        // Clean phone number (remove formatting)
        String phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

        print('🚀 Starting tenant registration for: $fullName ($email)');

        final response = await AuthService.registerTenant(
          name: fullName,
          email: email,
          phone: phone,
          password: _passwordController.text,
        );

        print('📥 Registration API Response: $response');

        if (!mounted) return;

        if (response['success'] == true) {
          print('✅ Registration successful, proceeding to OTP');

          await UserPreferences.saveTempUserData({
            'name': fullName,
            'email': email,
            'phone': phone,
            'role': 'tenant',
            'tenantId': response['tenantId'],
          });

          _showSuccessSnackBar(
              response['message'] ?? 'Registration successful! Please check your email for OTP verification.',
              const Color(0xFF4CAF50)
          );

          await Future.delayed(const Duration(milliseconds: 800));

          if (mounted) {
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => VerifyOtpScreen(
                  email: email,
                  purpose: 'tenant_register',
                  userRole: 'tenant',
                ),
              ),
            );
          }
        } else {
          String errorMessage = response['message'] ?? 'Registration failed. Please try again.';
          Color errorColor = Colors.red;

          if (errorMessage.toLowerCase().contains('email already') ||
              errorMessage.toLowerCase().contains('already registered') ||
              errorMessage.toLowerCase().contains('already exists')) {
            errorColor = Colors.orange;
            errorMessage = 'This email is already registered. Please use a different email or login instead.';
            _showErrorWithLoginOption(errorMessage);
            return;
          }

          _showErrorSnackBar(errorMessage, errorColor);
        }
      } catch (e) {
        print('💥 Registration Exception: $e');
        if (mounted) {
          String errorMessage = 'Registration failed. Please try again.';
          if (e.toString().contains('email already exists') ||
              e.toString().contains('already registered')) {
            _showErrorWithLoginOption('This email is already registered. Please use a different email or login instead.');
            return;
          }
          _showErrorSnackBar(errorMessage, Colors.red);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showErrorSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              backgroundColor == Colors.orange ? Icons.warning : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorWithLoginOption(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    'Go to Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void _showSuccessSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 2000),
        margin: const EdgeInsets.all(16),
        elevation: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE8F5E8),
                  Color(0xFFF1F8E9),
                ],
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: Text(
                          'Already have account?',
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryColor, const Color(0xFF66BB6A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.home,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Create Tenant Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Join our community of trusted tenants',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Name fields row
                  Row(
                    children: [
                      Expanded(
                        child: InputFunctions.buildInputField(
                          controller: _firstNameController,
                          label: 'First Name',
                          icon: Icons.person_outline,
                          primaryColor: _primaryColor,
                          inputFormatters: [InputFunctions.nameInputFormatter],
                          textCapitalization: TextCapitalization.words,
                          validator: (value) => InputFunctions.validateName(value, fieldName: 'First name'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InputFunctions.buildInputField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          icon: Icons.person_outline,
                          primaryColor: _primaryColor,
                          inputFormatters: [InputFunctions.nameInputFormatter],
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              return InputFunctions.validateName(value, fieldName: 'Last name');
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Email field
                  InputFunctions.buildInputField(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    primaryColor: _primaryColor,
                    keyboardType: TextInputType.emailAddress,
                    validator: InputFunctions.validateEmail,
                  ),
                  const SizedBox(height: 20),

                  // Phone field
                  InputFunctions.buildInputField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    primaryColor: _primaryColor,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      InputFunctions.phoneInputFormatter,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: InputFunctions.validatePhone,
                    onChanged: (value) {
                      // Optional: Auto-format phone number
                      if (value.length == 10) {
                        _phoneController.value = TextEditingValue(
                          text: InputFunctions.formatPhone(value),
                          selection: TextSelection.collapsed(offset: InputFunctions.formatPhone(value).length),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  InputFunctions.buildPasswordField(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: _obscurePassword,
                    onToggleVisibility: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    primaryColor: _primaryColor,
                    validator: InputFunctions.validatePassword,
                  ),
                  const SizedBox(height: 20),

                  // Confirm password field
                  InputFunctions.buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    obscureText: _obscureConfirmPassword,
                    onToggleVisibility: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                    primaryColor: _primaryColor,
                    validator: (value) => InputFunctions.validateConfirmPassword(value, _passwordController.text),
                  ),
                  const SizedBox(height: 40),

                  // Register button
                  _buildRegisterButton(),
                  const SizedBox(height: 32),

                  // Info box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: _primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'After registration, you will receive an OTP via email to verify your account and gain immediate access.',
                            style: TextStyle(
                              color: _primaryColor.withOpacity(0.8),
                              fontSize: 14,
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
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          disabledBackgroundColor: _primaryColor.withOpacity(0.6),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text(
          'CREATE ACCOUNT',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}