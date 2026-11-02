import 'package:another_telephony/telephony.dart';
import '../models/raw_sms_message.dart';

class SmsReader {
  final Telephony? _telephony;

  const SmsReader({Telephony? telephony}) : _telephony = telephony;

  Future<List<RawSmsMessage>> fetchInboxMessages({int? sinceMillis}) async {
    final telephony = _telephony ?? Telephony.instance;
    final List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: sinceMillis == null
          ? null
          : SmsFilter.where(SmsColumn.DATE).greaterThan('$sinceMillis'),
    );

    return messages.map((m) {
      final date = m.date != null
          ? DateTime.fromMillisecondsSinceEpoch(m.date!)
          : DateTime.now();
      return RawSmsMessage(sender: m.address, body: m.body ?? '', date: date);
    }).toList();
  }

  static RawSmsMessage fromTelephony(SmsMessage message) {
    final date = message.date != null
        ? DateTime.fromMillisecondsSinceEpoch(message.date!)
        : DateTime.now();
    return RawSmsMessage(
      sender: message.address,
      body: message.body ?? '',
      date: date,
    );
  }
}
