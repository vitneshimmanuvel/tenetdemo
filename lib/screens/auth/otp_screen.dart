import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/input_field.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();

  void _verifyOtp() {
    // You can integrate API verification logic here
    print('OTP Verified: ${_otpController.text}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InputField(controller: _otpController, hintText: 'Enter OTP'),
            const SizedBox(height: 20),
            CustomButton(text: 'Verify', onPressed: _verifyOtp),
          ],
        ),
      ),
    );
  }
}

