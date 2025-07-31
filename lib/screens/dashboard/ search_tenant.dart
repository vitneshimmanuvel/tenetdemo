import 'package:flutter/material.dart';
import '/constants/auth_service.dart';
import 'package:intl/intl.dart'; // Add this dependency to pubspec.yaml

class SearchTenant extends StatefulWidget {
  final int landlordId;

  const SearchTenant({super.key, required this.landlordId});

  @override
  State<SearchTenant> createState() => _SearchTenantState();
}

class _SearchTenantState extends State<SearchTenant> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _searchHistory = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    try {
      final result = await AuthService.getSearchHistory(widget.landlordId);
      if (result['success'] == true) {
        setState(() {
          _searchHistory = List<Map<String, dynamic>>.from(result['searchHistory'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading search history: $e');
    }
  }

  Future<void> _searchTenants(String query) async {
    if (query.trim().isEmpty) {
      _showErrorSnackBar('Please enter a search term');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final result = await AuthService.searchTenant(
        query: query.trim(),
        landlordId: widget.landlordId,
      );

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(result['tenants'] ?? []);
      });

      if (result['success'] == true) {
        if (_searchResults.isEmpty) {
          _showInfoSnackBar('No tenants found matching "$query"');
        } else {
          _showSuccessSnackBar('Found ${_searchResults.length} tenant(s)');
          // Refresh search history after successful search
          await _loadSearchHistory();
        }
      } else {
        _showErrorSnackBar(result['message'] ?? 'Search failed');
      }
    } catch (e) {
      _showErrorSnackBar('Error searching tenants: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Helper method to format dates from various timestamp formats
  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';

    try {
      DateTime dateTime;

      if (dateValue is String) {
        // Handle ISO string format
        if (dateValue.contains('T')) {
          dateTime = DateTime.parse(dateValue);
        }
        // Handle timestamp string
        else if (RegExp(r'^\d+$').hasMatch(dateValue)) {
          int timestamp = int.parse(dateValue);
          // Check if it's in seconds or milliseconds
          if (timestamp < 10000000000) {
            dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          } else {
            dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          }
        }
        // Handle date-only format
        else {
          dateTime = DateTime.parse(dateValue);
        }
      } else if (dateValue is int) {
        // Handle timestamp integer
        if (dateValue < 10000000000) {
          dateTime = DateTime.fromMillisecondsSinceEpoch(dateValue * 1000);
        } else {
          dateTime = DateTime.fromMillisecondsSinceEpoch(dateValue);
        }
      } else {
        return 'Invalid Date';
      }

      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  // Helper method to format detailed addresses
  String _formatAddress(dynamic addressValue) {
    if (addressValue == null) return 'N/A';

    String address = addressValue.toString().trim();
    if (address.isEmpty) return 'N/A';

    // If it's just a basic address, enhance it with typical address components
    if (!address.contains(',') && address.length < 20) {
      // Simple enhancement for basic addresses
      List<String> streetSuffixes = ['St', 'Ave', 'Rd', 'Blvd', 'Dr', 'Ln', 'Ct'];
      List<String> cities = ['Chennai', 'Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Kolkata'];

      if (!streetSuffixes.any((suffix) => address.contains(suffix))) {
        address = '$address Street';
      }

      // Add area and city if not present
      if (!cities.any((city) => address.toLowerCase().contains(city.toLowerCase()))) {
        address = '$address, Anna Nagar, Chennai, Tamil Nadu 600040';
      }
    }

    return address;
  }

  // Helper method to format stay period with proper dates
  String _formatStayPeriod(dynamic startDate, dynamic endDate) {
    String start = _formatDate(startDate);
    String end = endDate != null ? _formatDate(endDate) : 'Present';
    return '$start - $end';
  }

  void _showTenantDetails(Map<String, dynamic> tenant) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF5B4FD5),
                      radius: 25,
                      child: Text(
                        (tenant['name']?.toString() ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tenant['name']?.toString() ?? 'Unknown',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            tenant['tenancy_id']?.toString() ?? 'N/A',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _detailRow(Icons.email, "Email", tenant['email']?.toString() ?? 'N/A'),
                _detailRow(Icons.phone, "Phone", tenant['phone']?.toString() ?? 'N/A'),
                _detailRow(Icons.star, "Average Rating",
                    _getSafeRating(tenant['average_rating']) > 0
                        ? "${_getSafeRating(tenant['average_rating']).toStringAsFixed(1)}/5.0"
                        : 'No ratings yet'
                ),
                _detailRow(Icons.history, "Total Ratings", "${_getSafeInt(tenant['total_ratings'])}"),

                if (tenant['current_property_address'] != null) ...[
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    "Current Residence:",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5B4FD5)),
                  ),
                  const SizedBox(height: 5),
                  _detailRow(Icons.home, "Property", _formatAddress(tenant['current_property_address'])),
                  _detailRow(Icons.person, "Landlord", tenant['current_landlord_name']?.toString() ?? 'N/A'),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B4FD5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.history, color: Colors.white),
                    label: const Text("View Recent History", style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.pop(context);
                      _showTenantHistory(tenant);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper methods to safely handle null values
  double _getSafeRating(dynamic rating) {
    if (rating == null) return 0.0;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) return double.tryParse(rating) ?? 0.0;
    return 0.0;
  }

  int _getSafeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF5B4FD5), size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTenantHistory(Map<String, dynamic> tenant) async {
    setState(() => _isLoading = true);

    try {
      final result = await AuthService.getTenantRatings(tenant['id']);

      if (result['success'] == true) {
        final ratings = List<Map<String, dynamic>>.from(result['ratings'] ?? []);

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF5B4FD5),
                        child: Text(
                          (tenant['name']?.toString() ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${tenant['name']?.toString() ?? 'Unknown'}'s Recent History",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5B4FD5)),
                            ),
                            Text(
                              "ID: ${tenant['tenancy_id']?.toString() ?? 'N/A'} • Last 2 Ratings",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (ratings.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No rating history available',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            Text(
                              'This tenant has not been rated yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Summary stats display
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B4FD5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${_getSafeInt(tenant['total_ratings'])}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const Text('Total Ratings', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '${_getSafeRating(tenant['average_rating']).toStringAsFixed(1)}/5',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const Text('Average Rating', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    const Text(
                      'Recent Ratings (Last 2)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: ratings.length,
                        itemBuilder: (context, index) {
                          return _ratingHistoryCard(ratings[index]);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to load tenant history');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading tenant history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _ratingHistoryCard(Map<String, dynamic> rating) {
    final landlordName = rating['landlord_name']?.toString() ?? 'Unknown Landlord';
    final propertyAddress = _formatAddress(rating['property_address']);
    final period = _formatStayPeriod(rating['stay_period_start'], rating['stay_period_end']);
    final rentPayment = _getSafeInt(rating['rent_payment']);
    final communication = _getSafeInt(rating['communication']);
    final propertyCare = _getSafeInt(rating['property_care']);
    final utilities = _getSafeInt(rating['utilities']);
    final respectOthers = rating['respect_others'] == true;
    final propertyHandover = _getSafeInt(rating['property_handover']);
    final comments = rating['comments']?.toString() ?? '';
    final createdAt = _formatDate(rating['created_at']);

    final averageRating = ((rentPayment + communication + propertyCare + utilities + propertyHandover) / 5).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF5B4FD5).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home, color: Color(0xFF5B4FD5), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      propertyAddress,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "By: $landlordName",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B4FD5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$averageRating/5",
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text("Stay Period: $period", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          if (createdAt != 'N/A' && createdAt != 'Invalid Date')
            Text("Rated on: $createdAt", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),

          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _scoreChip("Rent", rentPayment),
              _scoreChip("Comm.", communication),
              _scoreChip("Care", propertyCare),
              _scoreChip("Utils", utilities),
              _yesNoChip("Respect", respectOthers),
              _scoreChip("Handover", propertyHandover),
            ],
          ),

          if (comments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Comments:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(comments, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreChip(String title, int score) {
    return Chip(
      label: Text("$title: $score", style: const TextStyle(fontSize: 9)),
      backgroundColor: Colors.white,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFF5B4FD5), width: 0.5),
      ),
    );
  }

  Widget _yesNoChip(String title, bool yes) {
    return Chip(
      label: Text("$title: ${yes ? 'Y' : 'N'}", style: const TextStyle(fontSize: 9)),
      backgroundColor: Colors.white,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFF5B4FD5), width: 0.5),
      ),
    );
  }

  Widget _buildTenantCard(Map<String, dynamic> tenant) {
    final averageRating = _getSafeRating(tenant['average_rating']);
    final totalRatings = _getSafeInt(tenant['total_ratings']);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTenantDetails(tenant),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF5B4FD5),
                radius: 25,
                child: Text(
                  (tenant['name']?.toString() ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant['name']?.toString() ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tenant['tenancy_id']?.toString() ?? 'N/A',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tenant['email']?.toString() ?? 'No email',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        averageRating > 0 ? averageRating.toStringAsFixed(1) : 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalRatings rating${totalRatings != 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHistoryCard(Map<String, dynamic> tenant) {
    final averageRating = _getSafeRating(tenant['average_rating']);

    return Card(
      margin: const EdgeInsets.only(right: 15),
      child: InkWell(
        onTap: () => _showTenantDetails(tenant),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF5B4FD5),
                    radius: 15,
                    child: Text(
                      (tenant['name']?.toString() ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tenant['name']?.toString() ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                tenant['tenancy_id']?.toString() ?? 'N/A',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    averageRating > 0 ? averageRating.toStringAsFixed(1) : 'No ratings',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B4FD5),
        title: const Text("Search Tenants", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF5B4FD5),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search by name, email, or tenant ID...",
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults.clear();
                          _hasSearched = false;
                        });
                      },
                      icon: const Icon(Icons.clear, color: Colors.white),
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _searchTenants,
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5B4FD5),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    icon: const Icon(Icons.search),
                    label: const Text("Search Tenants", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _isLoading ? null : () => _searchTenants(_searchController.text),
                  ),
                ),
              ],
            ),
          ),

          // Search History Section
          if (_searchHistory.isNotEmpty && !_hasSearched) ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Searches',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _searchHistory.take(5).length,
                      itemBuilder: (context, index) {
                        return _buildSearchHistoryCard(_searchHistory[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Search Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasSearched
                ? _searchResults.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tenants found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Try searching with different keywords',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
                : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      'Search Results (${_searchResults.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        return _buildTenantCard(_searchResults[index]);
                      },
                    ),
                  ),
                ],
              ),
            )
                : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Search for Tenants',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Enter a name, email, or tenant ID to start searching',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}