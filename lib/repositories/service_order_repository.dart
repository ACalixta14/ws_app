import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/order_status.dart';
import '../models/service_order.dart';

class ServiceOrderRepository {
  Box<Map> get _box => Hive.box<Map>('orders');

  List<ServiceOrder> getAll() {
    return _box.values.map((m) => ServiceOrder.fromMap(m)).toList();
  }

  ServiceOrder? getById(String id) {
    final data = _box.get(id);
    if (data == null) return null;
    return ServiceOrder.fromMap(data);
  }

  Future<void> upsert(ServiceOrder order) async {
    await _box.put(order.id, order.toMap());
  }

  Future<void> add(ServiceOrder order) async => upsert(order);

  Future<void> update(ServiceOrder order) async => upsert(order);

  Future<void> clear() async => _box.clear();

  Future<void> deleteHard(String id) async => _box.delete(id);

  /// ✅ Scheduled -> Done (sem hard delete)
  Future<void> markDone(String orderId) async {
    final order = getById(orderId);
    if (order == null) return;

    if (order.status != OrderStatus.scheduled) return;

    final updated = order.copyWith(
      status: OrderStatus.done,
      updatedAt: DateTime.now(),
    );

    await upsert(updated);
  }
}
