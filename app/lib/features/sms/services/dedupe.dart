import '../models/parsed_transaction.dart';

class TransactionDeduplicator {
  static const timestampWindow = Duration(minutes: 10);
  final Set<String> _seenReferences = {};
  final List<ParsedTransaction> _seenTransactions = [];

  void reset() {
    _seenReferences.clear();
    _seenTransactions.clear();
  }

  bool isDuplicate(ParsedTransaction tx) {
    // 1. Same reference (when present)
    if (tx.reference != null && tx.reference!.trim().isNotEmpty) {
      final ref = tx.reference!.trim().toLowerCase();
      if (_seenReferences.contains(ref)) {
        return true;
      }
    }

    // 2. Same amount/type/account/party within a short delivery window.
    final duplicate = _seenTransactions.any((other) =>
        other.amountPaise == tx.amountPaise &&
        other.type == tx.type &&
        (other.accountLast4 ?? '').trim() == (tx.accountLast4 ?? '').trim() &&
        other.party.trim().toLowerCase() == tx.party.trim().toLowerCase() &&
        other.date.difference(tx.date).abs() <= timestampWindow);
    if (duplicate) {
      return true;
    }

    // Record as seen
    if (tx.reference != null && tx.reference!.trim().isNotEmpty) {
      _seenReferences.add(tx.reference!.trim().toLowerCase());
    }
    _seenTransactions.add(tx);

    return false;
  }
}
