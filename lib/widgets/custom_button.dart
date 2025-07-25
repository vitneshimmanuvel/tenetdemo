
  import 'package:flutter/material.dart';
  import '../constants/colors.dart';

  class CustomButton extends StatelessWidget {
    final String text;
    final VoidCallback onPressed;
    final bool isLoading;

    const CustomButton({
      super.key,
      required this.text,
      required this.onPressed,
      this.isLoading = false,
    });

    @override
    Widget build(BuildContext context) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 4,
          ),
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }
