import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

/// Read-only, authenticated access to finance records.
class FinanceDataService {
  FinanceDataService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<FinanceDashboardData> loadDashboard() async {
    final user = AuthService.currentUser;
    if (user == null) throw const FinanceDataException('Your session has expired.');

    try {
      final results = await Future.wait<dynamic>([
        _client.from('profiles').select('full_name').eq('id', user.id).maybeSingle(),
        _client
            .from('finance_accounts')
            .select('id, provider_name, masked_account_number, account_type, currency, latest_balance, balance_updated_at, is_active')
            .eq('is_active', true)
            .order('balance_updated_at', ascending: false),
        _client
            .from('finance_transactions')
            .select('id, amount, direction, merchant, category, occurred_at')
            .order('occurred_at', ascending: false)
            .limit(10),
      ]);
      final profile = results[0] as Map<String, dynamic>?;
      final accounts = (results[1] as List<dynamic>)
          .map((row) => FinanceAccount.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
      final transactions = (results[2] as List<dynamic>)
          .map((row) => FinanceTransaction.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
      return FinanceDashboardData(
        firstName: _firstName(profile?['full_name'] as String?),
        accounts: accounts,
        transactions: transactions,
      );
    } on PostgrestException {
      throw const FinanceDataException('Unable to load your financial data right now.');
    } catch (error) {
      if (error is FinanceDataException) rethrow;
      throw const FinanceDataException('Unable to load your financial data right now.');
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

  const FinanceDashboardData({required this.firstName, required this.accounts, required this.transactions});

  /// Credit-card balances are deliberately excluded from available cash.
  double get usableBalance => accounts
      .where((account) => account.isDepositAccount)
      .fold<double>(0, (total, account) => total + (account.latestBalance ?? 0));

  double get creditCardDue => accounts
      .where((account) => account.accountType == 'credit_card')
      .fold<double>(0, (total, account) => total + (account.latestBalance ?? 0));

  double get monthSpend {
    final now = DateTime.now();
    return transactions
        .where((transaction) => transaction.direction == TransactionDirection.debit && transaction.occurredAt.year == now.year && transaction.occurredAt.month == now.month)
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

  const FinanceAccount({required this.id, required this.providerName, required this.maskedAccountNumber, required this.accountType, required this.currency, required this.latestBalance, required this.balanceUpdatedAt});

  bool get isDepositAccount => accountType == 'savings' || accountType == 'current';
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
        id: json['id'] as String,
        providerName: json['provider_name'] as String? ?? 'Bank account',
        maskedAccountNumber: json['masked_account_number'] as String? ?? '••••',
        accountType: json['account_type'] as String? ?? 'other',
        currency: json['currency'] as String? ?? 'INR',
        latestBalance: (json['latest_balance'] as num?)?.toDouble(),
        balanceUpdatedAt: DateTime.tryParse(json['balance_updated_at'] as String? ?? ''),
      );
}

enum TransactionDirection { debit, credit }

class FinanceTransaction {
  final String id;
  final double amount;
  final TransactionDirection direction;
  final String merchant;
  final String? category;
  final DateTime occurredAt;

  const FinanceTransaction({required this.id, required this.amount, required this.direction, required this.merchant, required this.category, required this.occurredAt});

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) => FinanceTransaction(
        id: json['id'] as String,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        direction: json['direction'] == 'credit' ? TransactionDirection.credit : TransactionDirection.debit,
        merchant: json['merchant'] as String? ?? 'Transaction',
        category: json['category'] as String?,
        occurredAt: DateTime.tryParse(json['occurred_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class FinanceDataException implements Exception {
  final String message;
  const FinanceDataException(this.message);
}
