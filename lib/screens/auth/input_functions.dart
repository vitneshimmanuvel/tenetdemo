import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputFunctions {
  // Input Formatters
  static final nameInputFormatter = FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'));
  static final phoneInputFormatter = FilteringTextInputFormatter.digitsOnly;
  static final pinCodeInputFormatter = FilteringTextInputFormatter.digitsOnly;

  // Validators
  static String? validateName(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return '$fieldName can only contain letters';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final email = value.trim().toLowerCase();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final phone = value.replaceAll(RegExp(r'\D'), '');
    if (phone.length != 10) {
      return 'Mobile number must be exactly 10 digits';
    }
    // Optional: Check if it starts with valid digits (like 6,7,8,9 for Indian mobile numbers)
    // if (!RegExp(r'^[6-9]').hasMatch(phone)) {
    //   return 'Please enter a valid mobile number';
    // }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    // Optional: Add more password strength requirements
    // if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
    //   return 'Password must contain uppercase, lowercase, and number';
    // }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 5) {
      return 'Please enter a complete address';
    }
    return null;
  }

  static String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'City name can only contain letters';
    }
    return null;
  }

  static String? validatePinCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PIN code is required';
    }
    final pinCode = value.trim();
    if (pinCode.length != 6) {
      return 'PIN code must be exactly 6 digits';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(pinCode)) {
      return 'PIN code can only contain numbers';
    }
    return null;
  }

  // Text Formatters
  static String formatPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '${digits.substring(0, 5)} ${digits.substring(5, 10)}';
    }
    return digits;
  }

  static String formatPinCode(String value) {
    final code = value.replaceAll(RegExp(r'\D'), '');
    return code;
  }

  // Common Input Field Builder
  static Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryColor,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool enabled = true,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      enabled: enabled,
      onChanged: onChanged,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[700],
          fontSize: 16,
        ),
        prefixIcon: Icon(icon, color: primaryColor),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        errorStyle: const TextStyle(fontSize: 12, height: 0.8),
      ),
    );
  }

  // Password Field Builder
  static Widget buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required Color primaryColor,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      enabled: enabled,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[700],
          fontSize: 16,
        ),
        prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[600],
          ),
          onPressed: enabled ? onToggleVisibility : null,
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        errorStyle: const TextStyle(fontSize: 12, height: 0.8),
      ),
    );
  }

  // Email formatter - lowercase and trim
  static String formatEmail(String email) {
    return email.trim().toLowerCase();
  }

  // Name formatter - proper case
  static String formatName(String name) {
    return name.trim().split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}