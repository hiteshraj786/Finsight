class RawSmsMessage {
  final String? sender;
  final String body;
  final DateTime date;

  const RawSmsMessage({
    required this.sender,
    required this.body,
    required this.date,
  });
}
