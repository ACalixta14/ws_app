class Client {
  final String id;
  final String name;
  final String address;
  final String phone;

  /// Optional legacy field (no longer required for MVP).
  final String? locationLink;

  final String? invoiceDetails;

  // ✅ novos campos para sync LWW
  final DateTime createdAt;
  final DateTime updatedAt;

  const Client({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.locationLink,
    this.invoiceDetails,
    required this.createdAt,
    required this.updatedAt,
  });

  Client copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? locationLink,
    String? invoiceDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      locationLink: locationLink ?? this.locationLink,
      invoiceDetails: invoiceDetails ?? this.invoiceDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'locationLink': locationLink,
      'invoiceDetails': invoiceDetails,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static Client fromMap(Map data) {
    final now = DateTime.now();

    return Client(
      id: (data['id'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      address: (data['address'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      locationLink: data['locationLink'] as String?,
      invoiceDetails: data['invoiceDetails'] as String?,
      createdAt: data['createdAt'] == null ? now : DateTime.parse(data['createdAt'] as String),
      updatedAt: data['updatedAt'] == null ? now : DateTime.parse(data['updatedAt'] as String),
    );
  }
}