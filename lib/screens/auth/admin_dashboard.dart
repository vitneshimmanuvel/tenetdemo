import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;
import '/constants/auth_service.dart';
import '/screens/user_preferences.dart';
import 'Login.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pendingLandlords = [];
  List<Map<String, dynamic>> _pendingProperties = [];
  List<Map<String, dynamic>> _pendingTenants = [];
  List<Map<String, dynamic>> _allTenants = [];
  List<Map<String, dynamic>> _allLandlords = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await Future.wait([
        _loadStats(),
        _loadPendingLandlords(),
        _loadPendingProperties(),
        _loadPendingTenants(),
        _loadAllTenants(),
        _loadAllLandlords(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await AuthService.getAdminStats();
      setState(() {
        _stats = stats ?? {
          'totalTenants': 0,
          'totalLandlords': 0,
          'totalProperties': 0,
        };
      });
    } catch (e) {
      setState(() {
        _stats = {
          'totalTenants': 0,
          'totalLandlords': 0,
          'totalProperties': 0,
        };
      });
    }
  }

  Future<void> _loadPendingLandlords() async {
    try {
      final landlords = await AuthService.getPendingLandlords();
      setState(() {
        _pendingLandlords = landlords ?? [];
      });
    } catch (e) {
      setState(() {
        _pendingLandlords = [];
      });
    }
  }

  Future<void> _loadPendingProperties() async {
    try {
      final properties = await AuthService.getPendingProperties();
      setState(() {
        _pendingProperties = properties ?? [];
      });
    } catch (e) {
      setState(() {
        _pendingProperties = [];
      });
    }
  }

  Future<void> _loadPendingTenants() async {
    try {
      final tenants = await AuthService.getPendingTenants();
      setState(() {
        _pendingTenants = tenants ?? [];
      });
    } catch (e) {
      setState(() {
        _pendingTenants = [];
      });
    }
  }

  Future<void> _loadAllTenants() async {
    try {
      final tenants = await AuthService.getAllTenants();
      setState(() {
        _allTenants = tenants ?? [];
      });
    } catch (e) {
      setState(() {
        _allTenants = [];
      });
    }
  }

  Future<void> _loadAllLandlords() async {
    try {
      final landlords = await AuthService.getAllLandlords();
      setState(() {
        _allLandlords = landlords ?? [];
      });
    } catch (e) {
      setState(() {
        _allLandlords = [];
      });
    }
  }

  // Verification handlers
  Future<void> _handleLandlordVerification(int landlordId, bool approve) async {
    _showLoadingDialog();

    try {
      final result = await AuthService.verifyLandlord(landlordId, approve);

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(
          result['message'] ?? 'Landlord ${approve ? 'approved' : 'rejected'} successfully',
          approve ? Colors.green : Colors.red,
        );

        if (result['success'] == true) {
          _loadDashboardData();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Failed to update: $e', Colors.red);
      }
    }
  }

  Future<void> _handlePropertyRequest(int propertyId, bool approve) async {
    _showLoadingDialog();

    try {
      final result = await AuthService.verifyProperty(propertyId, approve);

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(
          result['message'] ?? 'Property ${approve ? 'approved' : 'rejected'} successfully',
          approve ? Colors.green : Colors.red,
        );

        if (result['success'] == true) {
          _loadDashboardData();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Failed to update: $e', Colors.red);
      }
    }
  }

  Future<void> _handleTenantVerification(int tenantId, bool approve) async {
    _showLoadingDialog();

    try {
      final result = await AuthService.verifyTenant(tenantId, approve);

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(
          result['message'] ?? 'Tenant ${approve ? 'approved' : 'rejected'} successfully',
          approve ? Colors.green : Colors.red,
        );

        if (result['success'] == true) {
          _loadDashboardData();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Failed to update: $e', Colors.red);
      }
    }
  }

  // UI Helper functions
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Processing...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Document handling functions
  String _getFileType(String url) {
    final extension = path.extension(url).toLowerCase();
    switch (extension) {
      case '.pdf':
        return 'PDF';
      case '.jpg':
      case '.jpeg':
        return 'JPEG';
      case '.png':
        return 'PNG';
      case '.gif':
        return 'GIF';
      case '.bmp':
        return 'BMP';
      case '.webp':
        return 'WEBP';
      case '.doc':
      case '.docx':
        return 'DOC';
      case '.xls':
      case '.xlsx':
        return 'XLS';
      case '.ppt':
      case '.pptx':
        return 'PPT';
      case '.txt':
        return 'TXT';
      case '.rtf':
        return 'RTF';
      default:
        return 'FILE';
    }
  }

  Color _getFileColor(String fileType) {
    switch (fileType) {
      case 'PDF':
        return Colors.red;
      case 'JPEG':
      case 'PNG':
      case 'GIF':
      case 'BMP':
      case 'WEBP':
        return Colors.blue;
      case 'DOC':
        return Colors.indigo;
      case 'XLS':
        return Colors.green;
      case 'PPT':
        return Colors.orange;
      case 'TXT':
      case 'RTF':
        return Colors.grey;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DOC':
        return Icons.description;
      case 'XLS':
        return Icons.table_chart;
      case 'PPT':
        return Icons.slideshow;
      case 'TXT':
      case 'RTF':
        return Icons.text_snippet;
      case 'JPEG':
      case 'PNG':
      case 'GIF':
      case 'BMP':
      case 'WEBP':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  bool _isImageFile(String url) {
    final extension = path.extension(url).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }

  bool _isPdfFile(String fileType) {
    return fileType == 'PDF';
  }

  // Document opening function - Updated with proper DocumentViewer integration
  Future<void> _openDocument(String url, String docType, {String? docName}) async {
    try {
      // Clean and validate URL
      String cleanUrl = url.trim();
      if (cleanUrl.isEmpty) {
        _showSnackBar('Invalid document URL', Colors.red);
        return;
      }

      // Ensure proper URL format
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      // Navigate to document viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentViewer(
            documentUrl: cleanUrl,
            documentName: docName ?? 'Document',
            documentType: docType,
          ),
        ),
      );

    } catch (e) {
      print('Error opening document: $e');
      _showSnackBar('Could not open document: ${e.toString()}', Colors.red);
    }
  }

  // External document opening
  Future<void> _openExternalDocument(String url) async {
    try {
      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showSnackBar('Cannot open this document type externally', Colors.red);
      }
    } catch (e) {
      print('Error launching external app: $e');
      _showSnackBar('Failed to open document: $e', Colors.red);
    }
  }

  // View tenant and landlord details
  void _viewTenantDetails(Map<String, dynamic> tenant) async {
    _showLoadingDialog();

    try {
      final tenantId = tenant['id'];
      if (tenantId == null) {
        throw Exception('Tenant ID is null');
      }

      final details = await AuthService.getTenantDetails(tenantId.toString());

      if (mounted) {
        Navigator.pop(context);
        _showTenantDetailsDialog(details);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Failed to load tenant details: $e', Colors.red);
      }
    }
  }

  void _viewLandlordDetails(Map<String, dynamic> landlord) async {
    _showLoadingDialog();

    try {
      final landlordId = landlord['id'];
      if (landlordId == null) {
        throw Exception('Landlord ID is null');
      }

      final details = await AuthService.getLandlordDetails(landlordId.toString());

      if (mounted) {
        Navigator.pop(context);
        _showLandlordDetailsDialog(details);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Failed to load landlord details: $e', Colors.red);
      }
    }
  }

  // Document dialogs and UI components
  void _showTenantDocumentDialog(Map<String, dynamic> tenant) {
    final tenantId = _getSafeInt(tenant['id']);

    // Collect all documents
    List<Map<String, dynamic>> documents = [];

    for (int i = 1; i <= 4; i++) {
      final docType = _getSafeString(tenant['document${i}_type']);
      final docUrl = _getSafeString(tenant['document${i}_url']);
      final isMandatory = tenant['document${i}_mandatory'] == true;

      if (docType.isNotEmpty && docUrl.isNotEmpty) {
        final fileType = _getFileType(docUrl);
        documents.add({
          'number': i,
          'type': docType,
          'url': docUrl,
          'mandatory': isMandatory,
          'fileType': fileType,
          'isImage': _isImageFile(docUrl),
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.95,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Document Verification',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tenant Info Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    _getSafeString(tenant['name']).isNotEmpty
                                        ? _getSafeString(tenant['name'])[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getSafeString(tenant['name']),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1565C0),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _getSafeString(tenant['email']),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: documents.isNotEmpty ? Colors.green : Colors.orange,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${documents.length} Docs',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoItem('📞', 'Phone', _getSafeString(tenant['phone'])),
                                ),
                                Expanded(
                                  child: _buildInfoItem('🆔', 'Tenancy ID', _getSafeString(tenant['tenancy_id'])),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Documents Section
                      if (documents.isNotEmpty) ...[
                        Text(
                          'Uploaded Documents (${documents.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),

                        ...documents.map((doc) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: _buildEnhancedDocumentCard(doc),
                        )).toList(),
                      ] else ...[
                        // Empty State
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No Documents Available',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'This tenant hasn\'t uploaded any documents yet.',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleTenantVerification(tenantId, false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: documents.isNotEmpty
                            ? () {
                          Navigator.pop(context);
                          _handleTenantVerification(tenantId, true);
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: documents.isNotEmpty ? Colors.green[600] : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String label, String value) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDocumentCard(Map<String, dynamic> doc) {
    final fileType = doc['fileType'] as String;
    final fileColor = _getFileColor(fileType);
    final isImage = doc['isImage'] as bool;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: doc['mandatory'] ? Colors.red[200]! : Colors.blue[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // File Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fileColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(fileType),
              color: fileColor,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Document Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Document ${doc['number']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (doc['mandatory'])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'REQUIRED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  doc['type'].toString(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                Text(
                  fileType,
                  style: TextStyle(
                    color: fileColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isImage)
                IconButton(
                  onPressed: () => _openDocument(
                      doc['url'],
                      fileType,
                      docName: '${doc['type']} - Document ${doc['number']}'
                  ),
                  icon: const Icon(Icons.zoom_in, size: 20),
                  tooltip: 'View Full Screen',
                ),
              IconButton(
                onPressed: () => _openDocument(
                    doc['url'],
                    fileType,
                    docName: '${doc['type']} - Document ${doc['number']}'
                ),
                icon: const Icon(Icons.open_in_new, size: 20),
                tooltip: 'Open Document',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTenantDetailsDialog(Map<String, dynamic> details) {
    final tenant = details['tenant'] ?? {};
    final ratings = details['ratings'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tenant Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info
                      _buildInfoCard(
                        'Basic Information',
                        Icons.person,
                        Colors.blue[700]!,
                        [
                          _buildDetailRow('Name', _getSafeString(tenant['name'])),
                          _buildDetailRow('Email', _getSafeString(tenant['email'])),
                          _buildDetailRow('Phone', _getSafeString(tenant['phone'])),
                          _buildDetailRow('Tenancy ID', _getSafeString(tenant['tenancy_id'])),
                          _buildDetailRow('Joined', _formatDate(_getSafeString(tenant['created_at']))),
                          _buildDetailRow(
                            'Status',
                            _getSafeString(tenant['verified']) == 'true' ? 'Verified' : 'Unverified',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Rating Summary
                      if (_getSafeInt(tenant['total_ratings']) > 0) ...[
                        _buildInfoCard(
                          'Rating Summary',
                          Icons.star,
                          Colors.orange[700]!,
                          [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildRatingSummaryItem(
                                    'Overall Rating',
                                    _getSafeDouble(tenant['average_rating']).toStringAsFixed(1),
                                    Icons.star,
                                    _getRatingColor(tenant['average_rating']),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildRatingSummaryItem(
                                    'Total Ratings',
                                    _getSafeInt(tenant['total_ratings']).toString(),
                                    Icons.rate_review,
                                    Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Rating History
                      _buildInfoCard(
                        'Rating History (${ratings.length} ratings)',
                        Icons.trending_up,
                        Colors.green[700]!,
                        ratings.isEmpty
                            ? [
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text(
                                    'No ratings available',
                                    style: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]
                            : ratings.map<Widget>((rating) {
                          final ratingMap = rating as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              title: Text(
                                _getSafeString(ratingMap['property_address'], 'Property'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                _formatDate(_getSafeString(ratingMap['created_at'])),
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRatingColor(ratingMap['overall_rating']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${_getSafeDouble(ratingMap['overall_rating']).toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLandlordDetailsDialog(Map<String, dynamic> details) {
    final landlord = details['landlord'] ?? {};
    final properties = details['properties'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.greenAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Landlord Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(
                        'Basic Information',
                        Icons.person,
                        Colors.green[700]!,
                        [
                          _buildDetailRow('Name', _getSafeString(landlord['name'])),
                          _buildDetailRow('Email', _getSafeString(landlord['email'])),
                          _buildDetailRow('Phone', _getSafeString(landlord['phone'])),
                          _buildDetailRow('Address', _getSafeString(landlord['address'])),
                          _buildDetailRow('City', _getSafeString(landlord['city'])),
                          _buildDetailRow('Postal Code', _getSafeString(landlord['postal_code'])),
                          _buildDetailRow('Joined', _formatDate(_getSafeString(landlord['created_at']))),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildInfoCard(
                        'Properties (${properties.length})',
                        Icons.home,
                        Colors.blue[700]!,
                        properties.isEmpty
                            ? [
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(Icons.home_outlined, size: 48, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text(
                                    'No properties yet',
                                    style: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]
                            : properties.map<Widget>((property) {
                          final propertyMap = property as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 1,
                            child: ListTile(
                              leading: const Icon(Icons.home, size: 20),
                              title: Text(
                                _getSafeString(propertyMap['address']),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                _getSafeString(propertyMap['city']),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummaryItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Logout function
  void _logout() async {
    try {
      await UserPreferences.clearUser();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      _showSnackBar('Failed to logout: $e', Colors.red);
    }
  }

  // Helper methods
  String _getSafeString(dynamic value, [String defaultValue = 'N/A']) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  int _getSafeInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  double _getSafeDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Color _getRatingColor(dynamic rating) {
    final double ratingValue = _getSafeDouble(rating);
    if (ratingValue >= 4.0) return Colors.green;
    if (ratingValue >= 3.0) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString == 'N/A') return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color adminColor = Color(0xFF1976D2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: adminColor,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: '📊 Overview'),
            Tab(text: '👥 Tenants'),
            Tab(text: '🏢 Landlords'),
            Tab(text: '⏳ Pending'),
            Tab(text: '📈 Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading dashboard data...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      )
          : _errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error Loading Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadDashboardData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: adminColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTenantsTab(),
          _buildLandlordsTab(),
          _buildPendingTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  // Tab building methods
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard, size: 24),
              const SizedBox(width: 12),
              Text(
                'Dashboard Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              final aspectRatio = constraints.maxWidth > 600 ? 1.4 : 1.3;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: aspectRatio,
                children: [
                  _buildStatCard(
                    'Tenants',
                    _getSafeInt(_stats['totalTenants']).toString(),
                    Icons.people,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Landlords',
                    _getSafeInt(_stats['totalLandlords']).toString(),
                    Icons.business,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Pending',
                    (_pendingLandlords.length + _pendingProperties.length + _pendingTenants.length)
                        .toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Properties',
                    _getSafeInt(_stats['totalProperties']).toString(),
                    Icons.home,
                    Colors.purple,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Recent Activity
          Row(
            children: [
              const Icon(Icons.trending_up, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: (_pendingLandlords.isEmpty &&
                  _pendingProperties.isEmpty &&
                  _pendingTenants.isEmpty)
                  ? const Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                    SizedBox(height: 12),
                    Text(
                      'No pending requests',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'All caught up!',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pending tenants
                  if (_pendingTenants.isNotEmpty) ...[
                    Text(
                      'Pending Tenant Verifications (${_pendingTenants.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._pendingTenants.take(3).map((tenant) => _buildActivityItem(
                      'New tenant verification: ${_getSafeString(tenant['name'], 'Unknown')}',
                      'Documents uploaded for review',
                      Icons.person,
                      Colors.purple,
                    )),
                  ],
                  if (_pendingLandlords.isNotEmpty) ...[
                    if (_pendingTenants.isNotEmpty) const SizedBox(height: 16),
                    Text(
                      'Pending Landlord Approvals (${_pendingLandlords.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._pendingLandlords.take(3).map((landlord) => _buildActivityItem(
                      'New landlord: ${_getSafeString(landlord['name'], 'Unknown')}',
                      _getSafeString(landlord['email']),
                      Icons.business,
                      Colors.blue,
                    )),
                  ],
                  if (_pendingProperties.isNotEmpty) ...[
                    if (_pendingLandlords.isNotEmpty || _pendingTenants.isNotEmpty)
                      const SizedBox(height: 16),
                    Text(
                      'Pending Properties (${_pendingProperties.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._pendingProperties.take(3).map((property) => _buildActivityItem(
                      'New property: ${_getSafeString(property['address'], 'Unknown')}',
                      'by ${_getSafeString(property['landlord_name'], 'Unknown')}',
                      Icons.home,
                      Colors.green,
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'All Tenants',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  '${_allTenants.length} total',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _allTenants.isEmpty
              ? Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No tenants registered yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allTenants.length,
            itemBuilder: (context, index) {
              final tenant = _allTenants[index];
              final avgRating = _getSafeDouble(tenant['average_rating']);
              final totalRatings = _getSafeInt(tenant['total_ratings']);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    child: Text(
                      _getSafeString(tenant['name']).isNotEmpty
                          ? _getSafeString(tenant['name'])[0].toUpperCase()
                          : 'U',
                      style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    _getSafeString(tenant['name'], 'Unknown'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${_getSafeString(tenant['tenancy_id'])}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getSafeString(tenant['email']),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              totalRatings > 0
                                  ? '${avgRating.toStringAsFixed(1)} (${totalRatings} reviews)'
                                  : 'No ratings yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 16),
                  onTap: () => _viewTenantDetails(tenant),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLandlordsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.business, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'All Landlords',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  '${_allLandlords.length} approved',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _allLandlords.isEmpty
              ? Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No approved landlords yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allLandlords.length,
            itemBuilder: (context, index) {
              final landlord = _allLandlords[index];
              final totalProperties = _getSafeInt(landlord['total_properties']);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[50],
                    child: Text(
                      _getSafeString(landlord['name']).isNotEmpty
                          ? _getSafeString(landlord['name'])[0].toUpperCase()
                          : 'L',
                      style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    _getSafeString(landlord['name'], 'Unknown'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        _getSafeString(landlord['email']),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'City: ${_getSafeString(landlord['city'])}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.home, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            '$totalProperties properties',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 16),
                  onTap: () => _viewLandlordDetails(landlord),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Colors.blue[700],
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
              indicatorColor: Colors.blue,
              indicatorWeight: 3,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 6),
                      Text('Tenants (${_pendingTenants.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.business, size: 16),
                      const SizedBox(width: 6),
                      Text('Landlords (${_pendingLandlords.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.home, size: 16),
                      const SizedBox(width: 6),
                      Text('Properties (${_pendingProperties.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPendingTenantsTab(),
                _buildPendingLandlordsTab(),
                _buildPendingPropertiesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTenantsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pending Tenant Verifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _pendingTenants.isEmpty
              ? Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      'No pending tenant verifications',
                      style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'All tenants are verified!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pendingTenants.length,
            itemBuilder: (context, index) {
              final tenant = _pendingTenants[index];
              return _buildTenantVerificationCard(tenant);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTenantVerificationCard(Map<String, dynamic> tenant) {
    final tenantId = _getSafeInt(tenant['id']);
    if (tenantId == 0) return const SizedBox.shrink();

    // Count documents
    int documentCount = 0;
    for (int i = 1; i <= 4; i++) {
      if (_getSafeString(tenant['document${i}_url']).isNotEmpty) {
        documentCount++;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person, color: Colors.purple, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getSafeString(tenant['name'], 'Unknown'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getSafeString(tenant['email']),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: documentCount > 0 ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: documentCount > 0 ? Colors.green[200]! : Colors.red[200]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description,
                        size: 12,
                        color: documentCount > 0 ? Colors.green[700] : Colors.red[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$documentCount Docs',
                        style: TextStyle(
                          color: documentCount > 0 ? Colors.green[700] : Colors.red[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details
            _buildDetailItem('Phone', _getSafeString(tenant['phone'], 'Not provided')),
            _buildDetailItem('Tenancy ID', _getSafeString(tenant['tenancy_id'], 'Not assigned')),
            _buildDetailItem('Registration Date', _formatDate(_getSafeString(tenant['created_at']))),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showTenantDocumentDialog(tenant),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      side: BorderSide(color: Colors.blue[200]!),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Docs', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _handleTenantVerification(tenantId, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _handleTenantVerification(tenantId, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingLandlordsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pending Landlord Approvals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _pendingLandlords.isEmpty
              ? Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      'No pending landlord approvals',
                      style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'All landlords are approved!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pendingLandlords.length,
            itemBuilder: (context, index) {
              final landlord = _pendingLandlords[index];
              return _buildLandlordCard(landlord);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLandlordCard(Map<String, dynamic> landlord) {
    final landlordId = _getSafeInt(landlord['id']);
    if (landlordId == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getSafeString(landlord['name'], 'Unknown'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getSafeString(landlord['email']),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildDetailItem('Phone', _getSafeString(landlord['phone'], 'Not provided')),
            _buildDetailItem('Address', _getSafeString(landlord['address'], 'Not provided')),
            _buildDetailItem('City', _getSafeString(landlord['city'], 'Not provided')),
            _buildDetailItem('Registration Date', _formatDate(_getSafeString(landlord['created_at']))),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handleLandlordVerification(landlordId, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _handleLandlordVerification(landlordId, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPropertiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pending Property Requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _pendingProperties.isEmpty
              ? Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.home_outlined, size: 64, color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'No pending property requests',
                      style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'All properties are approved!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pendingProperties.length,
            itemBuilder: (context, index) {
              final property = _pendingProperties[index];
              return _buildPropertyCard(property);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    final propertyId = _getSafeInt(property['id']);
    if (propertyId == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.home, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getSafeString(property['address'], 'Unknown Address'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Requested by: ${_getSafeString(property['landlord_name'], 'Unknown')}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _buildDetailItem('City', _getSafeString(property['city'], 'Not provided')),
            _buildDetailItem('Postal Code', _getSafeString(property['postal_code'], 'Not provided')),
            _buildDetailItem('Request Date', _formatDate(_getSafeString(property['created_at']))),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handlePropertyRequest(propertyId, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _handlePropertyRequest(propertyId, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final totalUsers = _getSafeInt(_stats['totalTenants']) + _getSafeInt(_stats['totalLandlords']);
    final pendingRequests = _pendingLandlords.length + _pendingProperties.length + _pendingTenants.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, size: 24),
              const SizedBox(width: 12),
              Text(
                'System Analytics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Analytics cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              final aspectRatio = constraints.maxWidth > 600 ? 1.3 : 1.2;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: aspectRatio,
                children: [
                  _buildAnalyticsCard('Total Users', totalUsers, Icons.people, Colors.indigo),
                  _buildAnalyticsCard('Active Properties', _getSafeInt(_stats['totalProperties']), Icons.home, Colors.green),
                  _buildAnalyticsCard('Pending Requests', pendingRequests, Icons.pending, Colors.orange),
                  _buildAnalyticsCard('System Health', 100, Icons.check_circle, Colors.teal),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // System Status
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'System Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatusItem('Database', 'Connected', Colors.green),
                  _buildStatusItem('Server', 'Running', Colors.green),
                  _buildStatusItem('Email Service', 'Active', Colors.green),
                  _buildStatusItem('File Storage', 'Available', Colors.green),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  // Stat card
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Analytics card
  Widget _buildAnalyticsCard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// DocumentViewer class - integrated into the same file
class DocumentViewer extends StatefulWidget {
  final String documentUrl;
  final String documentName;
  final String? documentType;

  const DocumentViewer({
    super.key,
    required this.documentUrl,
    required this.documentName,
    this.documentType,
  });

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  late String _fileType;
  bool _isLoading = true;
  String? _errorMessage;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _determineFileType();
  }

  void _determineFileType() {
    if (widget.documentType != null && widget.documentType!.isNotEmpty) {
      _fileType = widget.documentType!.toUpperCase();
    } else {
      final extension = path.extension(widget.documentUrl).toLowerCase();
      _fileType = _getFileTypeFromExtension(extension);
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _getFileTypeFromExtension(String extension) {
    switch (extension) {
      case '.pdf':
        return 'PDF';
      case '.jpg':
      case '.jpeg':
        return 'JPEG';
      case '.png':
        return 'PNG';
      case '.gif':
        return 'GIF';
      case '.bmp':
        return 'BMP';
      case '.webp':
        return 'WEBP';
      case '.doc':
      case '.docx':
        return 'DOC';
      case '.xls':
      case '.xlsx':
        return 'XLS';
      case '.ppt':
      case '.pptx':
        return 'PPT';
      case '.txt':
        return 'TXT';
      case '.rtf':
        return 'RTF';
      default:
        return 'FILE';
    }
  }

  bool _isImageFile(String fileType) {
    return ['JPEG', 'JPG', 'PNG', 'GIF', 'BMP', 'WEBP'].contains(fileType);
  }

  bool _isPdfFile(String fileType) {
    return fileType == 'PDF';
  }

  Color _getFileColor(String fileType) {
    switch (fileType) {
      case 'PDF':
        return Colors.red;
      case 'JPEG':
      case 'JPG':
      case 'PNG':
      case 'GIF':
      case 'BMP':
      case 'WEBP':
        return Colors.blue;
      case 'DOC':
        return Colors.indigo;
      case 'XLS':
        return Colors.green;
      case 'PPT':
        return Colors.orange;
      case 'TXT':
      case 'RTF':
        return Colors.grey;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DOC':
        return Icons.description;
      case 'XLS':
        return Icons.table_chart;
      case 'PPT':
        return Icons.slideshow;
      case 'TXT':
      case 'RTF':
        return Icons.text_snippet;
      case 'JPEG':
      case 'JPG':
      case 'PNG':
      case 'GIF':
      case 'BMP':
      case 'WEBP':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _openExternally() async {
    try {
      final uri = Uri.parse(widget.documentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Cannot open this document type externally');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to open document: $e');
    }
  }

  Future<void> _downloadDocument() async {
    try {
      final uri = Uri.parse(widget.documentUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _showSuccessSnackBar('Download started');
    } catch (e) {
      _showErrorSnackBar('Failed to download document');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.documentName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: _getFileColor(_fileType),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _openExternally,
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open in External App',
          ),
          IconButton(
            onPressed: _downloadDocument,
            icon: const Icon(Icons.download),
            tooltip: 'Download',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildDocumentView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Document',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _openExternally,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getFileColor(_fileType),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open External'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentView() {
    if (_isPdfFile(_fileType)) {
      return _buildPdfViewer();
    } else if (_isImageFile(_fileType)) {
      return _buildImageViewer();
    } else {
      return _buildUnsupportedFileView();
    }
  }

  Widget _buildPdfViewer() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SfPdfViewer.network(
            widget.documentUrl,
            key: _pdfViewerKey,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            enableDoubleTapZooming: true,
            enableTextSelection: true,
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              setState(() {
                _errorMessage = 'Failed to load PDF: ${details.error}';
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.documentUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    padding: const EdgeInsets.all(64),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Loading image...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(64),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openExternally,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open External'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnsupportedFileView() {
    final color = _getFileColor(_fileType);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Icon(
                    _getFileIcon(_fileType),
                    size: 64,
                    color: color,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '$_fileType Document',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.documentName,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'This document type cannot be previewed internally.\nUse external app to view the document.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _openExternally,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open External App'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _downloadDocument,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
