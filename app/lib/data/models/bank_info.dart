import 'package:flutter/painting.dart';

enum BankGroup {
  publicSector('Public sector banks'),
  privateSector('Private sector banks'),
  smallFinance('Small finance banks'),
  payments('Payments banks'),
  foreign('Foreign banks'),
  wallet('Wallets & UPI apps');

  final String label;
  const BankGroup(this.label);
}

/// A bank or wallet the user can pick when adding an account.
class BankInfo {
  final String id;
  final String name;

  /// Short label shown in the monogram when there is no logo.
  final String shortName;
  final BankGroup group;
  final Color brandColor;

  /// Bundled logo, or null to fall back to a monogram.
  final String? logoAsset;

  const BankInfo({
    required this.id,
    required this.name,
    required this.shortName,
    required this.group,
    required this.brandColor,
    this.logoAsset,
  });

  bool get isWallet => group == BankGroup.wallet;
}
