import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/sms/data/transaction_repository.dart';
import '../../features/sms/models/transaction_status.dart';
import '../../features/sms/models/transaction_type.dart';
import 'auth_service.dart';

/// Read and write access to finance records with offline-first local caching.
class FinanceDataService {
  FinanceDataService._();

  static SupabaseClient get _client => Supabase.instance.client;
  static const _accountsPrefix = 'finsight_finance_accounts_';

  static String _generateUuid() {
    final rnd = math.Random();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // RFC4122 version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).toList();
    return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-${hex.sublist(10, 16).join()}';
  }

  static Future<List<FinanceAccount>> _cachedAccounts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_accountsPrefix$userId');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (item) =>
                FinanceAccount.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _cacheAccounts(
    String userId,
    List<FinanceAccount> accounts,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = accounts.map((a) => a.toJson()).toList();
    await prefs.setString('$_accountsPrefix$userId', jsonEncode(jsonList));
  }

  static Future<List<FinanceAccount>> getCachedAccounts([String? userId]) async {
    final uid = userId ?? AuthService.currentUser?.id ?? 'local_user';
    return _cachedAccounts(uid);
  }

  static Future<FinanceDashboardData> loadDashboard() async {
    final user = AuthService.currentUser;
    final userId = user?.id ?? 'local_user';
    final cachedAccounts = await _cachedAccounts(userId);

    // Load local SMS and manual transactions from Drift SQLite
    List<FinanceTransaction> localTransactions = [];
    try {
      final repo = TransactionRepository();
      final localTx = await repo.getAll();
      localTransactions = localTx
          .where((t) => t.status != TransactionStatus.ignored)
          .map((tx) => FinanceTransaction(
                id: tx.id?.toString() ?? 'tx_${tx.date.millisecondsSinceEpoch}',
                amount: tx.amountPaise / 100.0,
                direction: tx.type == TransactionType.credit
                    ? TransactionDirection.credit
                    : TransactionDirection.debit,
                merchant: tx.party.isEmpty ? 'Unknown' : tx.party,
                category: tx.category,
                occurredAt: tx.date,
              ))
          .toList();
    } catch (e) {
      debugPrint('Local transactions fetch error: $e');
    }

    if (user != null && AuthService.isInitialized) {
      try {
        final results = await Future.wait<dynamic>([
          _client
              .from('profiles')
              .select('full_name')
              .eq('id', user.id)
              .maybeSingle(),
          _client
              .from('finance_accounts')
              .select(
                'id, provider_name, masked_account_number, account_type, currency, latest_balance, balance_updated_at, is_active',
              )
              .eq('is_active', true)
              .order('balance_updated_at', ascending: false),
          _client
              .from('finance_transactions')
              .select('id, amount, direction, merchant, category, occurred_at')
              .order('occurred_at', ascending: false)
              .limit(20),
        ]);
        final profile = results[0] as Map<String, dynamic>?;
        final accounts = (results[1] as List<dynamic>)
            .map(
              (row) =>
                  FinanceAccount.fromJson(Map<String, dynamic>.from(row as Map)),
            )
            .toList();
        final remoteTransactions = (results[2] as List<dynamic>)
            .map(
              (row) => FinanceTransaction.fromJson(
                Map<String, dynamic>.from(row as Map),
              ),
            )
            .toList();

        final map = <String, FinanceAccount>{};
        for (final a in cachedAccounts) {
          map[a.id] = a;
        }
        for (final a in accounts) {
          map[a.id] = a;
        }
        final merged = map.values.toList();
        await _cacheAccounts(userId, merged);

        // Merge remote and local transactions
        final txMap = <String, FinanceTransaction>{};
        for (final t in localTransactions) {
          txMap[t.id] = t;
        }
        for (final t in remoteTransactions) {
          txMap[t.id] = t;
        }
        final mergedTransactions = txMap.values.toList();
        mergedTransactions.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

        return FinanceDashboardData(
          firstName: _firstName(profile?['full_name'] as String?),
          accounts: merged,
          transactions: mergedTransactions,
        );
      } catch (e) {
        debugPrint('Dashboard Supabase fetch failed: $e, using local cache.');
      }
    }

    final cachedName = user?.userMetadata?['full_name'] as String?;
    localTransactions.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return FinanceDashboardData(
      firstName: _firstName(cachedName),
      accounts: cachedAccounts,
      transactions: localTransactions,
    );
  }

  static Future<List<FinanceAccount>> loadAccounts() async {
    final user = AuthService.currentUser;
    final userId = user?.id ?? 'local_user';
    final cached = await _cachedAccounts(userId);

    if (user != null && AuthService.isInitialized) {
      try {
        final rows = await _client
            .from('finance_accounts')
            .select(
              'id, provider_name, masked_account_number, account_type, currency, latest_balance, balance_updated_at, is_active',
            )
            .eq('is_active', true)
            .order('created_at');
        final remote = (rows as List<dynamic>)
            .map(
              (row) =>
                  FinanceAccount.fromJson(Map<String, dynamic>.from(row as Map)),
            )
            .toList();

        final map = <String, FinanceAccount>{};
        for (final a in cached) {
          map[a.id] = a;
        }
        for (final a in remote) {
          map[a.id] = a;
        }
        final merged = map.values.toList();
        await _cacheAccounts(userId, merged);
        return merged;
      } catch (e) {
        debugPrint('Accounts Supabase fetch failed: $e, returning local cache.');
        return cached;
      }
    }
    return cached;
  }

  static Future<FinanceAccount> loadAccount(String accountId) async {
    final user = AuthService.currentUser;
    final userId = user?.id ?? 'local_user';
    final cached = await _cachedAccounts(userId);
    final match = cached.where((a) => a.id == accountId).firstOrNull;
    if (match != null) return match;

    if (user != null && AuthService.isInitialized) {
      try {
        final row = await _client
            .from('finance_accounts')
            .select(
              'id, provider_name, masked_account_number, account_type, currency, latest_balance, balance_updated_at, is_active',
            )
            .eq('id', accountId)
            .eq('is_active', true)
            .single();
        return FinanceAccount.fromJson(Map<String, dynamic>.from(row));
      } catch (_) {}
    }
    throw const FinanceDataException('This account is unavailable.');
  }

  static Future<List<FinanceTransaction>> loadAccountTransactions(
    String accountId,
  ) async {
    final user = AuthService.currentUser;
    if (user != null && AuthService.isInitialized) {
      try {
        final rows = await _client
            .from('finance_transactions')
            .select('id, amount, direction, merchant, category, occurred_at')
            .eq('account_id', accountId)
            .order('occurred_at', ascending: false);
        return (rows as List<dynamic>)
            .map(
              (row) => FinanceTransaction.fromJson(
                Map<String, dynamic>.from(row as Map),
              ),
            )
            .toList();
      } catch (_) {}
    }
    return [];
  }

  static Future<void> saveAccount(
    AccountDraft draft, {
    String? accountId,
  }) async {
    final user = AuthService.currentUser;
    final userId = user?.id ?? 'local_user';
    final targetId = accountId ?? _generateUuid();
    final values = draft.toJson();

    final newAccount = FinanceAccount(
      id: targetId,
      providerName: draft.providerName,
      maskedAccountNumber: values['masked_account_number'] as String,
      accountType: draft.accountType,
      currency: draft.currency,
      latestBalance: draft.balance,
      balanceUpdatedAt: DateTime.now(),
    );

    // Save locally first so the account is NEVER lost
    final currentAccounts = await _cachedAccounts(userId);
    final updatedList = List<FinanceAccount>.from(currentAccounts);
    final existingIndex = updatedList.indexWhere((a) => a.id == targetId);
    if (existingIndex >= 0) {
      updatedList[existingIndex] = newAccount;
    } else {
      updatedList.add(newAccount);
    }
    await _cacheAccounts(userId, updatedList);

    // Sync to Supabase if authenticated
    if (user != null && AuthService.isInitialized) {
      try {
        if (accountId == null) {
          await _client.from('finance_accounts').insert({
            ...values,
            'id': targetId,
            'user_id': user.id,
          });
        } else {
          await _client
              .from('finance_accounts')
              .update(values)
              .eq('id', accountId);
        }
      } on PostgrestException catch (e) {
        debugPrint('Supabase finance_accounts sync warning: ${e.message}');
      } catch (e) {
        debugPrint('Supabase finance_accounts sync error: $e');
      }
    }
  }

  static Future<void> archiveAccount(String accountId) async {
    final user = AuthService.currentUser;
    final userId = user?.id ?? 'local_user';
    final cached = await _cachedAccounts(userId);
    final updated = cached.where((a) => a.id != accountId).toList();
    await _cacheAccounts(userId, updated);

    if (user != null && AuthService.isInitialized) {
      try {
        await _client
            .from('finance_accounts')
            .update({'is_active': false})
            .eq('id', accountId);
      } catch (_) {}
    }
  }

  static String _firstName(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'there' : trimmed.split(RegExp(r'\s+')).first;
  }
}

class FinanceDashboardData {
  final String firstName;
  final List<FinanceAccount> accounts;
  final List<FinanceTransaction> transactions;

  const FinanceDashboardData({
    required this.firstName,
    required this.accounts,
    required this.transactions,
  });

  double get usableBalance => accounts
      .where((account) => account.isDepositAccount || account.accountType == 'wallet')
      .fold<double>(
        0,
        (total, account) => total + (account.latestBalance ?? 0),
      );

  double get creditCardDue => accounts
      .where((account) => account.accountType == 'credit_card')
      .fold<double>(
        0,
        (total, account) => total + (account.latestBalance ?? 0),
      );

  double get monthSpend {
    final now = DateTime.now();
    return transactions
        .where(
          (transaction) =>
              transaction.direction == TransactionDirection.debit &&
              transaction.occurredAt.year == now.year &&
              transaction.occurredAt.month == now.month,
        )
        .fold<double>(0, (total, transaction) => total + transaction.amount);
  }
}

class FinanceAccount {
  final String id;
  final String providerName;
  final String maskedAccountNumber;
  final String accountType;
  final String currency;
  final double? latestBalance;
  final DateTime? balanceUpdatedAt;

  const FinanceAccount({
    required this.id,
    required this.providerName,
    required this.maskedAccountNumber,
    required this.accountType,
    required this.currency,
    required this.latestBalance,
    required this.balanceUpdatedAt,
  });

  bool get isDepositAccount =>
      accountType == 'savings' || accountType == 'current';
  bool get isCreditCard => accountType == 'credit_card';

  String get displayType => switch (accountType) {
    'credit_card' => 'Credit card',
    'current' => 'Current account',
    'savings' => 'Savings account',
    'loan' => 'Loan',
    'wallet' => 'Wallet',
    _ => 'Account',
  };

  factory FinanceAccount.fromJson(Map<String, dynamic> json) => FinanceAccount(
    id: json['id'] as String? ?? 'acc_${DateTime.now().millisecondsSinceEpoch}',
    providerName: json['provider_name'] as String? ?? 'Bank account',
    maskedAccountNumber: json['masked_account_number'] as String? ?? '••••',
    accountType: json['account_type'] as String? ?? 'other',
    currency: json['currency'] as String? ?? 'INR',
    latestBalance: (json['latest_balance'] as num?)?.toDouble() ?? 0.0,
    balanceUpdatedAt: DateTime.tryParse(
      json['balance_updated_at'] as String? ?? '',
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider_name': providerName,
    'masked_account_number': maskedAccountNumber,
    'account_type': accountType,
    'currency': currency,
    'latest_balance': latestBalance,
    'balance_updated_at': balanceUpdatedAt?.toIso8601String(),
    'is_active': true,
  };
}

class AccountDraft {
  final String providerName;
  final String accountType;
  final String currency;
  final double balance;
  final String maskedAccountNumber;

  const AccountDraft({
    required this.providerName,
    required this.accountType,
    required this.currency,
    required this.balance,
    this.maskedAccountNumber = '••••',
  });

  Map<String, dynamic> toJson() {
    final raw = maskedAccountNumber.trim();
    final formatted = raw.isEmpty || raw == '••••'
        ? '••••'
        : (raw.startsWith('••••') ? raw : '•••• $raw');
    return {
      'provider_name': providerName.trim(),
      'account_type': accountType,
      'currency': currency,
      'latest_balance': balance,
      'balance_updated_at': DateTime.now().toUtc().toIso8601String(),
      'masked_account_number': formatted,
      'is_active': true,
    };
  }
}

enum TransactionDirection { debit, credit }

class FinanceTransaction {
  final String id;
  final double amount;
  final TransactionDirection direction;
  final String merchant;
  final String? category;
  final DateTime occurredAt;

  const FinanceTransaction({
    required this.id,
    required this.amount,
    required this.direction,
    required this.merchant,
    required this.category,
    required this.occurredAt,
  });

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) =>
      FinanceTransaction(
        id: json['id'] as String,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        direction: json['direction'] == 'credit'
            ? TransactionDirection.credit
            : TransactionDirection.debit,
        merchant: json['merchant'] as String? ?? 'Transaction',
        category: json['category'] as String?,
        occurredAt:
            DateTime.tryParse(json['occurred_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class FinanceDataException implements Exception {
  final String message;
  const FinanceDataException(this.message);
}
