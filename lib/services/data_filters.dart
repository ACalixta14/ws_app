import '../models/service_order.dart';

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isToday(ServiceOrder order) {
  final now = DateTime.now();
  return isSameDay(order.scheduledAt, now);
}

bool isTomorrow(ServiceOrder order) {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  return isSameDay(order.scheduledAt, tomorrow);
}
