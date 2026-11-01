/// How a transaction was paid. Stored by [name] in the database, so values
/// must never be renamed once released.
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
    (m) => m.name == name,
    orElse: () => PaymentMethod.unknown,
  );
}
