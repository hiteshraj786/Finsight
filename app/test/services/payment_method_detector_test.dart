import 'package:finsight/data/models/payment_method.dart';
import 'package:finsight/data/models/raw_sms_message.dart';
import 'package:finsight/services/sms/payment_method_detector.dart';
import 'package:finsight/services/sms/sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const detector = PaymentMethodDetector();

  final cases = <String, PaymentMethod>{
    // UPI
    'Sent Rs.250.00 from HDFC Bank A/C *1234 To SWIGGY On 30/10/26 Ref 630412345678':
        PaymentMethod.upi,
    'Rs.250.00 debited from A/c XX1234 on 30-10-26 to VPA swiggy@ybl (UPI Ref No 630412345678)':
        PaymentMethod.upi,
    'Dear UPI user A/C X1234 debited by 120.0 on date 30Oct26 trf to ZOMATO Refno 630498765432':
        PaymentMethod.upi,
    'Your a/c no. XXXXXXXX1234 is credited with Rs 500.00 by UPI/P2P/630411112222/RAHUL':
        PaymentMethod.upi,
    'Paid Rs.99 to merchant@okaxis from A/c XX1234':
        PaymentMethod.upi,
    // Card
    'Rs.1,499.00 spent on your SBI Credit Card ending 4321 at AMAZON on 30/10/26':
        PaymentMethod.card,
    'INR 2,000.00 spent on HDFC Bank Card x9876 at FLIPKART on 2026-10-30':
        PaymentMethod.card,
    'Txn of Rs 650 on Debit Card XX5555 at DMART POS on 30-Oct-26':
        PaymentMethod.card,
    // Net banking / transfers
    'Rs 10,000.00 debited from A/c XX1234 for NEFT to RAHUL KUMAR. Ref N30412345':
        PaymentMethod.netBanking,
    'IMPS of Rs.3,000 from A/c XX1234 to A/c XX9876 successful. Ref 630400001111':
        PaymentMethod.netBanking,
    'Rs.5000 transferred via Net Banking from your a/c XX1234':
        PaymentMethod.netBanking,
    'Your A/c XX1234 debited Rs 899 towards NACH mandate for INSURANCE':
        PaymentMethod.netBanking,
    // ATM
    'Rs.2000 withdrawn at ATM S1AB1234 from A/c XX1234 on 30Oct26':
        PaymentMethod.atm,
    'Cash withdrawal of Rs 500 from your Debit Card XX5555':
        PaymentMethod.atm,
  };

  cases.forEach((sms, expected) {
    test('${expected.name}: $sms', () {
      expect(detector.detect(sms), expected);
    });
  });

  test('UPI wins when a UPI payment also mentions a card', () {
    expect(
      detector.detect(
        'Rs 300 debited from RuPay Credit Card XX4321 via UPI to CAFE COFFEE',
      ),
      PaymentMethod.upi,
    );
  });

  test('the parser stores the detected method', () {
    final tx = const SmsParser().parse(
      RawSmsMessage(
        sender: 'AD-HDFCBK',
        body: 'Rs.1,499.00 spent on your HDFC Bank Credit Card ending 4321 at AMAZON on 30/10/26',
        date: DateTime(2026, 10, 30),
      ),
    );
    expect(tx, isNotNull);
    expect(tx!.paymentMethod, PaymentMethod.card);
  });
}
