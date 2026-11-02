import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/currency_service.dart';
import '../../core/services/finance_data_service.dart';
import '../../core/services/pin_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/language_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bank_logo.dart';
import '../../core/widgets/theme_toggle_button.dart';
import '../../core/widgets/bank_picker_sheet.dart';
import '../insights/data/insight_notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserProfile> _profile;
  String? _displayNameOverride;

  @override
  void initState() {
    super.initState();
    _profile = ProfileService.load();
  }

  Future<void> _reload() async {
    setState(() => _profile = ProfileService.load());
    await _profile;
  }

  Future<void> _editName(UserProfile profile) async {
    final controller = TextEditingController(text: profile.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // The route completes before the closing animation has disposed its
    // TextField. Defer disposal so Cancel cannot hit _dependents.isEmpty.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (result == null) return;
    final cleanName = result.trim();
    if (cleanName.isEmpty) {
      _message('Enter a name to continue.', error: true);
      return;
    }
    if (!mounted) return;
    // Show the saved value immediately instead of waiting for a network round
    // trip or rebuilding the entire profile page.
    setState(() => _displayNameOverride = cleanName);
    try {
      await ProfileService.updateName(cleanName);
    } on ProfileException catch (error) {
      if (mounted) setState(() => _displayNameOverride = null);
      if (mounted) _message(error.message, error: true);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogoutSheet(
        onNo: () => Navigator.pop(context, false),
        onYes: () => Navigator.pop(context, true),
      ),
    );
    if (confirmed != true) return;
    await AuthService.signOut();
    await PinService.clearAll();
    if (mounted)
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  void _message(String value, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value),
          backgroundColor: error ? AppColors.error : AppColors.success,
        ),
      );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: LanguageService.selectedLanguage,
    builder: (context, _, __) => ValueListenableBuilder<String>(
      valueListenable: CurrencyService.selected,
      builder: (context, _, __) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: FutureBuilder<UserProfile>(
            future: _profile,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return _ProfileError(onRetry: _reload);
              final profile = snapshot.data!;
              final displayName = _displayNameOverride ?? profile.displayName;
              final initials = displayName
                  .split(RegExp(r'\s+'))
                  .where((word) => word.isNotEmpty)
                  .take(2)
                  .map((word) => word[0].toUpperCase())
                  .join();
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 38, 20, 110),
                  children: [
                    Row(
                      children: [
                        _Avatar(initials: initials),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Username'.tr(),
                                style: _style(
                                  14,
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                                  FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayName,
                                style: _style(
                                  24,
                                  Theme.of(context).colorScheme.onSurface,
                                  FontWeight.w800,
                                ),
                              ),
                              if (profile.email.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  profile.email,
                                  style: _style(
                                    12,
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                                    FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const ThemeToggleButton(),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          onPressed: () => _editName(profile),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 38),
                    _ProfileMenu(
                      items: [
                        _MenuItem(
                          Icons.account_balance_wallet_outlined,
                          'Account'.tr(),
                          AppColors.primary,
                          () async {
                            await Navigator.pushNamed(context, AppRoutes.accounts);
                            _reload();
                          },
                        ),
                        _MenuItem(
                          Icons.settings_outlined,
                          'Settings'.tr(),
                          AppColors.primary,
                          () async {
                            await Navigator.pushNamed(context, AppRoutes.settings);
                            _reload();
                          },
                        ),
                        _MenuItem(
                          Icons.file_upload_outlined,
                          'Export Data'.tr(),
                          AppColors.primary,
                          () => Navigator.pushNamed(context, AppRoutes.exportData),
                        ),
                        _MenuItem(
                          Icons.logout_rounded,
                          'Logout'.tr(),
                          AppColors.error,
                          _logout,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<FinanceAccount>? _accounts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final cached = await FinanceDataService.getCachedAccounts();
    if (mounted && cached.isNotEmpty) {
      setState(() {
        _accounts = cached;
        _loading = false;
      });
    }
    await _refresh();
  }

  Future<void> _refresh() async {
    try {
      final latest = await FinanceDataService.loadAccounts();
      if (mounted) {
        setState(() {
          _accounts = latest;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: LanguageService.selectedLanguage,
    builder: (context, _, __) => ValueListenableBuilder<String>(
      valueListenable: CurrencyService.selected,
      builder: (context, _, child) => Scaffold(
        appBar: AppBar(title: Text('Account'.tr())),
        body: _loading && _accounts == null
            ? const Center(child: CircularProgressIndicator())
            : _accounts == null
                ? _ProfileError(onRetry: _loadInitial)
                : Builder(
                    builder: (context) {
                      final accounts = _accounts!;
                      final total = accounts
                          .where(
                            (account) =>
                                account.isDepositAccount || account.accountType == 'wallet',
                          )
                          .fold<double>(
                            0,
                            (value, account) => value + (account.latestBalance ?? 0),
                          );
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFA475FF), AppColors.primary],
                                ),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Account Balance'.tr(),
                                    style: _style(15, Colors.white70, FontWeight.w500),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _money(total),
                                    style: _style(38, Colors.white, FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (accounts.isEmpty)
                              _emptyCard(
                                'No accounts yet'.tr(),
                                'Add a bank, wallet, or credit card to start tracking your finances.'.tr(),
                              )
                            else
                              ...accounts.map(
                                (account) => _AccountListTile(
                                  account: account,
                                  onTap: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      AppRoutes.accountDetail,
                                      arguments: account.id,
                                    );
                                    final cached = await FinanceDataService.getCachedAccounts();
                                    if (mounted) setState(() => _accounts = cached);
                                    _refresh();
                                  },
                                ),
                              ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.pushNamed(context, AppRoutes.accountEditor);
                                final cached = await FinanceDataService.getCachedAccounts();
                                if (mounted) {
                                  setState(() {
                                    _accounts = cached;
                                    _loading = false;
                                  });
                                }
                                _refresh();
                              },
                              icon: const Icon(Icons.add),
                              label: Text('Add new account'.tr()),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    ),
  );
}

class AccountEditorScreen extends StatefulWidget {
  final FinanceAccount? account;
  const AccountEditorScreen({super.key, this.account});

  @override
  State<AccountEditorScreen> createState() => _AccountEditorScreenState();
}

class _AccountEditorScreenState extends State<AccountEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late final TextEditingController _maskedNumber;
  late String _type;
  late String _currency;
  bool _saving = false;

  static const _types = {
    'savings': 'Bank / savings',
    'current': 'Current account',
    'wallet': 'Wallet',
    'credit_card': 'Credit card',
    'loan': 'Loan',
    'other': 'Other',
  };
  static const _currencies = ['INR', 'USD', 'EUR', 'GBP', 'IDR', 'JPY'];
  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _name = TextEditingController(text: account?.providerName ?? '');
    _balance = TextEditingController(
      text: account?.latestBalance?.toStringAsFixed(2) ?? '0.00',
    );
    _maskedNumber = TextEditingController(
      text: account?.maskedAccountNumber == '••••'
          ? ''
          : (account?.maskedAccountNumber ?? '').replaceAll(
              RegExp(r'[^0-9]'),
              '',
            ),
    );
    _type = account?.accountType ?? 'savings';
    _currency = account?.currency ?? CurrencyService.current;
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    _maskedNumber.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await FinanceDataService.saveAccount(
        AccountDraft(
          providerName: _name.text,
          accountType: _type,
          currency: _currency,
          balance: double.parse(_balance.text.trim()),
          maskedAccountNumber: _maskedNumber.text,
        ),
        accountId: widget.account?.id,
      );
      if (mounted) Navigator.pop(context, true);
    } on FinanceDataException catch (error) {
      if (mounted) _snack(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _archive() async {
    final confirm = await _confirm(
      context,
      'Remove account?',
      'The account will be hidden, while its transaction history stays preserved.',
    );
    if (confirm != true) return;
    try {
      await FinanceDataService.archiveAccount(widget.account!.id);
      if (mounted) Navigator.pop(context, true);
    } on FinanceDataException catch (error) {
      if (mounted) _snack(context, error.message, error: true);
    }
  }

  Future<void> _pickCatalogProvider() async {
    final selected = await BankPickerSheet.show(
      context,
      selectedName: _name.text.trim(),
    );
    if (selected != null && mounted) {
      setState(() => _name.text = selected.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.account != null;
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          editing ? 'Edit account'.tr() : 'Add new account'.tr(),
          style: _style(18, Colors.white, FontWeight.w700),
        ),
        actions: [
          if (editing)
            IconButton(
              onPressed: _archive,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Form(
                key: _formKey,
                child: IntrinsicHeight(
                  child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Balance'.tr(),
                  style: _style(16, Colors.white70, FontWeight.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                child: Text(
                  _money(
                    double.tryParse(_balance.text) ?? 0,
                    currency: _currency,
                  ),
                  style: _style(48, Colors.white, FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Account name'.tr(),
                        suffixIcon: IconButton(
                          tooltip: 'Select provider'.tr(),
                          onPressed: _pickCatalogProvider,
                          icon: const Icon(Icons.account_balance_outlined),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter an account name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _balance,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(labelText: 'Balance'.tr()),
                      onChanged: (_) => setState(() {}),
                      validator: (value) =>
                          double.tryParse(value ?? '') == null ||
                              double.parse(value!) < 0
                          ? 'Enter a valid balance'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField(
                      value: _type,
                      items: _types.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _type = value!),
                      decoration: InputDecoration(
                        labelText: 'Account type'.tr(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickCatalogProvider,
                      icon: const Icon(Icons.grid_view_rounded, size: 18),
                      label: Text('Choose bank or wallet provider'.tr()),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField(
                      value: _currency,
                      items: _currencies
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _currency = value!),
                      decoration: InputDecoration(labelText: 'Currency'.tr()),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _maskedNumber,
                      decoration: InputDecoration(
                        labelText: 'Last 4 digits (optional)'.tr(),
                      ),
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value != null &&
                              value.trim().isNotEmpty &&
                              !RegExp(r'^\d{4}$').hasMatch(value.trim())
                          ? 'Enter exactly 4 digits'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text('Continue'.tr()),
                    ),
                  ],
                ),
              ),
            ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountDetailScreen extends StatefulWidget {
  final String accountId;
  const AccountDetailScreen({super.key, required this.accountId});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  late Future<_AccountDetail> _detail;

  @override
  void initState() {
    super.initState();
    _detail = _load();
  }

  Future<_AccountDetail> _load() async => _AccountDetail(
    await FinanceDataService.loadAccount(widget.accountId),
    await FinanceDataService.loadAccountTransactions(widget.accountId),
  );
  Future<void> _refresh() async {
    setState(() => _detail = _load());
    await _detail;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detail account')),
    body: FutureBuilder<_AccountDetail>(
      future: _detail,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _ProfileError(onRetry: _refresh);
        final detail = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(child: _AccountIcon(account: detail.account, size: 58)),
              const SizedBox(height: 14),
              Text(
                detail.account.providerName,
                textAlign: TextAlign.center,
                style: _style(24, AppColors.textPrimary, FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                _money(
                  detail.account.latestBalance ?? 0,
                  currency: detail.account.currency,
                ),
                textAlign: TextAlign.center,
                style: _style(34, AppColors.textPrimary, FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${detail.account.displayType} · ${detail.account.maskedAccountNumber}',
                textAlign: TextAlign.center,
                style: _style(13, AppColors.textSecondary, FontWeight.w500),
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AccountEditorScreen(account: detail.account),
                    ),
                  );
                  _refresh();
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit account'),
              ),
              const SizedBox(height: 28),
              Text(
                'Activity',
                style: _style(19, AppColors.textPrimary, FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (detail.transactions.isEmpty)
                _emptyCard(
                  'No transactions yet',
                  'Transactions linked to this account will appear here.',
                )
              else
                ...detail.transactions.map(
                  (transaction) => _ActivityTile(
                    transaction: transaction,
                    currency: detail.account.currency,
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<UserProfile> _profile;
  ProfilePreferences? _visiblePreferences;
  @override
  void initState() {
    super.initState();
    _profile = ProfileService.load();
  }

  Future<void> _refresh() async {
    setState(() {
      _visiblePreferences = null;
      _profile = ProfileService.load();
    });
    await _profile;
  }

  Future<void> _openPreference(
    String route,
    ProfilePreferences preferences,
  ) async {
    final result = await Navigator.pushNamed(
      context,
      route,
      arguments: preferences,
    );
    if (result is ProfilePreferences && mounted) {
      // Do not wait for a new network read. The chosen value is already saved
      // locally and should be visible the instant the picker closes.
      setState(() => _visiblePreferences = result);
    }
  }
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: LanguageService.selectedLanguage,
    builder: (context, _, __) => ValueListenableBuilder<String>(
      valueListenable: CurrencyService.selected,
      builder: (context, _, __) => Scaffold(
        appBar: AppBar(title: Text('Settings'.tr())),
        body: FutureBuilder<UserProfile>(
          future: _profile,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return _ProfileError(onRetry: _refresh);
            final preferences = _visiblePreferences ?? snapshot.data!.preferences;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                _SettingsRow(
                  'Currency'.tr(),
                  preferences.currency,
                  () => _openPreference(AppRoutes.currency, preferences),
                ),
                _SettingsRow(
                  'Language'.tr(),
                  preferences.language,
                  () => _openPreference(AppRoutes.language, preferences),
                ),
                _SettingsRow(
                  'Theme'.tr(),
                  _themeLabel(preferences.theme).tr(),
                  () => _openPreference(AppRoutes.theme, preferences),
                ),
                _SettingsRow(
                  'Security'.tr(),
                  preferences.securityMethod == 'biometric' ? 'Biometric'.tr() : 'PIN'.tr(),
                  () => _openPreference(AppRoutes.security, preferences),
                ),
                _SettingsRow('Change PIN'.tr(), '', () async {
                  await Navigator.pushNamed(
                    context,
                    AppRoutes.setupPin,
                    arguments: true,
                  );
                }),
                _SettingsRow(
                  'Notification'.tr(),
                  '',
                  () => Navigator.pushNamed(
                    context,
                    AppRoutes.notifications,
                    arguments: preferences,
                  ),
                ),
                const SizedBox(height: 28),
                _SettingsRow(
                  'About'.tr(),
                  '',
                  () => Navigator.pushNamed(context, AppRoutes.about),
                ),
                _SettingsRow(
                  'Help'.tr(),
                  '',
                  () => Navigator.pushNamed(context, AppRoutes.help),
                ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

class PreferencePickerScreen extends StatefulWidget {
  final PreferenceKind kind;
  final ProfilePreferences preferences;
  const PreferencePickerScreen({
    super.key,
    required this.kind,
    required this.preferences,
  });
  @override
  State<PreferencePickerScreen> createState() => _PreferencePickerScreenState();
}

class _PreferencePickerScreenState extends State<PreferencePickerScreen> {
  bool _saving = false;
  List<String> get _values => switch (widget.kind) {
    PreferenceKind.currency => const [
      'INR',
      'USD',
      'EUR',
      'IDR',
      'JPY',
      'RUB',
      'KRW',
    ],
    PreferenceKind.language => const [
      'English (EN)',
      'Hindi (HI)',
      'Indonesian (ID)',
      'Arabic (AR)',
      'Chinese (ZH)',
      'French (FR)',
      'German (DE)',
      'Spanish (ES)',
    ],
    PreferenceKind.theme => const ['light', 'dark'],
    PreferenceKind.security => const ['pin', 'biometric'],
  };
  String get _selected => switch (widget.kind) {
    PreferenceKind.currency => widget.preferences.currency,
    PreferenceKind.language => widget.preferences.language,
    PreferenceKind.theme => widget.preferences.theme,
    PreferenceKind.security => widget.preferences.securityMethod,
  };
  String get _title => switch (widget.kind) {
    PreferenceKind.currency => 'Currency',
    PreferenceKind.language => 'Language',
    PreferenceKind.theme => 'Theme',
    PreferenceKind.security => 'Security',
  };

  Future<void> _select(String value) async {
    if (_saving || value == _selected) return;
    if (widget.kind == PreferenceKind.security && value == 'biometric') {
      final available = await BiometricService.isAvailable();
      if (!available) {
        if (mounted)
          _snack(
            context,
            'Biometric unlock is not available on this device.',
            error: true,
          );
        return;
      }
      final verified = await BiometricService.authenticate(
        reason: 'Verify your identity to enable biometric unlock for FinSight',
      );
      if (!verified) {
        if (mounted) {
          _snack(
            context,
            'Biometric verification was not completed. Your PIN is still active.',
            error: true,
          );
        }
        return;
      }
    }
    setState(() => _saving = true);
    final updated = switch (widget.kind) {
      PreferenceKind.currency => widget.preferences.copyWith(currency: value),
      PreferenceKind.language => widget.preferences.copyWith(language: value),
      PreferenceKind.theme => widget.preferences.copyWith(theme: value),
      PreferenceKind.security => widget.preferences.copyWith(
        securityMethod: value,
      ),
    };
    try {
      await ProfileService.updatePreferences(updated);
      if (widget.kind == PreferenceKind.theme) AppTheme.setPreference(value);
      if (widget.kind == PreferenceKind.currency) CurrencyService.setCurrency(value);
      if (widget.kind == PreferenceKind.language) LanguageService.setLanguage(value);
      if (mounted) Navigator.pop(context, updated);
    } on ProfileException catch (error) {
      if (mounted) _snack(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_title)),
    body: ListView.separated(
      itemCount: _values.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final value = _values[index];
        final selected = value == _selected;
        return ListTile(
          title: Text(
            _preferenceLabel(widget.kind, value),
            style: _style(
              16,
              Theme.of(context).colorScheme.onSurface,
              FontWeight.w500,
            ),
          ),
          trailing: selected
              ? const Icon(Icons.check_circle, color: AppColors.primary)
              : null,
          onTap: () => _select(value),
        );
      },
    ),
  );
}

class NotificationSettingsScreen extends StatefulWidget {
  final ProfilePreferences preferences;
  const NotificationSettingsScreen({super.key, required this.preferences});
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late ProfilePreferences _preferences;
  bool _saving = false;
  bool _insightNotifications = false;
  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences;
    InsightNotificationService.isEnabled().then((enabled) {
      if (mounted) setState(() => _insightNotifications = enabled);
    });
  }

  Future<void> _update(ProfilePreferences value) async {
    final previous = _preferences;
    setState(() {
      _preferences = value;
      _saving = true;
    });
    try {
      await ProfileService.updatePreferences(value);
    } on ProfileException catch (error) {
      if (mounted) setState(() => _preferences = previous);
      if (mounted) _snack(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notification')),
    body: Column(
      children: [
        _NotificationTile(
          title: 'Insight notifications',
          subtitle: 'Budget, recurring payment, and unusual transaction alerts',
          value: _insightNotifications,
          enabled: !_saving,
          onChanged: (enabled) async {
            final granted = await InsightNotificationService.setEnabled(enabled);
            if (mounted) setState(() => _insightNotifications = granted && enabled);
          },
        ),
        _NotificationTile(
          title: 'Expense Alert',
          subtitle: 'Get notification about your expenses',
          value: _preferences.expenseAlerts,
          enabled: !_saving,
          onChanged: (value) =>
              _update(_preferences.copyWith(expenseAlerts: value)),
        ),
        _NotificationTile(
          title: 'Budget',
          subtitle: 'Get notification when you’re over your budget limit',
          value: _preferences.budgetAlerts,
          enabled: !_saving,
          onChanged: (value) =>
              _update(_preferences.copyWith(budgetAlerts: value)),
        ),
        _NotificationTile(
          title: 'Tips & Articles',
          subtitle: 'Small and useful pieces of practical financial advice',
          value: _preferences.tips,
          enabled: !_saving,
          onChanged: (value) => _update(_preferences.copyWith(tips: value)),
        ),
      ],
    ),
  );
}

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});
  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  ExportScope _scope = ExportScope.all;
  ExportRange _range = ExportRange.last30Days;
  ExportFormat _format = ExportFormat.csv;
  bool _exporting = false;
  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await ProfileService.exportData(
        scope: _scope,
        range: _range,
        format: _format,
      );
      if (mounted)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ExportCompleteScreen()),
        );
    } on ProfileException catch (error) {
      if (mounted) _snack(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Export Data')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What data do you want to export?',
            style: _style(16, AppColors.textPrimary, FontWeight.w600),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField(
            value: _scope,
            items: ExportScope.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_scopeLabel(value)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _scope = value!),
          ),
          const SizedBox(height: 24),
          Text(
            'When date range?',
            style: _style(16, AppColors.textPrimary, FontWeight.w600),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField(
            value: _range,
            items: ExportRange.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_rangeLabel(value)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _range = value!),
          ),
          const SizedBox(height: 24),
          Text(
            'What format do you want to export?',
            style: _style(16, AppColors.textPrimary, FontWeight.w600),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField(
            value: _format,
            items: ExportFormat.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.name.toUpperCase()),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _format = value!),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _exporting ? null : _export,
            icon: const Icon(Icons.file_download_outlined),
            label: Text(_exporting ? 'Preparing export…' : 'Export'),
          ),
        ],
      ),
    ),
  );
}

class ExportCompleteScreen extends StatelessWidget {
  const ExportCompleteScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.table_chart_outlined,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 38),
              Text(
                'Your export is ready',
                style: _style(25, AppColors.textPrimary, FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Your financial data file has been prepared. Choose an app in the share sheet to save or send it.',
                textAlign: TextAlign.center,
                style: _style(15, AppColors.textSecondary, FontWeight.w400),
              ),
              const SizedBox(height: 34),
              ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.profile, (_) => false),
                child: const Text('Back to Profile'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About FinSight')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.auto_graph_rounded,
            color: AppColors.primary,
            size: 38,
          ),
        ),
        const SizedBox(height: 22),
        Text('FinSight', style: _style(26, AppColors.textPrimary, FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Version 1.0.0', style: _style(14, AppColors.textSecondary, FontWeight.w500)),
        const SizedBox(height: 28),
        _infoBlock(
          'Your data',
          'Account information is private to your signed-in FinSight account. Exports are created only when you request them.',
        ),
        const SizedBox(height: 14),
        _infoBlock(
          'App lock'.tr(),
          'Your 4-digit PIN remains on this device and is never saved as readable text.',
        ),
      ],
    ),
  );
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text('Frequently asked questions', style: _style(20, AppColors.textPrimary, FontWeight.w800)),
        const SizedBox(height: 12),
        _helpItem(
          'How do I add an account?',
          'Open Profile, select Account, then tap Add new account. Choose a provider, type and current balance.',
        ),
        _helpItem(
          'Why are only the last four digits shown?',
          'Manual entry never stores a full account number. The last four digits are only a safe label for your account.',
        ),
        _helpItem(
          'How do I export my data?',
          'From Profile, choose Export Data, select content, date range and format, then use the device share sheet.',
        ),
        _helpItem(
          'How do I change the app lock?',
          'Open Settings, choose Security and select PIN or biometric unlock when your device supports it.',
        ),
      ],
    ),
  );
}

class _AccountDetail {
  final FinanceAccount account;
  final List<FinanceTransaction> transactions;
  const _AccountDetail(this.account, this.transactions);
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final Future<void> Function()? action;
  _MenuItem(this.icon, this.label, this.color, FutureOrVoidCallback callback)
    : action = callback;
}

typedef FutureOrVoidCallback = Future<void> Function();

class _ProfileMenu extends StatelessWidget {
  final List<_MenuItem> items;
  const _ProfileMenu({required this.items});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: List.generate(items.length, (i) {
        final item = items[i];
        return InkWell(
          onTap: item.action,
          borderRadius: BorderRadius.vertical(
            top: i == 0 ? const Radius.circular(24) : Radius.zero,
            bottom: i == items.length - 1
                ? const Radius.circular(24)
                : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(item.icon, color: item.color),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      item.label,
                      style: _style(
                        16,
                        Theme.of(context).colorScheme.onSurface,
                        FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                if (i != items.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(top: 17),
                    child: Divider(height: 1),
                  ),
              ],
            ),
          ),
        );
      }),
    ),
  );
}

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});
  @override
  Widget build(BuildContext context) => Container(
    width: 76,
    height: 76,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [Color(0xFFA96CFF), AppColors.primary],
      ),
      border: Border.all(color: Colors.white, width: 3),
    ),
    alignment: Alignment.center,
    child: Text(initials, style: _style(26, Colors.white, FontWeight.w800)),
  );
}

class _AccountIcon extends StatelessWidget {
  final FinanceAccount account;
  final double size;
  const _AccountIcon({required this.account, this.size = 48});
  @override
  Widget build(BuildContext context) {
    final wallet = account.accountType == 'wallet';
    if (!wallet) {
      return BankLogo(
        providerName: account.providerName,
        size: size,
        fallbackIcon: account.isCreditCard
            ? Icons.credit_card_rounded
            : Icons.account_balance_rounded,
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: (wallet ? AppColors.primary : const Color(0xFF3674D9))
            .withValues(alpha: .12),
        borderRadius: BorderRadius.circular(size * .32),
      ),
      child: Icon(
        wallet
            ? Icons.account_balance_wallet_rounded
            : account.isCreditCard
            ? Icons.credit_card_rounded
            : Icons.account_balance_rounded,
        color: wallet ? AppColors.primary : const Color(0xFF3674D9),
        size: size * .52,
      ),
    );
  }
}

class _AccountListTile extends StatelessWidget {
  final FinanceAccount account;
  final VoidCallback onTap;
  const _AccountListTile({required this.account, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
    leading: _AccountIcon(account: account),
    title: Text(
      account.providerName,
      style: _style(17, AppColors.textPrimary, FontWeight.w700),
    ),
    subtitle: Text(
      '${account.displayType} · ${account.maskedAccountNumber}',
      style: _style(12, AppColors.textSecondary, FontWeight.w400),
    ),
    trailing: Text(
      _money(account.latestBalance ?? 0, currency: account.currency),
      style: _style(16, AppColors.textPrimary, FontWeight.w800),
    ),
    onTap: onTap,
  );
}

class _ActivityTile extends StatelessWidget {
  final FinanceTransaction transaction;
  final String currency;
  const _ActivityTile({required this.transaction, required this.currency});
  @override
  Widget build(BuildContext context) {
    final credit = transaction.direction == TransactionDirection.credit;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (credit ? AppColors.success : AppColors.warning)
                .withValues(alpha: .13),
            child: Icon(
              credit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: credit ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.merchant,
                  style: _style(15, AppColors.textPrimary, FontWeight.w700),
                ),
                Text(
                  transaction.category ?? 'Transaction',
                  style: _style(12, AppColors.textSecondary, FontWeight.w400),
                ),
              ],
            ),
          ),
          Text(
            '${credit ? '+' : '-'} ${_money(transaction.amount, currency: currency)}',
            style: _style(
              15,
              credit ? AppColors.success : AppColors.error,
              FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;
  const _SettingsRow(this.title, this.value, this.onTap);
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(
        title,
        style: _style(16, scheme.onSurface, FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value.isNotEmpty)
            Text(
              value,
              style: _style(14, scheme.onSurfaceVariant, FontWeight.w400),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(
        title,
        style: _style(16, scheme.onSurface, FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: _style(13, scheme.onSurfaceVariant, FontWeight.w400),
      ),
      trailing: Switch(value: value, onChanged: enabled ? onChanged : null),
    );
  }
}

class _LogoutSheet extends StatelessWidget {
  final VoidCallback onNo;
  final VoidCallback onYes;
  const _LogoutSheet({required this.onNo, required this.onYes});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 25),
        Text(
          'Logout?',
          style: _style(21, AppColors.textPrimary, FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'Are you sure you want to log out?',
          style: _style(15, AppColors.textSecondary, FontWeight.w400),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: onNo, child: const Text('No')),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton(onPressed: onYes, child: const Text('Yes')),
            ),
          ],
        ),
      ],
    ),
  );
}




class _ProfileError extends StatelessWidget {
  final VoidCallback onRetry;
  const _ProfileError({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'We could not load this page',
            style: _style(19, AppColors.textPrimary, FontWeight.w800),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

enum PreferenceKind { currency, language, theme, security }

String _themeLabel(String value) => switch (value) {
  'dark' => 'FinSight dark',
  'system' => 'Use device setting',
  _ => 'FinSight light',
};
String _preferenceLabel(PreferenceKind kind, String value) => switch (kind) {
  PreferenceKind.currency => switch (value) {
    'INR' => 'India (INR)',
    'USD' => 'United States (USD)',
    'EUR' => 'Germany (EUR)',
    'IDR' => 'Indonesia (IDR)',
    'JPY' => 'Japan (JPY)',
    'RUB' => 'Russia (RUB)',
    _ => 'Korea (KRW)',
  },
  PreferenceKind.theme => switch (value) {
    'dark' => 'FinSight dark theme',
    'system' => 'Use device setting',
    _ => 'FinSight light theme',
  },
  PreferenceKind.security => value == 'pin' ? 'PIN' : 'Biometric',
  _ => value,
};
String _scopeLabel(ExportScope value) => switch (value) {
  ExportScope.all => 'All',
  ExportScope.accounts => 'Accounts',
  ExportScope.transactions => 'Transactions',
};
String _rangeLabel(ExportRange value) => switch (value) {
  ExportRange.last30Days => 'Last 30 days',
  ExportRange.last90Days => 'Last 90 days',
  ExportRange.thisYear => 'This year',
  ExportRange.allTime => 'All time',
};
String _money(double value, {String? currency}) {
  // Account records keep their source currency; this screen follows the
  // user's selected display currency consistently.
  final _ = currency;
  return CurrencyService.format(value);
}

TextStyle _style(double size, Color color, FontWeight weight) =>
    GoogleFonts.inter(fontSize: size, color: color, fontWeight: weight);
Widget _emptyCard(String title, String subtitle) => Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.border),
  ),
  child: Column(
    children: [
      Text(title, style: _style(18, AppColors.textPrimary, FontWeight.w800)),
      const SizedBox(height: 6),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: _style(14, AppColors.textSecondary, FontWeight.w400),
      ),
    ],
  ),
);
Future<bool?> _confirm(BuildContext context, String title, String message) =>
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
void _snack(BuildContext context, String message, {bool error = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
Widget _infoBlock(String title, String body) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppColors.border),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: _style(16, AppColors.textPrimary, FontWeight.w700)),
      const SizedBox(height: 6),
      Text(body, style: _style(14, AppColors.textSecondary, FontWeight.w400)),
    ],
  ),
);

Widget _helpItem(String title, String body) => Container(
  margin: const EdgeInsets.only(bottom: 12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppColors.border),
  ),
  child: ExpansionTile(
    title: Text(title, style: _style(15, AppColors.textPrimary, FontWeight.w700)),
    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    children: [
      Text(body, style: _style(14, AppColors.textSecondary, FontWeight.w400)),
    ],
  ),
);
