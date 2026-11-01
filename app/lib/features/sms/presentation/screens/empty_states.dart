import 'package:flutter/material.dart';
import '../../services/sms_pipeline.dart';
import '../theme/app_theme.dart';
import '../widgets/pill_buttons.dart';

class EmptyTransactionsView extends StatelessWidget {
  final VoidCallback onScanAgain;
  final VoidCallback onAddManually;

  const EmptyTransactionsView({
    super.key,
    required this.onScanAgain,
    required this.onAddManually,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.search_off_rounded,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Transactions Found',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We scanned the messages on this phone but found no bank transactions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            PrimaryPillButton(
              label: 'Scan again',
              icon: Icons.sync_rounded,
              onPressed: onScanAgain,
            ),
            const SizedBox(height: 10),
            SecondaryPillButton(
              label: 'Add manually',
              outlined: true,
              onPressed: onAddManually,
            ),
          ],
        ),
      ),
    );
  }
}

class UnreadableMessagesView extends StatefulWidget {
  final List<UnreadableMessage> messages;
  final ValueChanged<DateTime> onAddManuallyWithDate;

  const UnreadableMessagesView({
    super.key,
    required this.messages,
    required this.onAddManuallyWithDate,
  });

  @override
  State<UnreadableMessagesView> createState() => _UnreadableMessagesViewState();
}

class _UnreadableMessagesViewState extends State<UnreadableMessagesView> {
  late List<UnreadableMessage> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.messages);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'No unreadable messages.',
          style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.senderId,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatDate(item.date),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Reason: ${item.reason}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.pendingText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() => _items.removeAt(index));
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Ignore', style: TextStyle(fontFamily: 'Inter')),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        widget.onAddManuallyWithDate(item.date);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Add manually',
                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

