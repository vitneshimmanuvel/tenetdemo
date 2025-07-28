import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/constants/auth_service.dart';
import '/screens/user_preferences.dart';
import 'reset_password_screen.dart';
import '../dashboard/landlord_dashboard.dart';
import '../dashboard/tenant_dashboard.dart';
import 'admin_dashboard.dart';
import 'Login.dart';
import 'waiting_for_approval_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final String purpose;
  final String? userRole;

  const VerifyOtpScreen({
    super.key,
    required this.email,
    required this.purpose,
    this.userRole,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _otpControllers =
  List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  final Color _primaryColor = const Color(0xFF5B4FD5);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.verifyOtp(
        email: widget.email,
        otp: otp,
        purpose: widget.purpose,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        // Handle different purposes with correct navigation flow
        if (widget.purpose == 'reset') {
          // Password reset flow
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(
                email: widget.email,
                resetToken: response['resetToken'],
              ),
            ),
          );
        } else if (widget.purpose == 'admin_register') {
          // Admin registration flow - save admin data and navigate to dashboard
          if (response['admin'] != null) {
            await UserPreferences.saveUser(response['admin']);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboard()),
                  (route) => false,
            );
          } else {
            throw Exception('Admin data not received');
          }
        } else if (widget.purpose == 'register') {
          // Landlord registration verification flow
          if (response['user'] != null) {
            final user = response['user'];

            if (user['role'] == 'landlord') {
              // For landlords, show success message and navigate to waiting screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email verified successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );

              // Navigate to waiting for approval screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => WaitingForApprovalScreen(
                    email: widget.email,
                    name: user['name'] ?? 'User',
                  ),
                ),
              );
            } else {
              // For other user types (if any), navigate to login
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            }
          } else {
            throw Exception('User data not received');
          }
        } else {
          // Generic verification success
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'OTP verification failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleOtpInput(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index].unfocus();
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index].unfocus();
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    // Auto-verify when all fields are filled
    if (index == 5 && value.isNotEmpty) {
      bool allFieldsFilled = true;
      for (int i = 0; i < 6; i++) {
        if (_otpControllers[i].text.isEmpty) {
          allFieldsFilled = false;
          break;
        }
      }
      if (allFieldsFilled) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _verifyOtp();
        });
      }
    }
  }

  void _resendOtp() async {
    setState(() => _isResending = true);

    try {
      final response = await AuthService.sendOtp(
        email: widget.email,
        purpose: widget.purpose,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'OTP sent successfully'),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );

        // Clear OTP fields after resending
        if (response['success']) {
          for (var controller in _otpControllers) {
            controller.clear();
          }
          FocusScope.of(context).requestFocus(_focusNodes[0]);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend OTP: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  String _getPurposeTitle() {
    switch (widget.purpose) {
      case 'reset':
        return 'Reset Password';
      case 'admin_register':
        return 'Admin Registration';
      case 'register':
        return 'Verify Registration';
      default:
        return 'Verify Your Identity';
    }
  }

  String _getPurposeDescription() {
    switch (widget.purpose) {
      case 'reset':
        return 'Enter the code to reset your password';
      case 'admin_register':
        return 'Complete your admin registration';
      case 'register':
        return 'Verify your email to complete registration';
      default:
        return 'Enter the verification code';
    }
  }

  Color _getPurposeColor() {
    switch (widget.purpose) {
      case 'admin_register':
        return const Color(0xFF1976D2); // Admin blue
      case 'reset':
        return Colors.orange;
      default:
        return _primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final purposeColor = _getPurposeColor();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getPurposeTitle(),
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getPurposeTitle(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: purposeColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_getPurposeDescription()}\nWe sent a 6-digit code to ${widget.email}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: purposeColor, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    onChanged: (value) => _handleOtpInput(value, index),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),

            // Resend OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive the code?"),
                TextButton(
                  onPressed: _isResending ? null : _resendOtp,
                  child: _isResending
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: purposeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: purposeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'VERIFY',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Information box for different purposes
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: purposeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: purposeColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: purposeColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getInfoText(),
                      style: TextStyle(
                        color: purposeColor.withOpacity(0.8),
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
    );
  }

  String _getInfoText() {
    switch (widget.purpose) {
      case 'admin_register':
        return 'After verification, you will have full admin access to manage the platform.';
      case 'register':
        return 'After email verification, your account will be reviewed by admin for approval.';
      case 'reset':
        return 'This code will allow you to create a new password for your account.';
      default:
        return 'Enter the 6-digit code sent to your email address.';
    }
  }
}