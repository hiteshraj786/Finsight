import '../models/parsed_transaction.dart';
import '../models/raw_sms_message.dart';
import 'dedupe.dart';
import 'sms_filter.dart';
import 'sms_parser.dart';
import 'sms_reader.dart';

class UnreadableMessage {
  final String senderId;
  final DateTime date;
  final String reason;

  const UnreadableMessage({
    required this.senderId,
    required this.date,
    required this.reason,
  });
}

class ScanResult {
  final int messagesChecked;
  final int transactionsFound;
  final int duplicates;
  final int skipped;
  final Map<String, int> rejectionReasons;
  final Map<String, int> senderCounts;
  final List<ParsedTransaction> transactions;
  final List<UnreadableMessage> unreadableMessages;

  const ScanResult({
    required this.messagesChecked,
    required this.transactionsFound,
    required this.duplicates,
    required this.skipped,
    required this.rejectionReasons,
    required this.senderCounts,
    required this.transactions,
    this.unreadableMessages = const [],
  });

  static const ScanResult empty = ScanResult(
    messagesChecked: 0,
    transactionsFound: 0,
    duplicates: 0,
    skipped: 0,
    rejectionReasons: {},
    senderCounts: {},
    transactions: [],
    unreadableMessages: [],
  );
}

class SmsPipeline {
  final SmsReader reader;
  final SmsFilter filter;
  final SmsParser parser;

  SmsPipeline({SmsReader? reader, SmsFilter? filter, SmsParser? parser})
    : reader = reader ?? const SmsReader(),
      filter = filter ?? const SmsFilter(),
      parser = parser ?? const SmsParser();

  Future<ScanResult> run() async {
    final messages = await reader.fetchInboxMessages();
    return processMessages(messages);
  }

  ScanResult processMessages(List<RawSmsMessage> messages) {
    int checked = 0;
    int skipped = 0;
    int duplicates = 0;
    final Map<String, int> rejectionReasons = {};
    final Map<String, int> senderCounts = {};
    final List<ParsedTransaction> transactions = [];
    final List<UnreadableMessage> unreadableMessages = [];
    final deduplicator = TransactionDeduplicator();

    for (final message in messages) {
      checked++;

      // 1. Filter stage
      final filterResult = filter.evaluate(
        message.body,
        sender: message.sender,
      );
      if (!filterResult.isAccepted) {
        skipped++;
        final reasonKey = _formatRejectionReason(filterResult.rejectionReason);
        rejectionReasons[reasonKey] = (rejectionReasons[reasonKey] ?? 0) + 1;

        // Collect unreadable non-OTP / non-promo bank messages
        if (filterResult.rejectionReason != RejectionReason.otp &&
            filterResult.rejectionReason != RejectionReason.promo) {
          unreadableMessages.add(
            UnreadableMessage(
              senderId: message.sender ?? 'Unknown',
              date: message.date,
              reason: _plainUnreadableReason(filterResult.rejectionReason),
            ),
          );
        }
        continue;
      }

      // 2. Parse & Categorize stage
      final parsed = parser.parse(
        message,
        matchedPhrase: filterResult.matchedPhrase,
        isLowConfidence: filterResult.isLowConfidence,
      );
      if (parsed == null) {
        skipped++;
        rejectionReasons['Unparseable format'] =
            (rejectionReasons['Unparseable format'] ?? 0) + 1;
        unreadableMessages.add(
          UnreadableMessage(
            senderId: message.sender ?? 'Unknown',
            date: message.date,
            reason: 'Merchant name not recognized',
          ),
        );
        continue;
      }

      // 3. Dedupe stage
      if (deduplicator.isDuplicate(parsed)) {
        duplicates++;
        continue;
      }

      // Accepted transaction
      transactions.add(parsed);
      final senderKey =
          (message.sender != null && message.sender!.trim().isNotEmpty)
              ? message.sender!.trim()
              : 'Unknown';
      senderCounts[senderKey] = (senderCounts[senderKey] ?? 0) + 1;
    }

    return ScanResult(
      messagesChecked: checked,
      transactionsFound: transactions.length,
      duplicates: duplicates,
      skipped: skipped,
      rejectionReasons: rejectionReasons,
      senderCounts: senderCounts,
      transactions: transactions,
      unreadableMessages: unreadableMessages,
    );
  }

  String _plainUnreadableReason(RejectionReason? reason) {
    switch (reason) {
      case RejectionReason.reminder:
        return 'Payment reminder or request';
      case RejectionReason.failedTransaction:
        return 'Failed or declined transaction';
      case RejectionReason.noAmount:
        return 'Amount not found';
      case RejectionReason.noActionWord:
        return 'No money movement detected';
      default:
        return 'Unrecognized transaction format';
    }
  }

  String _formatRejectionReason(RejectionReason? reason) {
    switch (reason) {
      case RejectionReason.reminder:
        return 'Reminder / Due / Request';
      case RejectionReason.otp:
        return 'OTP / Auth code';
      case RejectionReason.promo:
        return 'Promo / Offer / Loan';
      case RejectionReason.failedTransaction:
        return 'Failed / Declined / Reversed';
      case RejectionReason.noAmount:
        return 'No amount';
      case RejectionReason.noActionWord:
        return 'No completed-action word';
      case null:
        return 'Other non-transaction';
    }
  }
}
