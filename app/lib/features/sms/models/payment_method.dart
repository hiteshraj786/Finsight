enum PaymentMethod {
  upi('UPI'),
  card('Card'),
  netBanking('Net banking'),
  atm('ATM'),
  cash('Cash'),
  unknown('Other');

  final String label;
  const PaymentMethod(this.label);

  static PaymentMethod fromName(String? name) => PaymentMethod.values.firstWhere(
        (method) => method.name == name,
        orElse: () => PaymentMethod.unknown,
      );
}
