import 'package:flutter/material.dart';

class PropertiesOpp extends StatelessWidget {
  const PropertiesOpp({super.key});

  void _showScoreTenantDialog(BuildContext context) {
    TextEditingController idController = TextEditingController();
    TextEditingController scoreController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Score Tenant", style: TextStyle(color: Color(0xFF5B4FD5))),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: idController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.perm_identity),
                    hintText: "Tenant ID",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: scoreController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.star),
                    hintText: "Score (1-5)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B4FD5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Save score logic can be added here
              },
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showPropertyHistory(BuildContext context) {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Property History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5B4FD5))),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Icon(Icons.location_on, color: Color(0xFF5B4FD5)),
                  SizedBox(width: 5),
                  Text("123 Main Street, Toronto, ON", style: TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 15),
              _historyCard("John Smith", "TEN-ABC12345", "Jun 1, 2023 - Present", 5, 4, 5, 4, true, 5, "5/5"),
              const SizedBox(height: 10),
              _historyCard("Lisa Chen", "TEN-LIS456", "Jan 1, 2022 - May 31, 2023", 5, 4, 5, 4, true, 5, "4/5"),
            ],
          ),
        );
      },
    );
  }

  static Widget _historyCard(String name, String id, String period, int rent, int comm, int care, int util, bool respect, int handover, String avgScore) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Color(0xFF5B4FD5).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF5B4FD5)),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(avgScore, style: const TextStyle(color: Color(0xFF5B4FD5))),
            ],
          ),
          const SizedBox(height: 5),
          Text("ID: $id"),
          Text(period),
          const SizedBox(height: 5),
          Wrap(
            spacing: 10,
            runSpacing: 5,
            children: [
              _scoreItem("Rent Payment", rent),
              _scoreItem("Communication", comm),
              _scoreItem("Property Care", care),
              _scoreItem("Utilities", util),
              _yesNoItem("Respect Others", respect),
              _scoreItem("Property Handover", handover),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _scoreItem(String title, int score) {
    return Chip(
      label: Text("$title: $score/5", style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFF5B4FD5))),
    );
  }

  static Widget _yesNoItem(String title, bool yes) {
    return Chip(
      label: Text("$title: ${yes ? 'YES' : 'NO'}", style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFF5B4FD5))),
    );
  }

  Widget _propertyCard(BuildContext context, String address, String type, String tenant, String tenantId, String score) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF5B4FD5).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on, color: Color(0xFF5B4FD5)),
              SizedBox(width: 5),
            ],
          ),
          Text(address, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Text(type),
          const SizedBox(height: 5),
          Text("Current tenant: $tenant ($tenantId)"),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text("Average Score: $score", style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF5B4FD5),
                    side: const BorderSide(color: Color(0xFF5B4FD5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.history),
                  label: const Text("View History"),
                  onPressed: () => _showPropertyHistory(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5B4FD5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.star),
                  label: const Text("Score Tenant"),
                  onPressed: () => _showScoreTenantDialog(context),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B4FD5),
        title: const Text("My Properties", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _propertyCard(context, "123 Main Street, Toronto, ON", "2BR Downtown Condo", "John Smith", "TEN-ABC12345", "5/5"),
            _propertyCard(context, "789 Pine Street, Calgary, AB", "1BR Modern Apartment", "Emma Wilson", "TEN-NEW123", "5/5"),
            _propertyCard(context, "321 Elm Drive, Montreal, QC", "2BR Heritage Building", "N/A", "TEN-N/A", "N/A"),
          ],
        ),
      ),
    );
  }
}
