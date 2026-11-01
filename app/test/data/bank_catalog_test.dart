import 'dart:io';

import 'package:finsight/data/catalogs/bank_lookup.dart';
import 'package:finsight/data/catalogs/indian_banks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('findBank', () {
    test('matches full names and short names', () {
      expect(findBank('HDFC Bank')?.id, 'hdfc');
      expect(findBank('SBI')?.id, 'sbi');
      expect(findBank('  icici bank ')?.id, 'icici');
    });

    test('prefers the longest contained name', () {
      expect(findBank('Central Bank of India savings')?.id, 'central');
      expect(findBank('Bank of India')?.id, 'boi');
    });

    test('matches a short name at the start of a custom label', () {
      expect(findBank('PNB salary account')?.id, 'pnb');
    });

    test('returns null for unknown or empty providers', () {
      expect(findBank('My piggy bank'), isNull);
      expect(findBank(''), isNull);
      expect(findBank(null), isNull);
    });
  });

  test('bank ids are unique', () {
    final ids = indianBanks.map((b) => b.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every bundled logo exists on disk', () {
    for (final bank in indianBanks.where((b) => b.logoAsset != null)) {
      expect(
        File(bank.logoAsset!).existsSync(),
        isTrue,
        reason: '${bank.name} logo missing: ${bank.logoAsset}',
      );
    }
  });
}
