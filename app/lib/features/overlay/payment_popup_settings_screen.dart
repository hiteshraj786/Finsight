import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../services/sms/payment_popup.dart';

/// Settings → Payment popups: turn the over-other-apps popup on or off,
/// grant Android's "Display over other apps" permission, and try it out.
class PaymentPopupSettingsScreen extends StatefulWidget {
  const PaymentPopupSettingsScreen({super.key});

  @override
  State<PaymentPopupSettingsScreen> createState() =>
      _PaymentPopupSettingsScreenState();
}

class _PaymentPopupSettingsScreenState extends State<PaymentPopupSettingsScreen>
    with WidgetsBindingObserver {
  bool _enabled = true;
  bool _permission = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from Android's permission page.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final enabled = await PaymentPopup.isEnabled();
    final permission = await PaymentPopup.hasPermission();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _permission = permission;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    if (value && !_permission) {
      await PaymentPopup.requestPermission();
    }
    await PaymentPopup.setEnabled(value);
    await _refresh();
  }

  Future<void> _tryIt() async {
    final repository = TransactionRepository();
    final latest = (await repository.getAll()).firstOrNull;
    if (!mounted) return;
    if (latest?.id == null) {
      _snack('Import some SMS transactions first.');
      return;
    }
    _snack('Switch to another app — the popup appears in 5 seconds.');
    await Future<void>.delayed(PaymentPopup.delay);
    await PaymentPopup.show(latest!.id!, repository);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = _enabled && _permission;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment popups')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Icon(
                  Icons.picture_in_picture_alt_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 14),
                Text(
                  'See each payment the moment you make it',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '5 seconds after your bank\'s SMS arrives, a small card '
                  'shows the amount, merchant and how you paid (UPI, card, '
                  'net banking) on top of the app you are in, such as GPay. '
                  'Pick a category and confirm without opening FinSight.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                Card(
                  elevation: 0,
                  color: scheme.surfaceContainerLow,
                  child: SwitchListTile(
                    value: active,
                    onChanged: _toggle,
                    activeThumbColor: AppColors.primary,
                    title: const Text('Show popup over other apps'),
                    subtitle: Text(
                      _permission
                          ? 'Allowed by Android'
                          : 'Needs "Display over other apps" permission',
                    ),
                  ),
                ),
                if (!_permission) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: PaymentPopup.requestPermission,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open Android permission page'),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: active ? _tryIt : null,
                  icon: const Icon(Icons.play_arrow_rounded),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  label: const Text('Try it with your latest transaction'),
                ),
                const SizedBox(height: 22),
                Text(
                  'If popups don\'t appear when FinSight is closed, allow it '
                  'to run in the background: Settings → Apps → FinSight → '
                  'Battery → Unrestricted.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }
}
