enum OrderStatus {
  scheduled,
  done,
  canceled,
}

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.scheduled:
        return 'Agendado';
      case OrderStatus.done:
        return 'Feito';
      case OrderStatus.canceled:
        return 'Cancelado';
    }
  }
}
