import 'package:another_telephony/telephony.dart';
import '../../data/models/raw_sms_message.dart';

class SmsReader {
  final Telephony? _telephony;

  const SmsReader({Telephony? telephony}) : _telephony = telephony;

  /// Reads inbox SMS. With [sinceMillis], Android returns only messages
  /// received after that time, so routine syncs never re-read the whole inbox.
  Future<List<RawSmsMessage>> fetchInboxMessages({int? sinceMillis}) async {
    final telephony = _telephony ?? Telephony.instance;
    final List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: sinceMillis == null
          ? null
          : SmsFilter.where(SmsColumn.DATE).greaterThan('$sinceMillis'),
    );

    return messages.map(fromTelephony).toList();
  }

  static RawSmsMessage fromTelephony(SmsMessage m) {
    final date = m.date != null
        ? DateTime.fromMillisecondsSinceEpoch(m.date!)
        : DateTime.now();
    return RawSmsMessage(sender: m.address, body: m.body ?? '', date: date);
  }
}
