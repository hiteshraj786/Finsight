import 'package:drift/drift.dart';

import '../models/parsed_transaction.dart';
import '../models/transaction_status.dart';
import '../models/transaction_type.dart';
import '../services/sms_categorizer.dart';
import 'database.dart';

class ScanInsertResult {
  final int inserted;
  final int alreadyExisting;

  const ScanInsertResult({
    required this.inserted,
    required this.alreadyExisting,
  });
}

class TransactionRepository {
  final AppDatabase _db;
  final SmsCategorizer _defaultCategorizer;

  TransactionRepository({
    AppDatabase? db,
    SmsCategorizer defaultCategorizer = const SmsCategorizer(),
  }) : _db = db ?? AppDatabase(),
       _defaultCategorizer = defaultCategorizer;

  AppDatabase get db => _db;

  static String normalizeParty(String party) {
    return party
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String computeDedupeKey(ParsedTransaction tx) {
    final sender = (tx.sender ?? 'Unknown').trim();
    if (tx.reference != null && tx.reference!.trim().isNotEmpty) {
      return 'ref:$sender:${tx.reference!.trim()}';
    }
    final dateUtc = tx.date.toUtc();
    final dayKey =
        '${dateUtc.year}-${dateUtc.month.toString().padLeft(2, '0')}-${dateUtc.day.toString().padLeft(2, '0')}';
    final account = (tx.accountLast4 ?? '').trim();
    final partyLower = tx.party.trim().toLowerCase();
    return 'fp:${tx.amountPaise}:${tx.type.name}:$account:$partyLower:$dayKey';
  }

  Future<String> suggestCategory(String party) async {
    final norm = normalizeParty(party);
    if (norm.isEmpty) return 'Uncategorized';

    // 1. User rule exact normalized match
    final exactRule = await (_db.select(
      _db.merchantRules,
    )..where((r) => r.normalizedParty.equals(norm))).getSingleOrNull();
    if (exactRule != null) {
      return exactRule.category;
    }

    // 2. User rule contains match (longest user rule wins)
    final allUserRules = await _db.select(_db.merchantRules).get();
    MerchantRule? bestRule;
    int bestRuleLength = 0;
    for (final rule in allUserRules) {
      if (norm.contains(rule.normalizedParty) ||
          rule.normalizedParty.contains(norm)) {
        if (rule.normalizedParty.length > bestRuleLength) {
          bestRuleLength = rule.normalizedParty.length;
          bestRule = rule;
        }
      }
    }
    if (bestRule != null) {
      return bestRule.category;
    }

    // 3. Default rules in category_rules.dart (longest-keyword wins)
    final defaultCat = _defaultCategorizer.categorize(party);
    if (defaultCat != 'Uncategorized') {
      return defaultCat;
    }

    // 4. Fallback: Uncategorized
    return 'Uncategorized';
  }

  Future<void> saveMerchantRule(
    String party,
    String category, {
    bool applyToPast = false,
  }) async {
    final norm = normalizeParty(party);
    if (norm.isEmpty) return;

    final existing = await (_db.select(
      _db.merchantRules,
    )..where((r) => r.normalizedParty.equals(norm))).getSingleOrNull();

    if (existing != null) {
      await (_db.update(
        _db.merchantRules,
      )..where((r) => r.normalizedParty.equals(norm))).write(
        MerchantRulesCompanion(
          category: Value(category),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
    } else {
      await _db
          .into(_db.merchantRules)
          .insert(
            MerchantRulesCompanion.insert(
              normalizedParty: norm,
              category: category,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
    }

    if (applyToPast) {
      await (_db.update(_db.transactions)..where(
            (t) =>
                t.normalizedParty.equals(norm) &
                t.categorySource.equals('auto'),
          ))
          .write(TransactionsCompanion(category: Value(category)));
    }
  }

  Future<ScanInsertResult> insertNewFromScan(
    List<ParsedTransaction> list,
  ) async {
    int insertedCount = 0;
    int existingCount = 0;

    await _db.transaction(() async {
      for (final tx in list) {
        final key = computeDedupeKey(tx);
        final existing = await (_db.select(
          _db.transactions,
        )..where((t) => t.dedupeKey.equals(key))).getSingleOrNull();

        if (existing != null) {
          existingCount++;
        } else {
          final norm = normalizeParty(tx.party);
          // Suggest category using learned user rules and default rules
          final resolvedCategory = await suggestCategory(tx.party);
          final finalCategory =
              (tx.category != 'Uncategorized' && tx.category.isNotEmpty)
              ? (resolvedCategory != 'Uncategorized'
                    ? resolvedCategory
                    : tx.category)
              : resolvedCategory;

          await _db
              .into(_db.transactions)
              .insert(
                TransactionsCompanion.insert(
                  amountPaise: tx.amountPaise,
                  type: tx.type.name,
                  party: tx.party,
                  category: finalCategory,
                  accountLast4: Value(tx.accountLast4),
                  reference: Value(tx.reference),
                  date: tx.date.toUtc(),
                  status: tx.status.name,
                  lowConfidence: Value(tx.lowConfidence),
                  confidenceReason: Value(tx.confidenceReason),
                  senderId: (tx.sender ?? 'Unknown').trim(),
                  dedupeKey: key,
                  createdAt: DateTime.now().toUtc(),
                  normalizedParty: Value(norm),
                  categorySource: const Value('auto'),
                ),
                mode: InsertMode.insertOrIgnore,
              );
          insertedCount++;
        }
      }
    });

    return ScanInsertResult(
      inserted: insertedCount,
      alreadyExisting: existingCount,
    );
  }

  Stream<List<ParsedTransaction>> watchAll({
    TransactionStatus? statusFilter,
    bool hideLowConfidence = false,
  }) {
    final query = _db.select(_db.transactions);

    query.where((t) {
      Expression<bool> predicate = const Constant(true);
      if (statusFilter != null) {
        predicate = predicate & t.status.equals(statusFilter.name);
      }
      if (hideLowConfidence) {
        predicate = predicate & t.lowConfidence.equals(false);
      }
      return predicate;
    });

    query.orderBy([
      (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
    ]);

    return query.watch().map((rows) => rows.map(_rowToModel).toList());
  }

  Future<List<ParsedTransaction>> getAll() async {
    final rows =
        await (_db.select(_db.transactions)..orderBy([
              (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            ]))
            .get();
    return rows.map(_rowToModel).toList();
  }

  Future<void> updateStatus(int id, TransactionStatus status) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(status: Value(status.name)),
    );
  }

  Future<void> updatePartyAndCategory(
    int id, {
    String? party,
    String? category,
    bool applyToPast = false,
  }) async {
    final current = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    final effectiveParty = party ?? current?.party ?? '';
    final effectiveCategory = category ?? current?.category ?? 'Uncategorized';
    final norm = normalizeParty(effectiveParty);

    final companion = TransactionsCompanion(
      party: party != null ? Value(party) : const Value.absent(),
      category: category != null ? Value(category) : const Value.absent(),
      normalizedParty: Value(norm),
      categorySource: const Value('user'),
    );
    await (_db.update(
      _db.transactions,
    )..where((t) => t.id.equals(id))).write(companion);

    if (effectiveCategory.isNotEmpty && effectiveCategory != 'Uncategorized') {
      await saveMerchantRule(
        effectiveParty,
        effectiveCategory,
        applyToPast: applyToPast,
      );
    }
  }

  Future<void> confirmAllVisible(List<int> ids) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.transactions)..where((t) => t.id.isIn(ids))).write(
      TransactionsCompanion(status: Value(TransactionStatus.confirmed.name)),
    );
  }

  Future<void> deleteAll() async {
    await _db.delete(_db.transactions).go();
    await _db.delete(_db.merchantRules).go();
    await _db.delete(_db.appStates).go();
  }

  Future<int?> getLastCheckedSmsTimestamp() async {
    final row = await (_db.select(
      _db.appStates,
    )..where((s) => s.key.equals('lastCheckedSmsTimestamp'))).getSingleOrNull();
    if (row?.value != null) {
      return int.tryParse(row!.value!);
    }
    return null;
  }

  Future<void> setLastCheckedSmsTimestamp(int timestampMillis) async {
    await _db
        .into(_db.appStates)
        .insertOnConflictUpdate(
          AppStatesCompanion.insert(
            key: 'lastCheckedSmsTimestamp',
            value: Value(timestampMillis.toString()),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  ParsedTransaction _rowToModel(Transaction row) {
    final type = row.type == TransactionType.credit.name
        ? TransactionType.credit
        : TransactionType.debit;

    TransactionStatus status = TransactionStatus.pending;
    if (row.status == TransactionStatus.confirmed.name) {
      status = TransactionStatus.confirmed;
    } else if (row.status == TransactionStatus.ignored.name) {
      status = TransactionStatus.ignored;
    }

    return ParsedTransaction(
      id: row.id,
      amountPaise: row.amountPaise,
      type: type,
      party: row.party,
      category: row.category,
      accountLast4: row.accountLast4,
      reference: row.reference,
      date: row.date.toLocal(),
      sender: row.senderId,
      matchedPhrase: null,
      lowConfidence: row.lowConfidence,
      confidenceReason: row.confidenceReason,
      status: status,
      categorySource: row.categorySource,
    );
  }
}
