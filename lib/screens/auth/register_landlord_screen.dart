import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/constants/auth_service.dart';
import 'verify_otp_screen.dart';

class RegisterLandlordScreen extends StatefulWidget {
  const RegisterLandlordScreen({super.key});

  @override
  State<RegisterLandlordScreen> createState() => _RegisterLandlordScreenState();
}

class _RegisterLandlordScreenState extends State<RegisterLandlordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final Color _primaryColor = const Color(0xFF6A35B1);
  bool _isLoading = false;

  Future<void> _register() async {
    print('Register button pressed'); // Debug log

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed'); // Debug log
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    print('Starting registration process...'); // Debug log

    try {
      final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      print('Full name: $fullName'); // Debug log
      print('Email: ${_emailController.text.trim()}'); // Debug log

      final response = await AuthService.registerLandlord(
        name: fullName,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        address: _addressController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        city: _cityController.text.trim(),
      );

      print('Registration response: $response'); // Debug log

      if (!mounted) return;

      if (response['success'] == true) {
        print('Registration successful, navigating to OTP screen'); // Debug log

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please check your email for OTP.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to OTP verification screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOtpScreen(
              email: _emailController.text.trim(),
              purpose: 'register',
              userRole: 'landlord',
            ),
          ),
        );
      } else {
        print('Registration failed: ${response['message']}'); // Debug log
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Registration failed'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Registration error: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    decoration: const BoxDecoration(
    color: Color(0xFFE8E0F5),
    ),
    child: Form(
    key: _formKey,
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
    Align(
    alignment: Alignment.topLeft,
    child: IconButton(
    icon: Icon(Icons.arrow_back, color: _primaryColor),
    onPressed: () => Navigator.pop(context),
    ),
    ),
    const SizedBox(height: 20),
    Column(
    children: [
    Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: [_primaryColor, const Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    ),
    shape: BoxShape.circle,
    ),
    child: const Icon(
    Icons.business,
    size: 60,
    color: Colors.white,
    ),
    ),
    const SizedBox(height: 24),
    Text(
    'Create Landlord Account',
    style: TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: _primaryColor,
    letterSpacing: 0.5,
    ),
    ),
    const SizedBox(height: 12),
    Text(
    'Please provide your details for verification',
    style: TextStyle(
    fontSize: 16,
    color: Colors.grey[700],
    fontWeight: FontWeight.w500,
    ),
    ),
    ],
    ),
    const SizedBox(height: 36),

    // First Name and Last Name Row
    Row(
    children: [
    Expanded(
    child: _buildInputField(
    controller: _firstNameController,
    label: 'First Name',
    icon: Icons.person_outline,
    validator: (value) {
    if (value == null || value.trim().isEmpty) {
    return 'Required';
    }
    return null;
    },
    ),
    ),
    const SizedBox(width: 16),
    Expanded(
    child: _buildInputField(
    controller: _lastNameController,
    label: 'Last Name',
    icon: Icons.person_outline,
    validator: (value) {
    if (value == null || value.trim().isEmpty) {
    return 'Required';
    }
    return null;
    },
    ),
    ),
    ],
    ),
    const SizedBox(height: 20),

    _buildInputField(
    controller: _emailController,
    label: 'Email Address',
    icon: Icons.email_outlined,
    keyboardType: TextInputType.emailAddress,
    validator: (value) {
    if (value == null || value.trim().isEmpty) {
    return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
    return 'Enter a valid email';
    }
    return null;
    },
    ),
    const SizedBox(height: 20),

    _buildInputField(
    controller: _phoneController,
    label: 'Phone Number',
    icon: Icons.phone_outlined,
    keyboardType: TextInputType.phone,
    validator: (value) {
    if (value == null || value.trim().isEmpty) {
    return 'Please enter your phone';
    }
    if (value.trim().length < 10) {
    return 'Enter a valid phone number';
    }
    return null;
    },
    ),
    const SizedBox(height: 20),

    _buildInputField(
    controller: _addressController,
    label: 'Complete Address',
    icon: Icons.location_on_outlined,
    validator: (value) {
    if (value == null || value.trim().isEmpty) {
    return 'Please enter your address';
    }
    return null;
    },
    ),
    const SizedBox(height: 20),

    // City and Postal Code Row
      // City and Postal Code Row
      Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildInputField(
              controller: _cityController,
              label: 'City',
              icon: Icons.location_city_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildInputField(
              controller: _postalCodeController,
              label: 'Postal Code',
              icon: Icons.local_post_office_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                // Canadian postal code format: A1A 1A1
                if (!RegExp(r'^[A-Za-z]\d[A-Za-z] ?\d[A-Za-z]\d$').hasMatch(value.trim())) {
                  return 'Invalid format';
                }
                return null;
              },
            ),
          ),
        ],
      ),

      const SizedBox(height: 20),

  _buildPasswordField(
  controller: _passwordController,
  label: 'Password',
  validator: (value) {
  if (value == null || value.isEmpty) {
  return 'Please enter a password';
  }
  if (value.length < 6) {
  return 'Password must be at least 6 characters';
  }
  return null;
  },
  ),
  const SizedBox(height: 20),

  _buildPasswordField(
  controller: _confirmPasswordController,
  label: 'Confirm Password',
  validator: (value) {
  if (value == null || value.isEmpty) {
  return 'Please confirm your password';
  }
  return null;
  },
  ),
  const SizedBox(height: 40),

  _buildActionButton(),
  const SizedBox(height: 32),

  Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
  color: Colors.orange[50],
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Colors.orange[300]!),
  ),
  child: Column(
  children: [
  const Icon(Icons.info_outline, color: Colors.orange),
  const SizedBox(height: 8),
  Text(
  'Verification Required',
  style: TextStyle(
  fontWeight: FontWeight.bold,
  color: Colors.orange[800],
  ),
  ),
  const SizedBox(height: 4),
  Text(
  'After email verification, your account will be reviewed by our admin team. You\'ll receive a notification once approved.',
  textAlign: TextAlign.center,
  style: TextStyle(
  fontSize: 12,
  color: Colors.orange[700],
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
  );
}

Widget _buildInputField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    validator: validator,
    style: const TextStyle(
      color: Colors.black87,
      fontSize: 16,
    ),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey[700],
        fontSize: 16,
      ),
      prefixIcon: Icon(icon, color: _primaryColor),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      errorStyle: const TextStyle(fontSize: 12),
    ),
  );
}

Widget _buildPasswordField({
  required TextEditingController controller,
  required String label,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    obscureText: true,
    validator: validator,
    style: const TextStyle(
      color: Colors.black87,
      fontSize: 16,
    ),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey[700],
        fontSize: 16,
      ),
      prefixIcon: Icon(Icons.lock_outline, color: _primaryColor),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
    ),
  );
}

Widget _buildActionButton() {
  return ElevatedButton(
    onPressed: _isLoading ? null : _register,
    style: ElevatedButton.styleFrom(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      shadowColor: _primaryColor.withOpacity(0.4),
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
      'REGISTER & VERIFY',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    ),
  );
}

@override
void dispose() {
  _firstNameController.dispose();
  _lastNameController.dispose();
  _emailController.dispose();
  _phoneController.dispose();
  _passwordController.dispose();
  _confirmPasswordController.dispose();
  _addressController.dispose();
  _cityController.dispose();
  _postalCodeController.dispose();
  super.dispose();
}
}