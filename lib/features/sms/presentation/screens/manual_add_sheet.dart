import 'package:flutter/material.dart';
import '../../data/transaction_repository.dart';
import '../../models/parsed_transaction.dart';
import '../../models/transaction_status.dart';
import '../../models/transaction_type.dart';
import '../theme/app_theme.dart';
import '../widgets/category_widgets.dart';
import '../widgets/pill_buttons.dart';

class ManualAddSheet extends StatefulWidget {
  final TransactionRepository repository;
  final DateTime? initialDate;
  final VoidCallback onSaved;

  const ManualAddSheet({
    super.key,
    required this.repository,
    this.initialDate,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required TransactionRepository repository,
    DateTime? initialDate,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ManualAddSheet(
        repository: repository,
        initialDate: initialDate,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<ManualAddSheet> createState() => _ManualAddSheetState();
}

class _ManualAddSheetState extends State<ManualAddSheet> {
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _type = TransactionType.debit;
  String _category = 'Food';
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? _parseAmountToPaise(String raw) {
    final clean = raw.replaceAll(',', '').trim();
    if (clean.isEmpty) return null;
    if (clean.contains('.')) {
      final parts = clean.split('.');
      final rupees = int.tryParse(parts[0]);
      if (rupees == null) return null;
      var dec = parts.length > 1 ? parts[1] : '0';
      if (dec.length == 1) {
        dec = '${dec}0';
      } else if (dec.length > 2) {
        dec = dec.substring(0, 2);
      }
      final paise = int.tryParse(dec) ?? 0;
      return rupees * 100 + paise;
    } else {
      final rupees = int.tryParse(clean);
      if (rupees == null) return null;
      return rupees * 100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const Text(
                'Add Transaction Manually',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Debit / Credit toggle
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _type = TransactionType.debit),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == TransactionType.debit
                              ? AppColors.debitLight
                              : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _type == TransactionType.debit
                                ? AppColors.debit
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Debit (-)',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: _type == TransactionType.debit
                                ? AppColors.debit
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _type = TransactionType.credit),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == TransactionType.credit
                              ? AppColors.creditLight
                              : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _type == TransactionType.credit
                                ? AppColors.credit
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Credit (+)',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: _type == TransactionType.credit
                                ? AppColors.credit
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Amount
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              // Merchant
              TextField(
                controller: _merchantController,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Merchant / Beneficiary',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              // Category
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
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
                        CategoryIcon(category: c, size: 22, iconSize: 13),
                        const SizedBox(width: 8),
                        Text(c, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 12),
              // Note
              TextField(
                controller: _noteController,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryPillButton(
                label: 'Save Transaction',
                onPressed: () async {
                  final paise = _parseAmountToPaise(_amountController.text);
                  if (paise == null || paise <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid amount')),
                    );
                    return;
                  }
                  final merchant = _merchantController.text.trim().isEmpty
                      ? 'Manual Entry'
                      : _merchantController.text.trim();

                  final manualTx = ParsedTransaction(
                    amountPaise: paise,
                    type: _type,
                    party: merchant,
                    category: _category,
                    date: _date,
                    sender: 'manual',
                    status: TransactionStatus.confirmed,
                    categorySource: 'user',
                  );

                  await widget.repository.insertNewFromScan([manualTx]);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    widget.onSaved();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
