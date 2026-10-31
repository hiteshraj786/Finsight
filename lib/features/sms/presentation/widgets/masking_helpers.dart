String maskAccount(String? account) {
  if (account == null || account.trim().isEmpty) {
    return 'A/C ••0000';
  }
  final clean = account.replaceAll(RegExp(r'\D'), '');
  final last4 = clean.length >= 4
      ? clean.substring(clean.length - 4)
      : clean.padLeft(4, '0');
  return 'A/C ••$last4';
}

String? maskReference(String? reference) {
  if (reference == null || reference.trim().isEmpty) {
    return null;
  }
  final trimmed = reference.trim();
  final last4 = trimmed.length >= 4
      ? trimmed.substring(trimmed.length - 4)
      : trimmed;
  return 'Ref ••••$last4';
}

