enum RejectionReason {
  reminder,
  otp,
  promo,
  failedTransaction,
  noAmount,
  noActionWord,
}

class FilterResult {
  final bool isAccepted;
  final RejectionReason? rejectionReason;
  final String? matchedPhrase;
  final bool isLowConfidence;

  const FilterResult({
    required this.isAccepted,
    this.rejectionReason,
    this.matchedPhrase,
    this.isLowConfidence = false,
  });

  static const FilterResult accepted = FilterResult(isAccepted: true);
}

class SmsFilter {
  const SmsFilter();

  static final RegExp amountRegex = RegExp(
    r'(?:Rs\.?|INR|₹)\s*[\d,]+(?:\.\d{1,2})?|\b[\d,]+(?:\.\d{1,2})?\s*(?:INR|Rs\.?|₹)|\b(?:debited\s+by|credited\s+by|debited\s+for|credited\s+with|paid|sent|received)\s+(?:Rs\.?|INR|₹)?\s*[\d,]+(?:\.\d{1,2})?',
    caseSensitive: false,
  );

  // Readable lists of phrases for easy maintenance
  static const List<String> reminderPhrases = [
    'is due',
    'due on',
    'due date',
    'pay your',
    'pay now',
    'to pay',
    'view and download',
    'bill dated',
    'bill of',
    'your bill',
    'outstanding',
    'overdue',
    'will be debited',
    'will be credited',
    'scheduled',
    'autopay',
    'reminder',
    'collect request',
    'request',
    'requested',
  ];

  static const List<String> otpPhrases = [
    'otp',
    'one time password',
    'verification code',
    'auth code',
    'secret code',
    'do not share',
    "don't share",
    'never share',
  ];

  static const List<String> promoPhrases = [
    'pre-approved',
    'cashback offer',
    'emi offer',
    'reward points',
    'apply now',
    'loan',
    'click',
    'http',
    'offer',
    'win',
    'earn',
  ];

  static const List<String> failedPhrases = [
    'failed',
    'declined',
    'unsuccessful',
  ];

  static const List<String> completedActionWords = [
    'debited',
    'credited',
    'spent',
    'paid',
    'sent',
    'received',
    'withdrawn',
    'deposited',
    'transferred',
    'refund',
    'refunded',
    'purchase of',
  ];

  FilterResult evaluate(String body, {String? sender}) {
    final lower = body.toLowerCase();
    final isLowConf = isSenderLowConfidence(sender);

    // 1. Check reminder / future phrases
    for (final phrase in reminderPhrases) {
      if (_matchesPhrase(lower, phrase)) {
        return FilterResult(
          isAccepted: false,
          rejectionReason: RejectionReason.reminder,
          matchedPhrase: phrase,
          isLowConfidence: isLowConf,
        );
      }
    }

    // 2. Check OTP phrases
    for (final phrase in otpPhrases) {
      if (_matchesPhrase(lower, phrase)) {
        return FilterResult(
          isAccepted: false,
          rejectionReason: RejectionReason.otp,
          matchedPhrase: phrase,
          isLowConfidence: isLowConf,
        );
      }
    }

    // 3. Check promo phrases
    for (final phrase in promoPhrases) {
      if (_matchesPhrase(lower, phrase)) {
        return FilterResult(
          isAccepted: false,
          rejectionReason: RejectionReason.promo,
          matchedPhrase: phrase,
          isLowConfidence: isLowConf,
        );
      }
    }

    // 4. Check failed / declined phrases
    for (final phrase in failedPhrases) {
      if (_matchesPhrase(lower, phrase)) {
        return FilterResult(
          isAccepted: false,
          rejectionReason: RejectionReason.failedTransaction,
          matchedPhrase: phrase,
          isLowConfidence: isLowConf,
        );
      }
    }

    // "reversed" check: reject unless it indicates money was credited/refunded
    if (_matchesPhrase(lower, 'reversed')) {
      final isCreditOrRefund =
          _matchesPhrase(lower, 'credited') ||
          _matchesPhrase(lower, 'refund') ||
          _matchesPhrase(lower, 'refunded');
      if (!isCreditOrRefund) {
        return FilterResult(
          isAccepted: false,
          rejectionReason: RejectionReason.failedTransaction,
          matchedPhrase: 'reversed',
          isLowConfidence: isLowConf,
        );
      }
    }

    // 5. Must contain an amount
    if (!amountRegex.hasMatch(body)) {
      return FilterResult(
        isAccepted: false,
        rejectionReason: RejectionReason.noAmount,
        matchedPhrase: 'No amount found',
        isLowConfidence: isLowConf,
      );
    }

    // 6. Must contain a completed action word
    String? matchedAction;
    for (final word in completedActionWords) {
      if (_matchesPhrase(lower, word)) {
        matchedAction = word;
        break;
      }
    }

    if (matchedAction == null) {
      return FilterResult(
        isAccepted: false,
        rejectionReason: RejectionReason.noActionWord,
        matchedPhrase: 'No completed action word',
        isLowConfidence: isLowConf,
      );
    }

    // Accepted transaction
    return FilterResult(
      isAccepted: true,
      matchedPhrase: matchedAction,
      isLowConfidence: isLowConf,
    );
  }

  bool shouldKeep(String body, {String? sender}) {
    return evaluate(body, sender: sender).isAccepted;
  }

  bool isSenderLowConfidence(String? sender) {
    if (sender == null || sender.trim().isEmpty) return true;
    final s = sender.trim();
    final digitsOnly = s.replaceAll(RegExp(r'[\s+\-]'), '');
    // Phone numbers (typically 7-15 digits without letters)
    if (RegExp(r'^\d{7,15}$').hasMatch(digitsOnly)) {
      return true;
    }
    // Must contain letters to be an alphanumeric bank/service header (e.g. XX-ABCDEF or ABCDEF)
    if (!RegExp(r'[a-zA-Z]').hasMatch(s)) {
      return true;
    }
    return false;
  }

  bool _matchesPhrase(String lowerText, String phrase) {
    // If phrase is a single alphanumeric word, enforce word boundary
    if (RegExp(r'^\w+$').hasMatch(phrase)) {
      final regex = RegExp(
        r'\b' + RegExp.escape(phrase.toLowerCase()) + r'\b',
        caseSensitive: false,
      );
      return regex.hasMatch(lowerText);
    }
    return lowerText.contains(phrase.toLowerCase());
  }
}
