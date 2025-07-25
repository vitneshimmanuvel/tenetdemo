import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/constants/auth_service.dart';
import 'reset_password_screen.dart';
import '../dashboard/landlord_dashboard.dart';
import '../dashboard/tenant_dashboard.dart';

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
  final Color _primaryColor = const Color(0xFF5B4FD5);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  void _verifyOtp() async {
    setState(() => _isLoading = true);
    final otp = _otpControllers.map((c) => c.text).join();

    try {
      final response = await AuthService.verifyOtp(
        email: widget.email,
        otp: otp,
        purpose: widget.purpose,
      );

      if (response['success'] == true) {
        if (widget.purpose == 'reset') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(
                email: widget.email,
                resetToken: response['resetToken'],
              ),
            ),
          );
        } else if (widget.purpose == 'login') {
          if (widget.userRole == 'landlord') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LandlordDashboard()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TenantDashboard()),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'OTP verification failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
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

    if (index == 5 && value.isNotEmpty) {
      _verifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.purpose == 'reset'
                  ? 'Reset Password'
                  : 'Verify Your Identity',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a 6-digit code to ${widget.email}',
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
                    style: const TextStyle(fontSize: 24),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _primaryColor, width: 2),
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
                  onPressed: () {
                    AuthService.sendOtp(
                      email: widget.email,
                      purpose: widget.purpose,
                    );
                  },
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(color: _primaryColor),
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
                  backgroundColor: _primaryColor,
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
          ],
        ),
      ),
    );
  }
}