import 'package:flutter/material.dart';

class SearchTenant extends StatelessWidget {
  const SearchTenant({super.key});

  @override
  Widget build(BuildContext context) {
    // Example tenant list
    final tenants = [
      {'id': 'TNE-684023', 'name': 'joseff', 'email': 'josef@gmail.com'},
      {'id': 'TNE-684024', 'name': 'alice', 'email': 'alice@gmail.com'},
      {'id': 'TNE-684025', 'name': 'mark', 'email': 'mark@gmail.com'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top search area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            decoration: const BoxDecoration(
              color: Color(0xFF5B4FD5),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF9F95EC), // Slightly lighter purple
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  hintText: "Search tenet with ID",
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tenant cards list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: tenants.length,
              itemBuilder: (context, index) {
                final tenant = tenants[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B4FD5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Avatar or placeholder icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person, color: Color(0xFF5B4FD5)),
                      ),
                      const SizedBox(width: 15),
                      // Tenant details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenant['id']!,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              tenant['name']!,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              tenant['email']!,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
