import 'payment_method.dart';
import 'service_type.dart';
import 'order_status.dart';

class ServiceOrder {
  final String id;

  final String clientId;
  final String driverId;

  final DateTime scheduledAt;

  final ServiceType serviceType;
  final PaymentMethod paymentMethod;

  final double price;

  final String addressSnapshot;
  final String phoneSnapshot;

  final String? notes;

  // ✅ new fields (history / driver workflow)
  final OrderStatus status;
  final String? disposalNote; // where it was dumped (driver writes)
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceOrder({
    required this.id,
    required this.clientId,
    required this.driverId,
    required this.scheduledAt,
    required this.serviceType,
    required this.paymentMethod,
    required this.price,
    required this.addressSnapshot,
    required this.phoneSnapshot,
    this.notes,
    required this.status,
    this.disposalNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceOrder.create({
    required String id,
    required String clientId,
    required String driverId,
    required DateTime scheduledAt,
    required ServiceType serviceType,
    required PaymentMethod paymentMethod,
    double? price,
    required String addressSnapshot,
    required String phoneSnapshot,
    String? notes,
  }) {
    final defaultPrice = serviceType.defaultPrice;

    double resolvedPrice;
    if (serviceType == ServiceType.miscellaneous) {
      if (price == null) throw ArgumentError('price is required for miscellaneous');
      if (price <= 0) throw ArgumentError('price must be > 0');
      resolvedPrice = price;
    } else {
      resolvedPrice = (price ?? defaultPrice ?? 0).toDouble();
      if (resolvedPrice <= 0) throw ArgumentError('price must be > 0');
    }

    final now = DateTime.now();

    return ServiceOrder(
      id: id,
      clientId: clientId,
      driverId: driverId,
      scheduledAt: scheduledAt,
      serviceType: serviceType,
      paymentMethod: paymentMethod,
      price: resolvedPrice,
      addressSnapshot: addressSnapshot,
      phoneSnapshot: phoneSnapshot,
      notes: notes,
      status: OrderStatus.scheduled,
      disposalNote: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  ServiceOrder copyWith({
    String? id,
    String? clientId,
    String? driverId,
    DateTime? scheduledAt,
    ServiceType? serviceType,
    PaymentMethod? paymentMethod,
    double? price,
    String? addressSnapshot,
    String? phoneSnapshot,
    String? notes,
    OrderStatus? status,
    String? disposalNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceOrder(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      driverId: driverId ?? this.driverId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      serviceType: serviceType ?? this.serviceType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      price: price ?? this.price,
      addressSnapshot: addressSnapshot ?? this.addressSnapshot,
      phoneSnapshot: phoneSnapshot ?? this.phoneSnapshot,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      disposalNote: disposalNote ?? this.disposalNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'driverId': driverId,
      'scheduledAt': scheduledAt.toIso8601String(),
      'serviceType': serviceType.name,
      'paymentMethod': paymentMethod.name,
      'price': price,
      'addressSnapshot': addressSnapshot,
      'phoneSnapshot': phoneSnapshot,
      'notes': notes,
      'status': status.name,
      'disposalNote': disposalNote,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static ServiceOrder fromMap(Map data) {
    final now = DateTime.now();

    return ServiceOrder(
      id: (data['id'] ?? '') as String,
      clientId: (data['clientId'] ?? '') as String,
      driverId: (data['driverId'] ?? '') as String,
      scheduledAt: DateTime.parse(data['scheduledAt'] as String),
      serviceType: ServiceType.values.byName(data['serviceType'] as String),
      paymentMethod: PaymentMethod.values.byName(data['paymentMethod'] as String),
      price: (data['price'] as num).toDouble(),
      addressSnapshot: (data['addressSnapshot'] ?? '') as String,
      phoneSnapshot: (data['phoneSnapshot'] ?? '') as String,
      notes: data['notes'] as String?,
      status: data['status'] == null
          ? OrderStatus.scheduled
          : OrderStatus.values.byName(data['status'] as String),
      disposalNote: data['disposalNote'] as String?,
      createdAt: data['createdAt'] == null ? now : DateTime.parse(data['createdAt'] as String),
      updatedAt: data['updatedAt'] == null ? now : DateTime.parse(data['updatedAt'] as String),
    );
  }
}
