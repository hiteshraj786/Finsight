import 'package:drift/drift.dart';

import '../models/category_definition.dart';
import '../models/parsed_transaction.dart';
import '../models/payment_method.dart';
import '../models/transaction_status.dart';
import '../models/transaction_type.dart';
import '../local/app_database.dart';

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

  TransactionRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

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

    // 3. Category keywords stored in the database: the built-in ones (which
    //    the user may have edited) and the user's own. Longest keyword wins.
    final keywordCat = await _matchCategoryKeywords(party);
    if (keywordCat != null) {
      return keywordCat;
    }

    // 4. Fallback: Uncategorized
    return 'Uncategorized';
  }

  Future<String?> _matchCategoryKeywords(String party) async {
    final lowerParty = party.toLowerCase();
    final categories = await (_db.select(
      _db.customCategories,
    )..orderBy([(c) => OrderingTerm(expression: c.id)])).get();
    String? bestCategory;
    int bestLength = 0;
    for (final category in categories) {
      for (final keyword in CategoryDefinition.parseKeywords(category.keywords)) {
        // `>=`: on a tie the newer category (higher id) wins, so a keyword
        // the user adds overrides the same built-in one.
        if (lowerParty.contains(keyword) && keyword.length >= bestLength) {
          bestLength = keyword.length;
          bestCategory = category.name;
        }
      }
    }
    return bestCategory;
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
          // A category the user picked (manual entry) is kept as is.
          final userChose = tx.categorySource == 'user' &&
              tx.category.isNotEmpty;
          final resolvedCategory = userChose
              ? tx.category
              : await suggestCategory(tx.party);
          // The parser's guess uses the original built-in keywords, which
          // the user may have edited or deleted, so only the database-backed
          // suggestion counts.
          final finalCategory = userChose ? tx.category : resolvedCategory;

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
                  categorySource: Value(tx.categorySource),
                  paymentMethod: Value(tx.paymentMethod.name),
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

  Future<ParsedTransaction?> findById(int id) async {
    final row = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _rowToModel(row);
  }

  /// Re-runs watch queries after another connection (the background SMS
  /// handler or the payment popup) changed the data.
  void notifyExternalChanges() {
    _db.markTablesUpdated({_db.transactions});
  }

  Future<ParsedTransaction?> findByDedupeKey(String key) async {
    final row = await (_db.select(
      _db.transactions,
    )..where((t) => t.dedupeKey.equals(key))).getSingleOrNull();
    return row == null ? null : _rowToModel(row);
  }

  Future<void> updatePaymentMethod(int id, PaymentMethod method) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(paymentMethod: Value(method.name)),
    );
  }

  /// Fills in the payment method of stored transactions that do not have one
  /// yet, matching freshly parsed SMS by their duplicate-check key. Returns
  /// how many rows were updated.
  Future<int> fillMissingPaymentMethods(List<ParsedTransaction> parsed) async {
    var updated = 0;
    await _db.transaction(() async {
      for (final tx in parsed) {
        if (tx.paymentMethod == PaymentMethod.unknown) continue;
        updated += await (_db.update(_db.transactions)..where(
              (t) =>
                  t.dedupeKey.equals(computeDedupeKey(tx)) &
                  t.paymentMethod.equals(PaymentMethod.unknown.name),
            ))
            .write(TransactionsCompanion(paymentMethod: Value(tx.paymentMethod.name)));
      }
    });
    return updated;
  }

  Future<String?> getAppState(String key) async {
    final row = await (_db.select(
      _db.appStates,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setAppState(String key, String value) async {
    await _db
        .into(_db.appStates)
        .insertOnConflictUpdate(
          AppStatesCompanion.insert(
            key: key,
            value: Value(value),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
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

  /// Deletes every transaction but keeps categories, learned merchant rules
  /// and the sync position, so "Scan SMS inbox" can import them again with
  /// the same categories while automatic sync does not re-add them silently.
  /// Returns how many were deleted.
  Future<int> deleteAllTransactions() => _db.delete(_db.transactions).go();

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
      paymentMethod: PaymentMethod.fromName(row.paymentMethod),
    );
  }
}
