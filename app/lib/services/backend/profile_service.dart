import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_service.dart';
import '../preferences/currency_service.dart';
import '../preferences/language_service.dart';

class ProfileService {
  ProfileService._();

  static SupabaseClient get _client => Supabase.instance.client;
  static const _preferencesPrefix = 'finsight_profile_preferences_';
  static const _displayNamePrefix = 'finsight_profile_display_name_';

  static Future<String?> _cachedDisplayName(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_displayNamePrefix$userId')?.trim();
  }

  static Future<void> _cacheDisplayName(String userId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_displayNamePrefix$userId', name);
  }

  static Future<ProfilePreferences> _cachedPreferences(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_preferencesPrefix$userId');
    if (raw == null) return const ProfilePreferences();
    try {
      return ProfilePreferences.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const ProfilePreferences();
    }
  }

  static Future<void> _cachePreferences(
    String userId,
    ProfilePreferences preferences,
  ) async {
    final store = await SharedPreferences.getInstance();
    await store.setString(
      '$_preferencesPrefix$userId',
      jsonEncode(preferences.toJson()),
    );
  }

  static Future<UserProfile> load() async {
    final user = AuthService.currentUser;
    if (user == null) throw const ProfileException('Your session has expired.');
    final cached = await _cachedPreferences(user.id);
    final store = await SharedPreferences.getInstance();
    final hasCachedPreferences =
        store.getString('$_preferencesPrefix${user.id}') != null;
    final cachedName = await _cachedDisplayName(user.id);
    final authName = (user.userMetadata?['full_name'] as String? ?? '').trim();
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      final data = Map<String, dynamic>.from(row ?? {});
      final hasRemotePreferences = data.containsKey('preferred_currency');
      final profile = UserProfile.fromJson(
        {
          ...(hasCachedPreferences
              ? {...data, ...cached.toJson()}
              : hasRemotePreferences
              ? data
              : {...data, ...cached.toJson()}),
          // Auth is the canonical source for a display name. The device cache
          // lets the new name appear immediately if a legacy profiles row
          // cannot be updated yet.
          'full_name': cachedName?.isNotEmpty == true
              ? cachedName
              : authName.isNotEmpty
              ? authName
              : data['full_name'],
        },
        fallbackEmail: user.email ?? '',
      );
      await _cachePreferences(user.id, profile.preferences);
      CurrencyService.setCurrency(profile.preferences.currency);
      LanguageService.setLanguage(profile.preferences.language);
      if (profile.name.isNotEmpty) {
        await _cacheDisplayName(user.id, profile.name);
      }
      return profile;
    } catch (_) {
      // Profile settings still work on this device when a database migration
      // is pending or connectivity is temporarily unavailable.
      CurrencyService.setCurrency(cached.currency);
      LanguageService.setLanguage(cached.language);
      return UserProfile(
        name: cachedName?.isNotEmpty == true ? cachedName! : authName,
        email: user.email ?? '',
        preferences: cached,
      );
    }
  }

  static Future<void> updateName(String name) async {
    final user = AuthService.currentUser;
    if (user == null) throw const ProfileException('Your session has expired.');
    final cleanName = name.trim();
    if (cleanName.isEmpty)
      throw const ProfileException('Enter a name to continue.');
    // Save the user's requested value first. This prevents a stale/missing
    // legacy profile row from making a successful edit look like a failure.
    await _cacheDisplayName(user.id, cleanName);
    try {
      await _client.auth.updateUser(
        UserAttributes(data: {'full_name': cleanName}),
      );
    } catch (_) {
      // Older projects can have an Auth configuration that rejects metadata
      // edits. The profile table remains a valid sync target in that case.
    }
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'full_name': cleanName,
      });
    } catch (_) {
      // The locally saved value is retried when the profile is next loaded.
    }
  }

  static Future<void> updatePreferences(ProfilePreferences preferences) async {
    final user = AuthService.currentUser;
    if (user == null) throw const ProfileException('Your session has expired.');
    await _cachePreferences(user.id, preferences);
    CurrencyService.setCurrency(preferences.currency);
    LanguageService.setLanguage(preferences.language);
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        ...preferences.toJson(),
      });
    } catch (_) {
      // The local copy is deliberate: the UI remains usable before the
      // profile-preferences migration is pushed and sync resumes next time.
    }
  }

  /// Saves only the theme, keeping the user's other preferences. Does nothing
  /// when signed out; the device-level copy in [AppTheme] still applies.
  static Future<void> updateTheme(String theme) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final current = await _cachedPreferences(user.id);
    await updatePreferences(current.copyWith(theme: theme));
  }

  static Future<void> exportData({
    required ExportScope scope,
    required ExportRange range,
    required ExportFormat format,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw const ProfileException('Your session has expired.');
    try {
      final now = DateTime.now().toUtc();
      final startedAt = range.startDate(now);
      final accountsFuture = _client
          .from('finance_accounts')
          .select(
            'provider_name, masked_account_number, account_type, currency, latest_balance, is_active, created_at',
          )
          .eq('is_active', true);
      final transactionsFuture = _client
          .from('finance_transactions')
          .select(
            'amount, direction, merchant, category, occurred_at, source, account_id',
          )
          .gte('occurred_at', startedAt.toIso8601String())
          .order('occurred_at', ascending: false);
      final data = await Future.wait<dynamic>([
        accountsFuture,
        transactionsFuture,
      ]);
      final accounts = List<Map<String, dynamic>>.from(
        (data[0] as List).map((row) => Map<String, dynamic>.from(row as Map)),
      );
      final transactions = List<Map<String, dynamic>>.from(
        (data[1] as List).map((row) => Map<String, dynamic>.from(row as Map)),
      );
      final output = _encodeExport(scope, format, accounts, transactions);
      final directory = await getTemporaryDirectory();
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final file = File(
        '${directory.path}${Platform.pathSeparator}finsight-export-$stamp.${format.extension}',
      );
      await file.writeAsString(output, flush: true);
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'FinSight financial export');
    } on PostgrestException {
      throw const ProfileException(
        'Unable to prepare your export. Please try again.',
      );
    } on FileSystemException {
      throw const ProfileException(
        'Unable to create the export file on this device.',
      );
    }
  }

  static String _encodeExport(
    ExportScope scope,
    ExportFormat format,
    List<Map<String, dynamic>> accounts,
    List<Map<String, dynamic>> transactions,
  ) {
    final selected = <String, dynamic>{
      if (scope != ExportScope.transactions) 'accounts': accounts,
      if (scope != ExportScope.accounts) 'transactions': transactions,
    };
    if (format == ExportFormat.json)
      return const JsonEncoder.withIndent('  ').convert(selected);

    final lines = <String>[];
    if (scope != ExportScope.transactions) {
      lines.add('Accounts');
      lines.add('Provider,Masked number,Type,Currency,Balance,Active,Created');
      for (final row in accounts) {
        lines.add(
          _csv([
            row['provider_name'],
            row['masked_account_number'],
            row['account_type'],
            row['currency'],
            row['latest_balance'],
            row['is_active'],
            row['created_at'],
          ]),
        );
      }
    }
    if (scope == ExportScope.all) lines.add('');
    if (scope != ExportScope.accounts) {
      lines.add('Transactions');
      lines.add(
        'Amount,Direction,Merchant,Category,Occurred at,Source,Account ID',
      );
      for (final row in transactions) {
        lines.add(
          _csv([
            row['amount'],
            row['direction'],
            row['merchant'],
            row['category'],
            row['occurred_at'],
            row['source'],
            row['account_id'],
          ]),
        );
      }
    }
    return lines.join('\n');
  }

  static String _csv(List<dynamic> fields) => fields
      .map((value) => '"${(value ?? '').toString().replaceAll('"', '""')}"')
      .join(',');
}

class UserProfile {
  final String name;
  final String email;
  final ProfilePreferences preferences;

  const UserProfile({
    required this.name,
    required this.email,
    required this.preferences,
  });

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    required String fallbackEmail,
  }) => UserProfile(
    name: (json['full_name'] as String? ?? '').trim(),
    email: fallbackEmail,
    preferences: ProfilePreferences.fromJson(json),
  );

  String get displayName => name.isEmpty ? 'FinSight user' : name;
  String get initials => displayName
      .split(RegExp(r'\s+'))
      .take(2)
      .map((word) => word.isEmpty ? '' : word[0].toUpperCase())
      .join();
}

class ProfilePreferences {
  final String currency;
  final String language;
  final String theme;
  final String securityMethod;
  final bool expenseAlerts;
  final bool budgetAlerts;
  final bool tips;

  const ProfilePreferences({
    this.currency = 'INR',
    this.language = 'English (EN)',
    this.theme = 'light',
    this.securityMethod = 'pin',
    this.expenseAlerts = true,
    this.budgetAlerts = true,
    this.tips = false,
  });

  factory ProfilePreferences.fromJson(Map<String, dynamic> json) =>
      ProfilePreferences(
        currency: json['preferred_currency'] as String? ?? 'INR',
        language: json['preferred_language'] as String? ?? 'English (EN)',
        theme: _validTheme(json['theme_preference'] as String?),
        securityMethod: json['security_method'] as String? ?? 'pin',
        expenseAlerts: json['expense_alerts_enabled'] as bool? ?? true,
        budgetAlerts: json['budget_alerts_enabled'] as bool? ?? true,
        tips: json['tips_enabled'] as bool? ?? false,
      );

  ProfilePreferences copyWith({
    String? currency,
    String? language,
    String? theme,
    String? securityMethod,
    bool? expenseAlerts,
    bool? budgetAlerts,
    bool? tips,
  }) => ProfilePreferences(
    currency: currency ?? this.currency,
    language: language ?? this.language,
    theme: theme ?? this.theme,
    securityMethod: securityMethod ?? this.securityMethod,
    expenseAlerts: expenseAlerts ?? this.expenseAlerts,
    budgetAlerts: budgetAlerts ?? this.budgetAlerts,
    tips: tips ?? this.tips,
  );

  Map<String, dynamic> toJson() => {
    'preferred_currency': currency,
    'preferred_language': language,
    'theme_preference': theme,
    'security_method': securityMethod,
    'expense_alerts_enabled': expenseAlerts,
    'budget_alerts_enabled': budgetAlerts,
    'tips_enabled': tips,
  };
}

String _validTheme(String? value) => switch (value) {
  'dark' => 'dark',
  'system' => 'system',
  _ => 'light',
};

enum ExportScope { all, accounts, transactions }

enum ExportRange {
  last30Days,
  last90Days,
  thisYear,
  allTime;

  DateTime startDate(DateTime now) => switch (this) {
    ExportRange.last30Days => now.subtract(const Duration(days: 30)),
    ExportRange.last90Days => now.subtract(const Duration(days: 90)),
    ExportRange.thisYear => DateTime.utc(now.year),
    ExportRange.allTime => DateTime.utc(2000),
  };
}

enum ExportFormat {
  csv,
  json;

  String get extension => this == ExportFormat.csv ? 'csv' : 'json';
}

class ProfileException implements Exception {
  final String message;
  const ProfileException(this.message);
}
