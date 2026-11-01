import '../../data/models/parsed_transaction.dart';

class TransactionDeduplicator {
  final Set<String> _seenReferences = {};
  final Set<String> _seenFingerprints = {};

  void reset() {
    _seenReferences.clear();
    _seenFingerprints.clear();
  }

  bool isDuplicate(ParsedTransaction tx) {
    // 1. Same reference (when present)
    if (tx.reference != null && tx.reference!.trim().isNotEmpty) {
      final ref = tx.reference!.trim().toLowerCase();
      if (_seenReferences.contains(ref)) {
        return true;
      }
    }

    // 2. Same amountPaise + type + accountLast4 + party + calendar day
    final dayKey =
        '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';
    final partyKey = tx.party.trim().toLowerCase();
    final accountKey = (tx.accountLast4 ?? '').trim();
    final fingerprint =
        '${tx.amountPaise}|${tx.type.name}|$accountKey|$partyKey|$dayKey';

    if (_seenFingerprints.contains(fingerprint)) {
      return true;
    }

    // Record as seen
    if (tx.reference != null && tx.reference!.trim().isNotEmpty) {
      _seenReferences.add(tx.reference!.trim().toLowerCase());
    }
    _seenFingerprints.add(fingerprint);

    return false;
  }
}
