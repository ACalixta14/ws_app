import '../models/service_order.dart';

class SupabaseOrderMaps {
  static Map<String, dynamic> orderToRow(ServiceOrder o) {
    return {
      'id': o.id,
      'client_id': o.clientId,
      'driver_id': o.driverId,
      'scheduled_at': o.scheduledAt.toUtc().toIso8601String(),
      'service_type': o.serviceType.name,
      'payment_method': o.paymentMethod.name,
      'price': o.price,
      'address_snapshot': o.addressSnapshot,
      'phone_snapshot': o.phoneSnapshot,
      'notes': o.notes,
      'status': o.status.name,
      'disposal_note': o.disposalNote,
      'created_at': o.createdAt.toUtc().toIso8601String(),
      'updated_at': o.updatedAt.toUtc().toIso8601String(),
    };
  }

  static Map<String, dynamic> rowToOrderMap(Map row) {
    return {
      'id': row['id'],
      'clientId': row['client_id'],
      'driverId': row['driver_id'],
      'scheduledAt': row['scheduled_at'],
      'serviceType': row['service_type'],
      'paymentMethod': row['payment_method'],
      'price': row['price'],
      'addressSnapshot': row['address_snapshot'],
      'phoneSnapshot': row['phone_snapshot'],
      'notes': row['notes'],
      'status': row['status'],
      'disposalNote': row['disposal_note'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    };
  }
}