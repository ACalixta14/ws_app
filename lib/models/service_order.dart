import 'payment_method.dart';
import 'service_type.dart';
import 'order_status.dart';
import 'job_stage.dart';

class ServiceOrder {
  final String id;

  final String clientId;
  final String driverId;

  final DateTime scheduledAt;

  final ServiceType serviceType;
  final PaymentMethod paymentMethod;

  final double price;

  final String serviceAddress;
  final List<String> additionalStops;

  final String phoneSnapshot;

  final String? notes;

  final OrderStatus status;
  final JobStage jobStage;
  final String? disposalNote;
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
    required this.serviceAddress,
    this.additionalStops = const [],
    required this.phoneSnapshot,
    this.notes,
    required this.status,
    required this.jobStage,
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
    required String serviceAddress,
    List<String>? additionalStops,
    required String phoneSnapshot,
    String? notes,
  }) {
    final defaultPrice = serviceType.defaultPrice;

    double resolvedPrice;
    if (serviceType == ServiceType.miscellaneous) {
      if (price == null) {
        throw ArgumentError('price is required for miscellaneous');
      }
      if (price <= 0) {
        throw ArgumentError('price must be > 0');
      }
      resolvedPrice = price;
    } else {
      resolvedPrice = (price ?? defaultPrice ?? 0).toDouble();
      if (resolvedPrice <= 0) {
        throw ArgumentError('price must be > 0');
      }
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
      serviceAddress: serviceAddress,
      additionalStops: additionalStops ?? const [],
      phoneSnapshot: phoneSnapshot,
      notes: notes,
      status: OrderStatus.scheduled,
      jobStage: JobStage.waiting,
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
    String? serviceAddress,
    List<String>? additionalStops,
    String? phoneSnapshot,
    String? notes,
    OrderStatus? status,
    JobStage? jobStage,
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
      serviceAddress: serviceAddress ?? this.serviceAddress,
      additionalStops: additionalStops ?? this.additionalStops,
      phoneSnapshot: phoneSnapshot ?? this.phoneSnapshot,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      jobStage: jobStage ?? this.jobStage,
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
      'serviceAddress': serviceAddress,
      'additionalStops': additionalStops,
      'phoneSnapshot': phoneSnapshot,
      'notes': notes,
      'status': status.name,
      'jobStage': jobStage.name,
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
      paymentMethod:
          PaymentMethod.values.byName(data['paymentMethod'] as String),
      price: (data['price'] as num).toDouble(),
      serviceAddress: (data['serviceAddress'] ?? '') as String,
      additionalStops:
          (data['additionalStops'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      phoneSnapshot: (data['phoneSnapshot'] ?? '') as String,
      notes: data['notes'] as String?,
      status: data['status'] == null
          ? OrderStatus.scheduled
          : OrderStatus.values.byName(data['status'] as String),
      jobStage: data['jobStage'] == null
          ? JobStage.waiting
          : JobStage.values.byName(data['jobStage'] as String),
      disposalNote: data['disposalNote'] as String?,
      createdAt: data['createdAt'] == null
          ? now
          : DateTime.parse(data['createdAt'] as String),
      updatedAt: data['updatedAt'] == null
          ? now
          : DateTime.parse(data['updatedAt'] as String),
    );
  }
}