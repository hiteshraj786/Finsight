import '../models/parsed_transaction.dart';
import '../models/raw_sms_message.dart';
import '../models/transaction_type.dart';
import 'sms_categorizer.dart';

class SmsParser {
  final SmsCategorizer categorizer;

  const SmsParser({this.categorizer = const SmsCategorizer()});

  static final RegExp _currencyAmountRegex = RegExp(
    r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)|\b([\d,]+(?:\.\d{1,2})?)\s*(?:INR|Rs\.?|₹)',
    caseSensitive: false,
  );

  static final RegExp _actionVerbAmountRegex = RegExp(
    r'\b(?:debited\s+by|credited\s+by|debited\s+for|credited\s+with|paid|sent|received)\s+(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static final RegExp _accountRegex = RegExp(
    r'(?:(?:A\/c|acct|account|card)\s*(?:no\.?)?\s*(?:ending\s+(?:in\s+)?)?|ending\s+(?:in\s+)?)[:\s#]*[xX*]*(\d{4})\b|\b[xX*]+(\d{4})\b',
    caseSensitive: false,
  );

  static final RegExp _referenceRegex = RegExp(
    r'\b(?:UPI\s+Ref(?:\s*(?:no|num|id)\.?)?|Txn\s*(?:ID|no\.?|Ref|num)?|Ref\s*(?:no|num|id)?\.?|Refno)\b\s*[:\s#-]*([a-zA-Z0-9]+)',
    caseSensitive: false,
  );

  static final RegExp _upiSlashRegex = RegExp(
    r'UPI\/(?:[a-zA-Z0-9_\-]+\/)+([a-zA-Z0-9\s._\-]+?)(?:\/|\.|\s|$)',
    caseSensitive: false,
  );

  static final RegExp _forbiddenPartyWords = RegExp(
    r'\b(?:bill|download|your|account|balance|available|ref|upi|txn|avl|a\/c|acct|atm)\b',
    caseSensitive: false,
  );

  static const List<String> _leadingPhrases = [
    'transfer from',
    'transfer to',
    'trf to',
    'trf from',
    'received from',
    'payment to',
    'payment from',
    'paid to',
    'sent to',
    'credited by',
    'debited for',
    'to vpa',
    'vpa',
    'upi',
  ];

  static const List<String> _stoppers = [
    ' using ',
    ' on ',
    ' via ',
    ' refno',
    ' ref no',
    ' ref',
    ' upi',
    ' avl',
    ' bal',
    ' txn',
    ' dated',
    ' -',
    '. ',
    ',',
    '(',
  ];

  static const List<String> _debitKeywords = [
    'debited',
    'spent',
    'paid',
    'sent',
    'withdrawn',
    'purchase of',
    'transferred to',
    'transferred',
  ];

  static const List<String> _creditKeywords = [
    'credited',
    'received',
    'deposited',
    'refunded',
    'refund',
  ];

  static final RegExp _corporateKeywords = RegExp(
    r'\b(?:communications|technologies|private\s+limited|pvt\.?|ltd\.?)\b',
    caseSensitive: false,
  );

  ParsedTransaction? parse(
    RawSmsMessage message, {
    String? matchedPhrase,
    bool isLowConfidence = false,
  }) {
    try {
      final body = message.body;

      final amountPaise = _parseAmountPaise(body);
      if (amountPaise == null) {
        return null;
      }

      final type = _parseType(body);
      if (type == null) {
        return null;
      }

      final party = _parseParty(body, type);
      final category = categorizer.categorize(party);
      final accountLast4 = _parseAccountLast4(body);
      final reference = _parseReference(body);

      // Low confidence rules
      final List<String> reasons = [];

      // 1. Amount <= Rs 10 (1000 paise) and party is Unknown
      if (amountPaise <= 1000 && party.toLowerCase() == 'unknown') {
        reasons.add('Amount <= Rs 10 with Unknown party');
      }

      // 2. Sender is a plain phone number
      if (_isPlainPhoneNumber(message.sender)) {
        reasons.add('Sender is a plain phone number');
      }

      // 3. Corporate entity with amount <= Rs 10
      if (amountPaise <= 1000 && _corporateKeywords.hasMatch(party)) {
        reasons.add('Corporate entity with amount <= Rs 10');
      }

      final bool computedLowConfidence = reasons.isNotEmpty || isLowConfidence;
      final String? confidenceReason = computedLowConfidence
          ? (reasons.isNotEmpty ? reasons.join('; ') : 'Non-bank sender ID')
          : null;

      return ParsedTransaction(
        amountPaise: amountPaise,
        type: type,
        party: party,
        category: category,
        accountLast4: accountLast4,
        reference: reference,
        date: message.date,
        sender: message.sender,
        matchedPhrase: matchedPhrase,
        lowConfidence: computedLowConfidence,
        confidenceReason: confidenceReason,
      );
    } catch (_) {
      // Malformed text must not crash
      return null;
    }
  }

  static bool _isPlainPhoneNumber(String? sender) {
    if (sender == null || sender.trim().isEmpty) return false;
    final s = sender.trim();
    if (RegExp(r'[a-zA-Z]').hasMatch(s)) {
      return false;
    }
    final digitsOnly = s.replaceAll(RegExp(r'[\s+\-]'), '');
    return RegExp(r'^\d{7,15}$').hasMatch(digitsOnly);
  }

  int? _parseAmountPaise(String body) {
    Match? match = _currencyAmountRegex.firstMatch(body);
    String? rawAmount;

    if (match != null) {
      rawAmount = (match.group(1) ?? match.group(2))?.trim();
    }

    if (rawAmount == null || rawAmount.isEmpty) {
      final actionMatch = _actionVerbAmountRegex.firstMatch(body);
      if (actionMatch != null) {
        rawAmount = actionMatch.group(1)?.trim();
      }
    }

    if (rawAmount == null || rawAmount.isEmpty) return null;

    final cleanStr = rawAmount.replaceAll(',', '').trim();
    if (cleanStr.contains('.')) {
      final parts = cleanStr.split('.');
      final rupees = int.tryParse(parts[0]);
      if (rupees == null) return null;

      var decimalPart = parts.length > 1 ? parts[1] : '0';
      if (decimalPart.length == 1) {
        decimalPart = '${decimalPart}0';
      } else if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2);
      }
      final paise = int.tryParse(decimalPart) ?? 0;
      return rupees * 100 + paise;
    } else {
      final rupees = int.tryParse(cleanStr);
      if (rupees == null) return null;
      return rupees * 100;
    }
  }

  TransactionType? _parseType(String body) {
    final lower = body.toLowerCase();

    int firstDebitIndex = -1;
    for (final kw in _debitKeywords) {
      final idx = lower.indexOf(kw);
      if (idx != -1 && (firstDebitIndex == -1 || idx < firstDebitIndex)) {
        firstDebitIndex = idx;
      }
    }

    int firstCreditIndex = -1;
    for (final kw in _creditKeywords) {
      final idx = lower.indexOf(kw);
      if (idx != -1 && (firstCreditIndex == -1 || idx < firstCreditIndex)) {
        firstCreditIndex = idx;
      }
    }

    if (firstDebitIndex != -1 && firstCreditIndex != -1) {
      return firstDebitIndex < firstCreditIndex
          ? TransactionType.debit
          : TransactionType.credit;
    } else if (firstDebitIndex != -1) {
      return TransactionType.debit;
    } else if (firstCreditIndex != -1) {
      return TransactionType.credit;
    }

    return null;
  }

  String _parseParty(String body, TransactionType type) {
    // 1. UPI slash format: UPI/<id>/NAME
    final upiMatch = _upiSlashRegex.firstMatch(body);
    if (upiMatch != null) {
      final candidate = _cleanParty(upiMatch.group(1));
      if (_isValidParty(candidate)) {
        return candidate;
      }
    }

    // 2. Info: Merchant
    final infoRegex = RegExp(r'\bInfo:\s*', caseSensitive: false);
    final infoMatch = infoRegex.firstMatch(body);
    if (infoMatch != null) {
      final candidate = _extractAfter(body, infoMatch.end);
      if (_isValidParty(candidate)) {
        return candidate;
      }
    }

    // 3. VPA
    final vpaRegex = RegExp(r'\bVPA\s*[:\s-]*', caseSensitive: false);
    final vpaMatch = vpaRegex.firstMatch(body);
    if (vpaMatch != null) {
      final candidate = _extractAfter(body, vpaMatch.end);
      if (_isValidParty(candidate)) {
        return candidate;
      }
    }

    // 4. Direction-specific starters
    final List<RegExp> starterRegexes = [];
    if (type == TransactionType.credit) {
      starterRegexes.add(RegExp(r'\breceived from\s+', caseSensitive: false));
      starterRegexes.add(RegExp(r'\btransfer from\s+', caseSensitive: false));
      starterRegexes.add(RegExp(r'\btrf from\s+', caseSensitive: false));
      starterRegexes.add(RegExp(r'\bpayment from\s+', caseSensitive: false));
      starterRegexes.add(RegExp(r'\bcredited by\s+', caseSensitive: false));
      starterRegexes.add(RegExp(r'\bfrom\s+', caseSensitive: false));
      starterRegexes.add(
        RegExp(r'\bby\s+(?!(?:Rs\.?|INR|₹|\d))', caseSensitive: false),
      );
      starterRegexes.add(RegExp(r'\bto vpa\s+', caseSensitive: false));
      starterRegexes.add(RegExp(r'\bto\s+', caseSensitive: false));
    } else {
      starterRegexes.add(RegExp(r'\btransferred to\s+', caseSensitive: false));
      starterRegexes.add(RegExp(r'\btransfer to\s+', caseSensitive: false));
      starterRegexes.add(RegExp(r'\btrf to\s+', caseSensitive: false));
      starterRegexes.add(RegExp(r'\bpayment to\s+', caseSensitive: false));
      starterRegexes.add(RegExp(r'\bpaid to\s+', caseSensitive: false));
      starterRegexes.add(RegExp(r'\bsent to\s+', caseSensitive: false));
      starterRegexes.add(RegExp(r'\bto vpa\s+', caseSensitive: false));
      starterRegexes.add(RegExp(r'\bto\s+', caseSensitive: false));
      starterRegexes.add(RegExp(r'\bat\s+', caseSensitive: false));
      starterRegexes.add(
        RegExp(r'\bby\s+(?!(?:Rs\.?|INR|₹|\d))', caseSensitive: false),
      );
      starterRegexes.add(RegExp(r'\btransfer from\s+', caseSensitive: false));
      starterRegexes.add(RegExp(r'\btrf from\s+', caseSensitive: false));
      starterRegexes.add(RegExp(r'\bfrom\s+', caseSensitive: false));
    }

    for (final regex in starterRegexes) {
      for (final match in regex.allMatches(body)) {
        final candidate = _extractAfter(body, match.end);
        if (_isValidParty(candidate)) {
          return candidate;
        }
      }
    }

    return 'Unknown';
  }

  String _extractAfter(String text, int startIndex) {
    if (startIndex >= text.length) return '';
    final remaining = text.substring(startIndex);

    // Normalize abbreviation dots (e.g. Mr., Mrs., Ms., Dr., Shri., Smt.) so that '.' is not treated as a stopper
    final normalized = remaining.replaceAllMapped(
      RegExp(r'\b(Mr|Mrs|Ms|Dr|Shri|Smt)\.\s*', caseSensitive: false),
      (m) => '${m.group(1)} ',
    );

    final earliestStopper = _findEarliestStopper(normalized);
    final rawCandidate = normalized.substring(0, earliestStopper);
    return _cleanParty(rawCandidate);
  }

  int _findEarliestStopper(String text) {
    final lower = text.toLowerCase();
    int earliest = text.length;
    for (final stopper in _stoppers) {
      final idx = lower.indexOf(stopper);
      if (idx != -1 && idx < earliest) {
        earliest = idx;
      }
    }
    return earliest;
  }

  String _cleanParty(String? raw) {
    if (raw == null) return '';
    var text = raw.trim();

    // If it contains a VPA handle like "name@bank", take the name part and tidy it
    if (text.contains('@')) {
      final vpaParts = text.split('@');
      var namePart = vpaParts.first.trim();
      namePart = namePart.replaceAll(RegExp(r'[._]'), ' ').trim();
      if (namePart.isNotEmpty) {
        text = namePart;
      }
    }

    // Remove leading/trailing non-alphanumeric characters
    text = text.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '').trim();

    // Strip leading phrases like "transfer from", "payment to", etc.
    text = _stripLeadingPhrases(text);

    // Handle titles: keep the name after Mr, Mrs, Ms, Shri, Smt, Dr
    text = _stripTitle(text);

    // Strip leading phrases again if they were nested
    text = _stripLeadingPhrases(text);

    // Collapse spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Remove trailing words like A/c, Bank
    text = text
        .replaceAll(
          RegExp(r'\s+(?:A\/c|acct|Bank)\b', caseSensitive: false),
          '',
        )
        .trim();

    // Title-case
    text = _toTitleCase(text);
    return text;
  }

  String _stripLeadingPhrases(String text) {
    var current = text.trim();
    bool changed = true;
    while (changed) {
      changed = false;
      final lower = current.toLowerCase();
      for (final phrase in _leadingPhrases) {
        if (lower.startsWith('$phrase ') || lower == phrase) {
          current = current.substring(phrase.length).trim();
          current = current.replaceAll(RegExp(r'^[^\w]+'), '').trim();
          changed = true;
          break;
        }
      }
    }
    return current;
  }

  String _stripTitle(String text) {
    final titleRegex = RegExp(
      r'^(?:(?:Mr|Mrs|Ms|Shri|Smt|Dr)\.?\s+)',
      caseSensitive: false,
    );
    return text.replaceFirst(titleRegex, '').trim();
  }

  bool _isOnlyTitle(String text) {
    final onlyTitleRegex = RegExp(
      r'^(?:Mr|Mrs|Ms|Shri|Smt|Dr)\.?$',
      caseSensitive: false,
    );
    return onlyTitleRegex.hasMatch(text.trim());
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          if (word.length == 1) return word.toUpperCase();
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  bool _isValidParty(String party) {
    if (party.isEmpty) return false;
    // Never return party longer than 40 chars
    if (party.length > 40) return false;
    // Never return only a title
    if (_isOnlyTitle(party)) return false;
    // Never return a single word of 2 letters or fewer
    final words = party.trim().split(RegExp(r'\s+'));
    if (words.length == 1 && words.first.length <= 2) {
      return false;
    }
    // Disallow currency or amount tokens
    if (RegExp(r'^(?:Rs\.?|INR|₹)', caseSensitive: false).hasMatch(party)) {
      return false;
    }
    if (_currencyAmountRegex.hasMatch(party)) return false;
    // Disallow forbidden words
    if (_forbiddenPartyWords.hasMatch(party)) return false;
    // Disallow pure digits
    if (RegExp(r'^\d+$').hasMatch(party)) return false;
    const invalidValues = {'unknown', 'vpa', 'inr', 'rs', 'card', 'atm'};
    if (invalidValues.contains(party.toLowerCase())) return false;
    return true;
  }

  String? _parseAccountLast4(String body) {
    final match = _accountRegex.firstMatch(body);
    if (match != null) {
      return match.group(1) ?? match.group(2);
    }
    return null;
  }

  String? _parseReference(String body) {
    final match = _referenceRegex.firstMatch(body);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }
}
