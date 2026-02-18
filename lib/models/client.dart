class Client {
  final String id;
  final String name;
  final String address;
  final String phone;

  /// Optional legacy field (no longer required for MVP).
  final String? locationLink;

  final String? invoiceDetails;

  const Client({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.locationLink,
    this.invoiceDetails,
  });

  Client copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? locationLink,
    String? invoiceDetails,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      locationLink: locationLink ?? this.locationLink,
      invoiceDetails: invoiceDetails ?? this.invoiceDetails,
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
    };
  }

  static Client fromMap(Map data) {
    return Client(
      id: (data['id'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      address: (data['address'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      locationLink: data['locationLink'] as String?,
      invoiceDetails: data['invoiceDetails'] as String?,
    );
  }
}
