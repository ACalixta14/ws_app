import '../models/service_order.dart';

class SupabaseOrderMaps {
  Map<String, dynamic> toMap(ServiceOrder o) {
    return {
      'id': o.id,
      'client_id': o.clientId,
      'driver_id': o.driverId,
      'scheduled_at': o.scheduledAt.toIso8601String(),
      'service_type': o.serviceType.name,
      'payment_method': o.paymentMethod.name,
      'status': o.status.name,
      'price': o.price,
      'service_address': o.serviceAddress,
      'additional_stops': o.additionalStops,
      'phone_snapshot': o.phoneSnapshot,
      'notes': o.notes,
      'disposal_note': o.disposalNote,
      'created_at': o.createdAt.toIso8601String(),
      'updated_at': o.updatedAt.toIso8601String(),
      'job_stage': o.jobStage.name,
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
      'serviceAddress': row['service_address'],
      'additionalStops':
          (row['additional_stops'] as List?)?.cast<String>() ?? const [],
      'phoneSnapshot': row['phone_snapshot'],
      'notes': row['notes'],
      'status': row['status'],
      'jobStage': row['job_stage'],
      'disposalNote': row['disposal_note'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    };
  }
}