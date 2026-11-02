import '../models/payment_method.dart';

class PaymentMethodDetector {
  const PaymentMethodDetector();

  static final _upi = RegExp(
    r'\bupi\b|\bvpa\b|upi[/:-]|@(?:ok\w*|ybl|ibl|axl|paytm|apl|sbi|icici|hdfcbank|axisbank|kotak|yesbank)\b',
    caseSensitive: false,
  );
  static final _atm = RegExp(
    r'\batm\b|cash\s+withdrawa?l|withdrawn\s+(?:at|from)\s+atm',
    caseSensitive: false,
  );
  static final _netBanking = RegExp(
    r'\bneft\b|\bimps\b|\brtgs\b|net\s*-?\s*banking|internet\s+banking|\bnach\b|\becs\b|\bbillpay\b',
    caseSensitive: false,
  );
  static final _card = RegExp(
    r'\b(?:credit|debit)\s+card\b|\bcard\s+(?:no\.?\s*)?(?:ending|xx|\*\*|x{2,}|\d{4})|\bpos\b',
    caseSensitive: false,
  );
  static final _upiStyleSend = RegExp(
    r'\b(?:sent|paid|trf\s+to)\b[\s\S]*\bref(?:\s*no)?\.?\s*[:#-]?\s*\d{12}\b',
    caseSensitive: false,
  );

  PaymentMethod detect(String body) {
    if (_upi.hasMatch(body) || _upiStyleSend.hasMatch(body)) {
      return PaymentMethod.upi;
    }
    if (_atm.hasMatch(body)) return PaymentMethod.atm;
    if (_netBanking.hasMatch(body)) return PaymentMethod.netBanking;
    if (_card.hasMatch(body)) return PaymentMethod.card;
    return PaymentMethod.unknown;
  }
}
