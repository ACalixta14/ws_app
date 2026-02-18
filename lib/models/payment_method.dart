enum PaymentMethod {
  bankTransfer('Bank transfer'),
  mbWay('MB Way'),
  cash('Cash');

  final String label;

  const PaymentMethod(this.label);
}


extension PaymentMethodExtension on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.mbWay:
        return 'MB Way';
      case PaymentMethod.cash:
        return 'Cash';
    }
  }
}
