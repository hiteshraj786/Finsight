String formatIndianRupees(int amountPaise) {
  final int rupees = (amountPaise ~/ 100).abs();
  final int paise = (amountPaise % 100).abs();
  final String paiseStr = paise.toString().padLeft(2, '0');

  final String rupeesStr = rupees.toString();
  if (rupeesStr.length <= 3) {
    return '₹$rupeesStr.$paiseStr';
  }

  final String lastThree = rupeesStr.substring(rupeesStr.length - 3);
  final String remaining = rupeesStr.substring(0, rupeesStr.length - 3);

  final StringBuffer formattedRemaining = StringBuffer();
  for (int i = 0; i < remaining.length; i++) {
    if (i > 0 && (remaining.length - i) % 2 == 0) {
      formattedRemaining.write(',');
    }
    formattedRemaining.write(remaining[i]);
  }

  return '₹$formattedRemaining,$lastThree.$paiseStr';
}
