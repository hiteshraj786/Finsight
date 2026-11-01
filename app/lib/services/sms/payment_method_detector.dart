import '../../data/models/payment_method.dart';

/// Works out from a bank SMS whether money moved by UPI, card, net banking
/// (NEFT/IMPS/RTGS) or an ATM withdrawal.
///
/// UPI is checked first: UPI payments made from a RuPay credit card still
/// mention "card", but the user thinks of them as UPI payments.
class PaymentMethodDetector {
  const PaymentMethodDetector();

  static final RegExp _upi = RegExp(
    r'\bupi\b|\bvpa\b|upi[/:-]|@(?:ok\w*|ybl|ibl|axl|paytm|apl|upi|sbi|icici|hdfcbank|axisbank|kotak|yesbank|jupiteraxis|fbl|waaxis|wahdfcbank|wasbi|naviaxis|pthdfc|ptsbi|ptyes|ptaxis)\b',
    caseSensitive: false,
  );

  static final RegExp _atm = RegExp(
    r'\batm\b|cash\s+withdrawa?l|withdrawn\s+(?:at|from)\s+atm',
    caseSensitive: false,
  );

  static final RegExp _netBanking = RegExp(
    r'\bneft\b|\bimps\b|\brtgs\b|net\s*-?\s*banking|internet\s+banking|\bmobile\s+banking\b|\bnach\b|\becs\b|\bbillpay\b',
    caseSensitive: false,
  );

  static final RegExp _card = RegExp(
    r'\b(?:credit|debit)\s+card\b|\bcard\s+(?:no\.?\s*)?(?:ending|xx|\*\*|x{2,}|\d{4})|\bcard\b|\bpos\b|\bcc\s+(?:xx|ending|\d{4})',
    caseSensitive: false,
  );

  /// Some banks (e.g. HDFC's "Sent Rs.X From ... To ... Ref 6304...") never
  /// say "UPI"; a person-to-merchant send with a 12-digit reference (the UPI
  /// RRN) is still UPI. IMPS uses the same reference format, so this only
  /// runs after the net-banking check.
  static final RegExp _upiStyleSend = RegExp(
    r'\b(?:sent|paid|trf\s+to)\b[\s\S]*\bref(?:\s*no)?\.?\s*[:#-]?\s*\d{12}\b',
    caseSensitive: false,
  );

  PaymentMethod detect(String body) {
    if (_upi.hasMatch(body)) return PaymentMethod.upi;
    if (_atm.hasMatch(body)) return PaymentMethod.atm;
    if (_netBanking.hasMatch(body)) return PaymentMethod.netBanking;
    if (_card.hasMatch(body)) return PaymentMethod.card;
    if (_upiStyleSend.hasMatch(body)) return PaymentMethod.upi;
    return PaymentMethod.unknown;
  }
}
