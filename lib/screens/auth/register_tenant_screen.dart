import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '/constants/auth_service.dart';
import '/screens/user_preferences.dart';
import 'input_functions.dart';
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

  // Document upload variables for 4 documents
  final List<XFile?> _selectedDocuments = [null, null, null, null];
  final List<String?> _documentTypes = [null, null, null, null];
  final List<String> _documentLabels = [
    'Document 1 (Mandatory)',
    'Document 2 (Optional)',
    'Document 3 (Optional)',
    'Document 4 (Optional)'
  ];

  final ImagePicker _picker = ImagePicker();

  // Document type options
  final List<Map<String, dynamic>> _documentTypeOptions = [
    {'value': 'passport', 'label': 'Passport', 'icon': Icons.contact_page, 'type': 'image'},
    {'value': 'license', 'label': 'Driver\'s License', 'icon': Icons.credit_card, 'type': 'image'},
    {'value': 'residential_proof', 'label': 'Residential Proof', 'icon': Icons.home, 'type': 'document'},
    {'value': 'other', 'label': 'Other Document', 'icon': Icons.description, 'type': 'document'},
  ];

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

  Future<void> _pickDocument(int index) async {
    if (_documentTypes[index] == null) {
      _showErrorSnackBar('Please select document type first', Colors.orange);
      return;
    }

    final selectedDocType = _documentTypeOptions.firstWhere(
          (type) => type['value'] == _documentTypes[index],
    );

    if (selectedDocType['type'] == 'image') {
      // For passport/license - show camera/gallery options
      _showImageSourceBottomSheet(index);
    } else {
      // For documents - show file picker
      await _pickDocumentFile(index);
    }
  }

  void _showImageSourceBottomSheet(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _pickFromImageSource(ImageSource.camera, index),
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickFromImageSource(ImageSource.gallery, index),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ✅ COMPLETELY FIXED: Image selection with immediate bytes conversion
  Future<void> _pickFromImageSource(ImageSource source, int index) async {
    Navigator.pop(context); // Close bottom sheet

    try {
      print('📷 Starting image selection from ${source == ImageSource.camera ? 'camera' : 'gallery'}');

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        print('📷 Image selected: ${image.name}, Path: ${image.path}');

        try {
          // ✅ CRITICAL FIX: Always convert to bytes immediately
          final bytes = await image.readAsBytes();
          print('📄 Image bytes length: ${bytes.length}');

          if (bytes.isEmpty) {
            throw Exception('Selected image has no data');
          }

          // Create new XFile from bytes (no path dependency)
          final xFile = XFile.fromData(
            bytes,
            name: image.name.isNotEmpty ? image.name : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
            mimeType: 'image/jpeg',
          );

          setState(() {
            _selectedDocuments[index] = xFile;
          });

          _showSuccessSnackBar('${_documentLabels[index]} selected successfully', _primaryColor);
          print('✅ Image stored as bytes: ${xFile.name} (${bytes.length} bytes)');

        } catch (bytesError) {
          print('❌ Failed to read image bytes: $bytesError');
          _showErrorSnackBar('Failed to process selected image', Colors.red);
        }
      } else {
        print('❌ No image selected');
      }
    } catch (e) {
      print('❌ Image picker error: $e');
      _showErrorSnackBar('Failed to select image: ${e.toString()}', Colors.red);
    }
  }

  // ✅ COMPLETELY FIXED: Document selection with immediate bytes conversion
  Future<void> _pickDocumentFile(int index) async {
    try {
      print('📁 Starting file picker for document ${index + 1}...');

      FilePickerResult? result;

      if (kIsWeb) {
        // WEB: Always load data
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
          allowMultiple: false,
          withData: true,
          withReadStream: false,
        );
      } else {
        // MOBILE: Use path but read immediately
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
          allowMultiple: false,
          withData: false,
          withReadStream: false,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('📄 File selected: ${file.name}, Size: ${file.size} bytes');

        try {
          XFile xFile;

          if (kIsWeb) {
            // ✅ WEB: Use bytes from picker
            if (file.bytes != null && file.bytes!.isNotEmpty) {
              xFile = XFile.fromData(
                file.bytes!,
                name: file.name,
                mimeType: _getMimeType(file.extension ?? ''),
              );
              print('✅ Web file processed: ${file.name} (${file.bytes!.length} bytes)');
            } else {
              throw Exception('File data not available on web');
            }
          } else {
            // ✅ MOBILE: Read file immediately while path is valid
            if (file.path != null && file.path!.isNotEmpty) {
              print('📂 Reading file from path: ${file.path}');

              final fileObject = File(file.path!);

              // Check if file exists
              if (!await fileObject.exists()) {
                throw Exception('Selected file no longer exists at path: ${file.path}');
              }

              final bytes = await fileObject.readAsBytes();
              print('📄 File bytes read: ${bytes.length}');

              if (bytes.isEmpty) {
                throw Exception('Selected file is empty');
              }

              // Create XFile from bytes (no path dependency)
              xFile = XFile.fromData(
                bytes,
                name: file.name,
                mimeType: _getMimeType(file.extension ?? ''),
              );

              print('✅ Mobile file stored as bytes: ${file.name} (${bytes.length} bytes)');
            } else {
              throw Exception('File path not available on mobile');
            }
          }

          setState(() {
            _selectedDocuments[index] = xFile;
          });

          _showSuccessSnackBar('${_documentLabels[index]} selected successfully', _primaryColor);
          print('✅ Document ${index + 1} successfully processed: ${file.name}');

        } catch (fileProcessError) {
          print('❌ File processing error: $fileProcessError');
          _showErrorSnackBar('Failed to process selected file', Colors.red);
        }
      } else {
        print('❌ No file selected or file picker cancelled');
      }

    } catch (e) {
      print('❌ File picker error: $e');

      if (e.toString().contains('LateInitializationError') ||
          e.toString().contains('_instance') ||
          e.toString().contains('not been initialized')) {
        print('🔄 File picker initialization error, offering image picker fallback...');
        _showFilePickerErrorDialog(index);
      } else {
        _showErrorSnackBar('Failed to select document: ${e.toString()}', Colors.red);
      }
    }
  }

  void _showFilePickerErrorDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Picker Error'),
        content: const Text(
            'Unable to open file picker. Would you like to take a photo of your document instead?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showImageSourceBottomSheet(index);
            },
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
            ),
            child: const Text('Use Camera'),
          ),
        ],
      ),
    );
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primaryColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: _primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      // Validate mandatory document
      if (_selectedDocuments[0] == null) {
        _showErrorSnackBar('Please upload the mandatory document (Document 1)', Colors.orange);
        return;
      }

      if (_documentTypes[0] == null) {
        _showErrorSnackBar('Please select document type for Document 1', Colors.orange);
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Format names properly
        String firstName = InputFunctions.formatName(_firstNameController.text);
        String lastName = InputFunctions.formatName(_lastNameController.text);
        String fullName = lastName.isNotEmpty ? '$firstName $lastName' : firstName;

        // Format email
        String email = InputFunctions.formatEmail(_emailController.text);

        // Clean phone number
        String phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

        print('🚀 Starting enhanced tenant registration for: $fullName ($email)');

        // ✅ VALIDATION: Check documents before upload
        for (int i = 0; i < 4; i++) {
          if (_selectedDocuments[i] != null) {
            try {
              final testBytes = await _selectedDocuments[i]!.readAsBytes();
              if (testBytes.isEmpty) {
                throw Exception('Document ${i + 1} has no data');
              }
              print('✅ Document ${i + 1} validation passed: ${testBytes.length} bytes');
            } catch (e) {
              _showErrorSnackBar('Document ${i + 1} is invalid. Please select again.', Colors.red);
              setState(() => _isLoading = false);
              return;
            }
          }
        }

        final response = await AuthService.registerTenantWithMultipleDocuments(
          name: fullName,
          email: email,
          phone: phone,
          password: _passwordController.text,
          documents: _selectedDocuments,
          documentTypes: _documentTypes,
        );

        print('📥 Registration API Response: $response');

        if (!mounted) return;

        if (response['success'] == true) {
          print('✅ Registration successful, showing admin verification message');
          await _showAdminVerificationDialog(response['documentsUploaded'] ?? 0);
        } else {
          String errorMessage = response['message'] ?? 'Registration failed. Please try again.';
          Color errorColor = Colors.red;

          if (errorMessage.toLowerCase().contains('email already') ||
              errorMessage.toLowerCase().contains('already registered')) {
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
          _showErrorSnackBar('Registration failed. Please try again.', Colors.red);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _showAdminVerificationDialog(int documentsUploaded) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_empty, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Verification Pending',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registration Successful!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: _primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$documentsUploaded Documents Uploaded',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• Our admin team will review your documents\n'
                            '• Verification typically takes 24-48 hours\n'
                            '• You\'ll receive an email once approved\n'
                            '• After approval, you can login and access all features',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.maxFinite,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Go to Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDocumentUploadSection(int index) {
    final isSelected = _selectedDocuments[index] != null;
    final docType = _documentTypes[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _documentLabels[index],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: index == 0 ? Colors.red : _primaryColor,
          ),
        ),
        if (index == 0)
          Text(
            'Required for account verification',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(height: 8),

        // Document Type Selection
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: _primaryColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: docType,
              hint: Text(
                'Select Document Type ${index == 0 ? '*' : ''}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
              items: _documentTypeOptions.map<DropdownMenuItem<String>>((option) {
                return DropdownMenuItem<String>(
                  value: option['value'] as String,
                  child: Row(
                    children: [
                      Icon(option['icon'] as IconData, color: _primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(option['label'] as String),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: option['type'] == 'image' ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          option['type'] == 'image' ? 'Photo' : 'Doc',
                          style: TextStyle(
                            fontSize: 10,
                            color: option['type'] == 'image' ? Colors.blue : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _documentTypes[index] = newValue;
                  _selectedDocuments[index] = null; // Reset selected file when type changes
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Document Upload Button
        GestureDetector(
          onTap: docType != null ? () => _pickDocument(index) : null,
          child: Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? _primaryColor
                    : (docType != null ? _primaryColor.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? _primaryColor.withOpacity(0.1)
                  : (docType != null ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.05)),
            ),
            child: isSelected
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: _primaryColor, size: 32),
                const SizedBox(height: 6),
                Text(
                  'Document Selected',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Tap to change',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  docType != null
                      ? (_documentTypeOptions.firstWhere((t) => t['value'] == docType)['type'] == 'image'
                      ? Icons.camera_alt
                      : Icons.upload_file)
                      : Icons.upload_file,
                  size: 32,
                  color: docType != null ? _primaryColor : Colors.grey,
                ),
                const SizedBox(height: 6),
                Text(
                  docType != null
                      ? (_documentTypeOptions.firstWhere((t) => t['value'] == docType)['type'] == 'image'
                      ? 'Tap to take photo or select from gallery'
                      : 'Tap to upload document or take photo')
                      : 'Select document type first',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: docType != null ? _primaryColor : Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 2000),
        margin: const EdgeInsets.all(16),
        elevation: 6,
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
          'CREATE ACCOUNT WITH DOCUMENTS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
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
                  // Header
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

                  // Title Section
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
                        'Join with comprehensive document verification',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Basic Information
                  Text(
                    'Basic Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

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
                  const SizedBox(height: 32),

                  // Document Upload Sections
                  Text(
                    'Document Verification',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload your identity and supporting documents for verification',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4 Document Upload Sections
                  ...List.generate(4, (index) => Column(
                    children: [
                      _buildDocumentUploadSection(index),
                      if (index < 3) const SizedBox(height: 24),
                    ],
                  )),

                  const SizedBox(height: 32),

                  // Register button
                  _buildRegisterButton(),
                  const SizedBox(height: 24),

                  // Info box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Document 1 is mandatory. Additional documents help speed up verification. Supported formats: Images (JPG, PNG) for ID documents, PDF/DOC for other documents.',
                            style: TextStyle(
                              color: Colors.blue.withOpacity(0.8),
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
}
