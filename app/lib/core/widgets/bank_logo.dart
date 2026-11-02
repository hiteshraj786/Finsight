import 'package:flutter/material.dart';

import '../../data/catalogs/bank_lookup.dart';
import '../../data/models/bank_info.dart';

/// A bank's logo on a white rounded tile, or a coloured monogram when no logo
/// is bundled. Pass either [bank] or [providerName].
class BankLogo extends StatelessWidget {
  final BankInfo? bank;
  final String? providerName;
  final double size;

  /// Shown when the provider is not in the catalog.
  final IconData fallbackIcon;

  const BankLogo({
    super.key,
    this.bank,
    this.providerName,
    this.size = 44,
    this.fallbackIcon = Icons.account_balance_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final info = bank ?? findBank(providerName);
    final radius = BorderRadius.circular(size * 0.28);
    final logo = info?.logoAsset;

    if (logo != null) {
      return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: Image.asset(
          logo,
          fit: BoxFit.contain,
          // Decode at display size instead of full resolution.
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
          errorBuilder: (_, _, _) => _Monogram(info: info, size: size),
        ),
      );
    }
    if (info != null) {
      return ClipRRect(
        borderRadius: radius,
        child: _Monogram(info: info, size: size),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: radius,
      ),
      child: Icon(fallbackIcon, size: size * 0.5, color: scheme.primary),
    );
  }
}

class _Monogram extends StatelessWidget {
  final BankInfo? info;
  final double size;

  const _Monogram({required this.info, required this.size});

  @override
  Widget build(BuildContext context) {
    final label = info?.shortName ?? '?';
    return Container(
      width: size,
      height: size,
      color: info?.brandColor ?? Colors.grey,
      alignment: Alignment.center,
      padding: EdgeInsets.all(size * 0.08),
      child: FittedBox(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
