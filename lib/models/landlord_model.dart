
class Landlord {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;

  Landlord({required this.id, required this.name, required this.email, required this.phone, required this.address});

  factory Landlord.fromJson(Map<String, dynamic> json) {
    return Landlord(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
    );
  }
}
