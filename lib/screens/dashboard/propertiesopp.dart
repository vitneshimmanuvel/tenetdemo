import 'package:flutter/material.dart';
import '/constants/auth_service.dart';

// Rate Tenant Dialog with corrected implementation
class RateTenantDialog extends StatefulWidget {
  final Map<String, dynamic> property;
  final int landlordId;
  final VoidCallback onRatingSubmitted;

  const RateTenantDialog({
    super.key,
    required this.property,
    required this.landlordId,
    required this.onRatingSubmitted,
  });

  @override
  State<RateTenantDialog> createState() => _RateTenantDialogState();
}

class _RateTenantDialogState extends State<RateTenantDialog> {
  final TextEditingController _tenantSearchController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  Map<String, dynamic>? _selectedTenant;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isSubmitting = false;

  // Rating values (1-5 stars)
  int _rentPaymentRating = 0;
  int _communicationRating = 0;
  int _propertyMaintenanceRating = 0;
  int _utilitiesRating = 0;
  int _propertyHandoverRating = 0;

  // Respect others (Yes/No/NA)
  String _respectOthers = 'NA';

  DateTime? _stayStartDate;
  DateTime? _stayEndDate;

  // Safe conversion helpers
  int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _safeToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill with current tenant if available
    if (widget.property['current_tenant_id'] != null) {
      _selectedTenant = {
        'id': _safeToInt(widget.property['current_tenant_id']),
        'name': _safeToString(widget.property['current_tenant_name']),
        'tenancy_id': _safeToString(widget.property['current_tenant_tenancy_id']),
      };
      _tenantSearchController.text = '${_selectedTenant!['name']} (${_selectedTenant!['tenancy_id']})';
    }
  }

  @override
  void dispose() {
    _tenantSearchController.dispose();
    _commentsController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _searchTenants(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final result = await AuthService.searchTenant(
        query: query,
        landlordId: widget.landlordId,
      );

      if (result['success'] == true) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(result['tenants'] ?? []);
        });
      }
    } catch (e) {
      print('Search error: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_stayStartDate ?? DateTime.now().subtract(const Duration(days: 365)))
          : (_stayEndDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5B4FD5),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _stayStartDate = picked;
          _startDateController.text = _formatDate(picked);
          // Clear end date if it's before start date
          if (_stayEndDate != null && _stayEndDate!.isBefore(picked)) {
            _stayEndDate = null;
            _endDateController.clear();
          }
        } else {
          // Validate that end date is after start date
          if (_stayStartDate != null && picked.isBefore(_stayStartDate!)) {
            _showErrorDialog('End date must be after start date');
            return;
          }
          _stayEndDate = picked;
          _endDateController.text = _formatDate(picked);
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _validateForm() {
    if (_selectedTenant == null) {
      _showErrorDialog('Please select a tenant');
      return false;
    }

    if (_stayStartDate == null) {
      _showErrorDialog('Please select stay start date');
      return false;
    }

    if (_rentPaymentRating == 0 || _communicationRating == 0 ||
        _propertyMaintenanceRating == 0 || _utilitiesRating == 0 ||
        _propertyHandoverRating == 0) {
      _showErrorDialog('Please rate all criteria (1-5 stars)');
      return false;
    }

    return true;
  }

  Future<void> _submitRating() async {
    if (!_validateForm()) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await AuthService.rateTenant(
        tenantId: _safeToInt(_selectedTenant!['id']),
        landlordId: widget.landlordId,
        propertyId: _safeToInt(widget.property['id']),
        rentPayment: _rentPaymentRating,
        communication: _communicationRating,
        propertyCare: _propertyMaintenanceRating,
        utilities: _utilitiesRating,
        respectOthers: _respectOthers == 'Yes', // Convert directly to boolean
        propertyHandover: _propertyHandoverRating,
        comments: _commentsController.text.trim(),
        stayPeriodStart: _stayStartDate!.toIso8601String().split('T')[0],
        stayPeriodEnd: _stayEndDate?.toIso8601String().split('T')[0],
      );

      // Rest of the method remains the same...
      if (result['success'] == true) {
        Navigator.pop(context);
        widget.onRatingSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_safeToString(result['message']).isEmpty
                ? 'Rating submitted successfully'
                : _safeToString(result['message'])),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorDialog(_safeToString(result['message']).isEmpty
            ? 'Failed to submit rating'
            : _safeToString(result['message']));
      }
    } catch (e) {
      _showErrorDialog('Network error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF5B4FD5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.rate_review, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Rate Tenant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                  children: [
                    // Property Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.home, color: Color(0xFF5B4FD5)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _safeToString(widget.property['address']).isEmpty
                                  ? 'Property'
                                  : _safeToString(widget.property['address']),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tenant Search
                    const Text(
                      'Select Tenant *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tenantSearchController,
                      decoration: InputDecoration(
                        hintText: 'Type tenant name or ID to search...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearching
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (value) {
                        if (value != _selectedTenant?['name']?.toString()) {
                          _selectedTenant = null;
                          _searchTenants(value);
                        }
                      },
                    ),

                    // Search Results
                    if (_searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: _searchResults.take(5).map((tenant) {
                            return ListTile(
                              dense: true,
                              leading: const CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(0xFF5B4FD5),
                                child: Icon(Icons.person, color: Colors.white, size: 16),
                              ),
                              title: Text(_safeToString(tenant['name']).isEmpty
                                  ? 'Unknown'
                                  : _safeToString(tenant['name'])),
                              subtitle: Text('ID: ${_safeToString(tenant['tenancy_id']).isEmpty
                                  ? 'N/A'
                                  : _safeToString(tenant['tenancy_id'])}'),
                              trailing: tenant['average_rating'] != null
                                  ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  Text(
                                    _safeToDouble(tenant['average_rating']).toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              )
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedTenant = tenant;
                                  _tenantSearchController.text = '${_safeToString(tenant['name'])} (${_safeToString(tenant['tenancy_id'])})';
                                  _searchResults = [];
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Stay Period
                    const Text(
                      'Stay Period *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _startDateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Start Date',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            onTap: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _endDateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'End Date (Optional)',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            onTap: () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Rating Criteria
                    const Text(
                      'Rating Criteria *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),

                    _buildStarRating('Rent On-time Payment', _rentPaymentRating, (rating) {
                      setState(() => _rentPaymentRating = rating);
                    }),

                    _buildStarRating('Communication Standard', _communicationRating, (rating) {
                      setState(() => _communicationRating = rating);
                    }),

                    _buildStarRating('Property Maintenance', _propertyMaintenanceRating, (rating) {
                      setState(() => _propertyMaintenanceRating = rating);
                    }),

                    _buildStarRating('Utilities Care', _utilitiesRating, (rating) {
                      setState(() => _utilitiesRating = rating);
                    }),

                    _buildStarRating('Property Handover', _propertyHandoverRating, (rating) {
                      setState(() => _propertyHandoverRating = rating);
                    }),

                    // Respect Others (Yes/No/NA)
                    const SizedBox(height: 12),
                    const Text(
                      'Respect Other Tenants',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            dense: true,
                            title: const Text('Yes'),
                            value: 'Yes',
                            groupValue: _respectOthers,
                            onChanged: (value) => setState(() => _respectOthers = value!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            dense: true,
                            title: const Text('No'),
                            value: 'No',
                            groupValue: _respectOthers,
                            onChanged: (value) => setState(() => _respectOthers = value!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            dense: true,
                            title: const Text('N/A'),
                            value: 'NA',
                            groupValue: _respectOthers,
                            onChanged: (value) => setState(() => _respectOthers = value!),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Comments
                    const Text(
                      'Additional Comments',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _commentsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share your experience with this tenant...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B4FD5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text('Submit Rating'),
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

  Widget _buildStarRating(String title, int currentRating, Function(int) onRatingChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => onRatingChanged(index + 1),
                icon: Icon(
                  index < currentRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 28,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// Properties Opp Widget
class PropertiesOpp extends StatefulWidget {
  final List<Map<String, dynamic>> properties;
  final int landlordId;

  const PropertiesOpp({
    super.key,
    required this.properties,
    required this.landlordId,
  });

  @override
  State<PropertiesOpp> createState() => _PropertiesOppState();
}

class _PropertiesOppState extends State<PropertiesOpp> {
  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _properties = List.from(widget.properties);
  }

  // Safe conversion helpers
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _safeToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  Future<void> _refreshProperties() async {
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.getLandlordProperties(widget.landlordId);
      if (result['success'] == true) {
        setState(() {
          _properties = List<Map<String, dynamic>>.from(result['properties'] ?? []);
        });
      }
    } catch (e) {
      print('Error refreshing properties: $e');
      _showErrorSnackBar('Failed to refresh properties: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showRateTenantDialog(Map<String, dynamic> property) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return RateTenantDialog(
          property: property,
          landlordId: widget.landlordId,
          onRatingSubmitted: () {
            _refreshProperties();
          },
        );
      },
    );
  }

  void _showPropertyHistoryDialog(Map<String, dynamic> property) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PropertyHistoryDialog(propertyId: _safeToInt(property['id']));
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.orange; // Changed: rejected now shows as orange (pending color)
      default:
        return Colors.grey;
    }
  }

  // UPDATED: This is the key change - rejected properties now show as "Pending"
  String _getStatusText(dynamic approved) {
    if (approved == null) return 'Pending';
    if (approved is bool) {
      return approved ? 'Approved' : 'Pending'; // Changed: false now returns 'Pending' instead of 'Rejected'
    }
    // Handle string/number values
    final String approvedStr = approved.toString().toLowerCase();
    if (approvedStr == 'true' || approvedStr == '1') return 'Approved';
    if (approvedStr == 'false' || approvedStr == '0') return 'Pending'; // Changed: rejected shows as 'Pending'
    return 'Pending';
  }

  // UPDATED: Status check now only considers truly approved properties
  bool _isPropertyApproved(dynamic approved) {
    if (approved == null) return false;
    if (approved is bool) return approved;
    final String approvedStr = approved.toString().toLowerCase();
    return (approvedStr == 'true' || approvedStr == '1');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Properties', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF5B4FD5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProperties,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _properties.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No properties found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Add your first property from the dashboard',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshProperties,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _properties.length,
          itemBuilder: (context, index) {
            final property = _properties[index];
            final statusText = _getStatusText(property['approved']);
            final isApproved = _isPropertyApproved(property['approved']); // Use updated method
            final hasCurrentTenant = property['current_tenant_id'] != null;

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _safeToString(property['address']).isEmpty
                                ? 'No Address'
                                : _safeToString(property['address']),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5B4FD5),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(statusText),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Property Details
                    if (_safeToString(property['street']).isNotEmpty)
                      Text(
                        _safeToString(property['street']),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    Text(
                      '${_safeToString(property['city'])}, ${_safeToString(property['postal_code'])}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    // Current Tenant Info
                    if (hasCurrentTenant) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Tenant',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _safeToString(property['current_tenant_name']).isEmpty
                                        ? 'Unknown'
                                        : _safeToString(property['current_tenant_name']),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (property['current_tenant_tenancy_id'] != null)
                                    Text(
                                      'ID: ${_safeToString(property['current_tenant_tenancy_id'])}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Property Stats
                    Row(
                      children: [

                        Expanded(
                          child: _buildStatItem(
                            'Created',
                            _formatDate(property['created_at']),
                            Icons.calendar_today,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showPropertyHistoryDialog(property),
                            icon: const Icon(Icons.history, size: 18),
                            label: const Text('History'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.grey.shade700,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isApproved
                                ? () => _showRateTenantDialog(property)
                                : null,
                            icon: const Icon(Icons.rate_review, size: 18),
                            label: const Text('Rate Tenant'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B4FD5),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}

// Property History Dialog
class PropertyHistoryDialog extends StatefulWidget {
  final int propertyId;

  const PropertyHistoryDialog({
    super.key,
    required this.propertyId,
  });

  @override
  State<PropertyHistoryDialog> createState() => _PropertyHistoryDialogState();
}

class _PropertyHistoryDialogState extends State<PropertyHistoryDialog> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final result = await AuthService.getPropertyHistory(widget.propertyId);
      if (result['success'] == true) {
        setState(() {
          _history = List<Map<String, dynamic>>.from(result['history'] ?? []);
        });
      } else {
        print('Failed to load history: ${result['message']}');
      }
    } catch (e) {
      print('Error loading history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Safe conversion helpers
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _safeToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF5B4FD5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Property History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _history.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No history available',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final record = _history[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: Color(0xFF5B4FD5),
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _safeToString(record['tenant_name']).isEmpty
                                          ? 'Unknown Tenant'
                                          : _safeToString(record['tenant_name']),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'ID: ${_safeToString(record['tenant_tenancy_id']).isEmpty ? 'N/A' : _safeToString(record['tenant_tenancy_id'])}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: record['is_current'] == true
                                      ? Colors.green
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  record['is_current'] == true ? 'Current' : 'Past',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Stay Period
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Stay: ${_formatHistoryDate(record['start_date'])} - ${record['end_date'] != null ? _formatHistoryDate(record['end_date']) : 'Present'}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Rating Summary
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                'Overall: ${record['overall_rating'] != null ? _safeToDouble(record['overall_rating']).toStringAsFixed(1) : 'Not rated'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          // Rating Details
                          if (record['overall_rating'] != null) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _buildRatingChip('Rent', record['rent_payment']),
                                _buildRatingChip('Communication', record['communication']),
                                _buildRatingChip('Property Care', record['property_care']),
                                _buildRatingChip('Utilities', record['utilities']),
                                _buildRatingChip('Handover', record['property_handover']),
                              ],
                            ),

                            // Respect Others
                            if (record['respect_others'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    record['respect_others'] == true
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 16,
                                    color: record['respect_others'] == true
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Respects Others: ${record['respect_others'] == true ? 'Yes' : 'No'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],

                            // Comments
                            if (_safeToString(record['comments']).isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.comment,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _safeToString(record['comments']),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingChip(String label, dynamic rating) {
    if (rating == null) return const SizedBox.shrink();

    final int ratingValue = _safeToInt(rating);
    if (ratingValue == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getRatingColor(ratingValue),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $ratingValue/5',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }

  String _formatHistoryDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}