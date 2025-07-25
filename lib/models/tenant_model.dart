class Tenant {
  final String id;
  final String name;
  final String email;
  final String phone;

  Tenant({required this.id, required this.name, required this.email, required this.phone});

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}
