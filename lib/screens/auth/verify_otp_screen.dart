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

class _VerifyOtpScreenState extends State<VerifyOtpScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
  List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _animationController.forward();

    Future.delayed(Duration.zero, () {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shakeController.dispose();
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

      _showSnackBar(
        'Please enter complete OTP',
        Colors.orange,
        Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Verifying OTP: $otp for ${widget.email} with purpose ${widget.purpose}');

      final response = await AuthService.verifyOtp(
        email: widget.email,
        otp: otp,
        purpose: widget.purpose,
      );

      if (!mounted) return;

      print('OTP verification response: $response');

      if (response['success'] == true) {
        await UserPreferences.clearTempUserData();

        // Handle different purposes with correct navigation flow
        if (widget.purpose == 'reset') {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => ResetPasswordScreen(
                email: widget.email,
                resetToken: response['resetToken'],
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: animation.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
                  child: child,
                );
              },
            ),
          );
        } else if (widget.purpose == 'admin_register') {
          if (response['admin'] != null) {
            await UserPreferences.saveUser(response['admin']);
            _showSnackBar(
              'Admin account verified successfully!',
              Colors.green,
              Icons.check_circle,
            );
            await Future.delayed(const Duration(seconds: 1));
            Navigator.pushAndRemoveUntil(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const AdminDashboard(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
                  (route) => false,
            );
          } else {
            throw Exception('Admin data not received');
          }
        } else if (widget.purpose == 'tenant_register') {
          if (response['user'] != null) {
            final user = response['user'];
            print('Tenant verification successful: ${user['name']} (${user['tenancyId'] ?? 'No tenancy ID'})');
            await UserPreferences.saveUser(user);

            _showSnackBar(
              'Welcome ${user['name']}! Account verified.',
              Colors.green,
              Icons.celebration,
            );
            await Future.delayed(const Duration(milliseconds: 1000));

            Navigator.pushAndRemoveUntil(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const TenantDashboard(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
                  (route) => false,
            );
          } else {
            throw Exception('User data not received from server');
          }
        } else if (widget.purpose == 'register') {
          if (response['user'] != null) {
            final user = response['user'];
            if (user['role'] == 'landlord') {
              _showSnackBar(
                'Email verified! Waiting for admin approval.',
                Colors.green,
                Icons.check_circle,
              );
              await Future.delayed(const Duration(seconds: 1));
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => WaitingForApprovalScreen(
                    email: widget.email,
                    name: user['name'] ?? 'User',
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
                      child: child,
                    );
                  },
                ),
              );
            } else {
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
          Navigator.pop(context);
        }
      } else {

        _showSnackBar(
          response['message'] ?? 'OTP verification failed',
          Colors.red,
          Icons.error_outline,
        );
      }
    } catch (e) {
      print('OTP verification error: $e');
      if (mounted) {

        String errorMessage = 'Verification failed. Please try again.';

        if (e.toString().contains('invalid') || e.toString().contains('Invalid')) {
          errorMessage = 'Invalid OTP. Please check and try again.';
        } else if (e.toString().contains('expired') || e.toString().contains('Expired')) {
          errorMessage = 'OTP has expired. Please request a new one.';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        _showSnackBar(errorMessage, Colors.red, Icons.error_outline);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
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
      bool allFieldsFilled = _otpControllers.every((controller) => controller.text.isNotEmpty);
      if (allFieldsFilled) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _verifyOtp();
        });
      }
    }
  }

  void _resendOtp() async {
    setState(() => _isResending = true);

    try {
      print('Resending OTP for ${widget.email} with purpose ${widget.purpose}');

      final response = await AuthService.sendOtp(
        email: widget.email,
        purpose: widget.purpose,
      );

      if (mounted) {
        _showSnackBar(
          response['message'] ?? 'OTP sent successfully',
          response['success'] ? Colors.green : Colors.red,
          response['success'] ? Icons.check_circle : Icons.error_outline,
        );

        if (response['success']) {
          // Clear all OTP fields with animation
          for (var controller in _otpControllers) {
            controller.clear();
          }
          FocusScope.of(context).requestFocus(_focusNodes[0]);
        }
      }
    } catch (e) {
      print('Resend OTP error: $e');
      if (mounted) {
        _showSnackBar(
          'Failed to resend OTP. Please try again.',
          Colors.red,
          Icons.error_outline,
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
      case 'tenant_register':
        return 'Verify Your Email';
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
      case 'tenant_register':
        return 'Verify your email to access your tenant account';
      default:
        return 'Enter the verification code';
    }
  }

  Color _getPurposeColor() {
    switch (widget.purpose) {
      case 'admin_register':
        return const Color(0xFF1976D2);
      case 'reset':
        return const Color(0xFFFF7043);
      case 'tenant_register':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF5B4FD5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final purposeColor = _getPurposeColor();
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[700], size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getPurposeTitle(),
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top - kToolbarHeight,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    isKeyboardVisible ? 16 : 32,
                    24,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header section with icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: purposeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: purposeColor.withOpacity(0.3), width: 2),
                        ),
                        child: Icon(
                          _getPurposeIcon(),
                          color: purposeColor,
                          size: 36,
                        ),
                      ),
                      SizedBox(height: isKeyboardVisible ? 16 : 24),

                      Text(
                        _getPurposeTitle(),
                        style: TextStyle(
                          fontSize: isKeyboardVisible ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: purposeColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isKeyboardVisible ? 8 : 12),

                      Text(
                        _getPurposeDescription(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: purposeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: purposeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: isKeyboardVisible ? 24 : 40),

                      // OTP Input Fields with shake animation
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value * 10 * (1 - _shakeAnimation.value), 0),
                            child: child,
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (index) {
                            return Container(
                              width: 50,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _otpControllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: purposeColor, width: 2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Colors.red, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onChanged: (value) => _handleOtpInput(value, index),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                      SizedBox(height: isKeyboardVisible ? 20 : 30),

                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purposeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: purposeColor.withOpacity(0.4),
                            disabledBackgroundColor: purposeColor.withOpacity(0.6),
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
                            'VERIFY CODE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isKeyboardVisible ? 16 : 24),

                      // Resend OTP
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive the code? ",
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                          TextButton(
                            onPressed: _isResending ? null : _resendOtp,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: _isResending
                                ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(purposeColor),
                              ),
                            )
                                : Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: purposeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (!isKeyboardVisible) ...[
                        const SizedBox(height: 20),
                        // Info container
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: purposeColor.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: purposeColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  color: purposeColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getInfoText(),
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Additional help text for tenant
                        if (widget.purpose == 'tenant_register') ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.withOpacity(0.1),
                                  Colors.green.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.rocket_launch, color: Colors.green[600], size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Once verified, you\'ll have instant access to your tenant dashboard with all features enabled.',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getPurposeIcon() {
    switch (widget.purpose) {
      case 'admin_register':
        return Icons.admin_panel_settings;
      case 'register':
        return Icons.how_to_reg;
      case 'reset':
        return Icons.lock_reset;
      case 'tenant_register':
        return Icons.verified_user;
      default:
        return Icons.security;
    }
  }

  String _getInfoText() {
    switch (widget.purpose) {
      case 'admin_register':
        return 'After verification, you will have full admin access to manage the platform with complete control over all features.';
      case 'register':
        return 'After email verification, your account will be reviewed by our admin team for approval. You\'ll be notified once approved.';
      case 'reset':
        return 'This secure code will allow you to create a new password for your account. Keep it confidential.';
      case 'tenant_register':
        return 'After verification, you will have immediate access to your tenant account with all features enabled including rent payments and maintenance requests.';
      default:
        return 'Enter the 6-digit verification code sent to your email address to continue.';
    }
  }
}