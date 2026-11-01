import 'transaction_status.dart';
import 'transaction_type.dart';

class ParsedTransaction {
  final int? id;
  final int amountPaise;
  final TransactionType type;
  final String party;
  final String category;
  final String? accountLast4;
  final String? reference;
  final DateTime date;
  final String? sender;
  final String? matchedPhrase;
  final bool lowConfidence;
  final String? confidenceReason;
  final TransactionStatus status;
  final String categorySource;

  bool get isLowConfidence => lowConfidence;

  const ParsedTransaction({
    this.id,
    required this.amountPaise,
    required this.type,
    required this.party,
    required this.category,
    this.accountLast4,
    this.reference,
    required this.date,
    this.sender,
    this.matchedPhrase,
    this.lowConfidence = false,
    this.confidenceReason,
    this.status = TransactionStatus.pending,
    this.categorySource = 'auto',
  });

  ParsedTransaction copyWith({
    int? id,
    int? amountPaise,
    TransactionType? type,
    String? party,
    String? category,
    String? accountLast4,
    String? reference,
    DateTime? date,
    String? sender,
    String? matchedPhrase,
    bool? lowConfidence,
    String? confidenceReason,
    TransactionStatus? status,
    String? categorySource,
  }) {
    return ParsedTransaction(
      id: id ?? this.id,
      amountPaise: amountPaise ?? this.amountPaise,
      type: type ?? this.type,
      party: party ?? this.party,
      category: category ?? this.category,
      accountLast4: accountLast4 ?? this.accountLast4,
      reference: reference ?? this.reference,
      date: date ?? this.date,
      sender: sender ?? this.sender,
      matchedPhrase: matchedPhrase ?? this.matchedPhrase,
      lowConfidence: lowConfidence ?? this.lowConfidence,
      confidenceReason: confidenceReason ?? this.confidenceReason,
      status: status ?? this.status,
      categorySource: categorySource ?? this.categorySource,
    );
  }
}
