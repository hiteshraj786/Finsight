import '../models/bank_info.dart';
import 'indian_banks.dart';

/// Finds the catalog entry for a saved account's provider name, so accounts
/// created before the catalog existed (e.g. "SBI", "HDFC Bank savings")
/// still get a logo.
BankInfo? findBank(String? providerName) {
  final query = providerName?.trim().toLowerCase() ?? '';
  if (query.isEmpty) return null;
  for (final bank in indianBanks) {
    if (bank.name.toLowerCase() == query ||
        bank.shortName.toLowerCase() == query) {
      return bank;
    }
  }
  // Longest bank name contained in the provider name wins, so
  // "Bank of India" does not shadow "Central Bank of India".
  BankInfo? best;
  for (final bank in indianBanks) {
    final name = bank.name.toLowerCase();
    if (query.contains(name) && name.length > (best?.name.length ?? 0)) {
      best = bank;
    }
  }
  if (best != null) return best;
  final firstWord = query.split(RegExp(r'\s+')).first;
  for (final bank in indianBanks) {
    if (bank.shortName.toLowerCase() == firstWord) return bank;
  }
  return null;
}
