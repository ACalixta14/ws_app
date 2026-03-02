import '../models/client.dart';

class SupabaseClientMaps {
  static Map<String, dynamic> clientToRow(Client c) {
    return {
      'id': c.id,
      'name': c.name,
      'address': c.address,
      'phone': c.phone,
      'invoice_details': c.invoiceDetails,
      'location_link': c.locationLink,
      'created_at': c.createdAt.toUtc().toIso8601String(),
      'updated_at': c.updatedAt.toUtc().toIso8601String(),
    };
  }

  static Map<String, dynamic> rowToClientMap(Map row) {
    return {
      'id': row['id'],
      'name': row['name'],
      'address': row['address'],
      'phone': row['phone'],
      'invoiceDetails': row['invoice_details'],
      'locationLink': row['location_link'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    };
  }
}