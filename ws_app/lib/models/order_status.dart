enum OrderStatus {
  scheduled,
  done,
  canceled,
}

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.scheduled:
        return 'Scheduled';
      case OrderStatus.done:
        return 'Done';
      case OrderStatus.canceled:
        return 'Canceled';
    }
  }
}
