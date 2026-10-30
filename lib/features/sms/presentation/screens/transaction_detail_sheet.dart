import 'package:flutter/material.dart';
import '../../data/transaction_repository.dart';
import '../../models/parsed_transaction.dart';
import '../../models/transaction_status.dart';
import '../theme/app_theme.dart';
import '../widgets/amount_text.dart';
import '../widgets/category_widgets.dart';
import '../widgets/masking_helpers.dart';
import '../widgets/pill_buttons.dart';
import '../widgets/status_tag.dart';

class TransactionDetailSheet extends StatefulWidget {
  final ParsedTransaction transaction;
  final TransactionRepository repository;
  final VoidCallback onSaved;

  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    required this.repository,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required ParsedTransaction transaction,
    required TransactionRepository repository,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionDetailSheet(
        transaction: transaction,
        repository: repository,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
  late TextEditingController _partyController;
  late TextEditingController _noteController;
  late String _selectedCategory;
  bool _applyToPast = false;
  int _otherPastCount = 0;
  bool _isLoadingOtherCount = true;

  @override
  void initState() {
    super.initState();
    _partyController = TextEditingController(text: widget.transaction.party);
    _noteController = TextEditingController();
    _selectedCategory = CategoryMeta.sanitize(widget.transaction.category);
    _loadOtherPastTransactions();
  }

  Future<void> _loadOtherPastTransactions() async {
    final all = await widget.repository.getAll();
    final norm = TransactionRepository.normalizeParty(widget.transaction.party);
    final count = all.where((t) {
      return t.id != widget.transaction.id &&
          TransactionRepository.normalizeParty(t.party) == norm;
    }).length;

    if (mounted) {
      setState(() {
        _otherPastCount = count;
        _isLoadingOtherCount = false;
        _applyToPast = count > 0;
      });
    }
  }

  @override
  void dispose() {
    _partyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
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
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day $month $year, $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final maskedAcct = maskAccount(tx.accountLast4);
    final maskedRef = maskReference(tx.reference);
    final dateStr = _formatDateTime(tx.date);
    final isAuto = tx.categorySource == 'auto';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Amount with Debit/Credit and Status tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AmountText(
                      amountPaise: tx.amountPaise,
                      type: tx.type,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (tx.status == TransactionStatus.pending)
                        const StatusTag.pending(),
                      if (tx.lowConfidence)
                        const StatusTag.needsCheck(),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Merchant text field
              TextField(
                controller: _partyController,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  labelText: 'Merchant / Party',
                  labelStyle: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              // Category dropdown
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: CategoryMeta.validCategories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              CategoryIcon(category: c, size: 24, iconSize: 14),
                              const SizedBox(width: 8),
                              Text(c, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),
                  ),
                  if (isAuto) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Suggested',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              // Meta info card (Account, Date, Reference)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildMetaRow('Account', maskedAcct),
                    const SizedBox(height: 6),
                    _buildMetaRow('Date & Time', dateStr),
                    if (maskedRef != null) ...[
                      const SizedBox(height: 6),
                      _buildMetaRow('Reference', maskedRef),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Note field
              TextField(
                controller: _noteController,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  labelStyle: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              // Checkbox for past transactions (hidden if n == 0)
              if (!_isLoadingOtherCount && _otherPastCount > 0) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _applyToPast,
                  dense: true,
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'Apply to all past transactions from ${tx.party} ($_otherPastCount others)',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _applyToPast = val ?? false);
                  },
                ),
              ],
              const SizedBox(height: 20),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: SecondaryPillButton(
                      label: 'Ignore',
                      outlined: true,
                      onPressed: () async {
                        if (tx.id != null) {
                          await widget.repository.updateStatus(tx.id!, TransactionStatus.ignored);
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          widget.onSaved();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryPillButton(
                      label: 'Confirm',
                      onPressed: () async {
                        final newParty = _partyController.text.trim().isEmpty
                            ? tx.party
                            : _partyController.text.trim();
                        if (tx.id != null) {
                          await widget.repository.updatePartyAndCategory(
                            tx.id!,
                            party: newParty,
                            category: _selectedCategory,
                            applyToPast: _applyToPast,
                          );
                          await widget.repository.updateStatus(tx.id!, TransactionStatus.confirmed);
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          widget.onSaved();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
