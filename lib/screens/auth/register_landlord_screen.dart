import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/constants/auth_service.dart';
import 'input_functions.dart'; // Import your InputFunctions
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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Custom postal code validation and formatting methods
  String? _validatePostalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Postal code is required';
    }

    final cleanValue = value.trim().replaceAll(' ', '');

    // Check if it's 6 digits
    if (!RegExp(r'^\d{6}$').hasMatch(cleanValue)) {
      return 'Enter a valid 6-digit postal code';
    }

    return null;
  }

  String _formatPostalCode(String value) {
    // Remove all non-digits
    String digits = value.replaceAll(RegExp(r'\D'), '');

    // Limit to 6 digits
    if (digits.length > 6) {
      digits = digits.substring(0, 6);
    }

    return digits;
  }

  // Custom postal code input formatter
  TextInputFormatter get _postalCodeInputFormatter {
    return FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));
  }

  Future<void> _register() async {
    print('Register button pressed'); // Debug log

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed'); // Debug log
      return;
    }

    setState(() => _isLoading = true);
    print('Starting registration process...'); // Debug log

    try {
      // Format the data before sending
      final formattedFirstName = InputFunctions.formatName(_firstNameController.text);
      final formattedLastName = InputFunctions.formatName(_lastNameController.text);
      final fullName = '$formattedFirstName $formattedLastName';
      final formattedEmail = InputFunctions.formatEmail(_emailController.text);
      final formattedPhone = _phoneController.text.trim();
      final formattedPostalCode = _formatPostalCode(_postalCodeController.text);

      print('Full name: $fullName'); // Debug log
      print('Email: $formattedEmail'); // Debug log

      final response = await AuthService.registerLandlord(
        name: fullName,
        email: formattedEmail,
        phone: formattedPhone,
        password: _passwordController.text,
        address: _addressController.text.trim(),
        postalCode: formattedPostalCode,
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
              email: formattedEmail,
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
                        validator: (value) => InputFunctions.validateName(value, fieldName: 'Last name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Email Field
                InputFunctions.buildInputField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  primaryColor: _primaryColor,
                  keyboardType: TextInputType.emailAddress,
                  validator: InputFunctions.validateEmail,
                ),
                const SizedBox(height: 20),

                // Phone Field
                InputFunctions.buildInputField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  primaryColor: _primaryColor,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [InputFunctions.phoneInputFormatter],
                  validator: InputFunctions.validatePhone,
                  onChanged: (value) {
                    // Auto-format phone number as user types
                    final formatted = InputFunctions.formatPhone(value);
                    if (formatted != value) {
                      _phoneController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Address Field
                InputFunctions.buildInputField(
                  controller: _addressController,
                  label: 'Complete Address',
                  icon: Icons.location_on_outlined,
                  primaryColor: _primaryColor,
                  textCapitalization: TextCapitalization.words,
                  validator: InputFunctions.validateAddress,
                ),
                const SizedBox(height: 20),

                // City and Postal Code Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: InputFunctions.buildInputField(
                        controller: _cityController,
                        label: 'City',
                        icon: Icons.location_city_outlined,
                        primaryColor: _primaryColor,
                        inputFormatters: [InputFunctions.nameInputFormatter],
                        textCapitalization: TextCapitalization.words,
                        validator: InputFunctions.validateCity,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InputFunctions.buildInputField(
                        controller: _postalCodeController,
                        label: 'Postal Code',
                        icon: Icons.local_post_office_outlined,
                        primaryColor: _primaryColor,
                        inputFormatters: [_postalCodeInputFormatter],
                        keyboardType: TextInputType.number,
                        validator: _validatePostalCode,
                        onChanged: (value) {
                          // Auto-format postal code as user types
                          final formatted = _formatPostalCode(value);
                          if (formatted != value) {
                            _postalCodeController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Password Field
                InputFunctions.buildPasswordField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: _obscurePassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  primaryColor: _primaryColor,
                  validator: InputFunctions.validatePassword,
                ),
                const SizedBox(height: 20),

                // Confirm Password Field
                InputFunctions.buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  primaryColor: _primaryColor,
                  validator: (value) => InputFunctions.validateConfirmPassword(value, _passwordController.text),
                ),
                const SizedBox(height: 40),

                // Register Button
                _buildActionButton(),
                const SizedBox(height: 32),

                // Verification Info Container
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