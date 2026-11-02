import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/catalogs/indian_banks.dart';
import '../../data/models/bank_info.dart';
import '../theme/app_colors.dart';
import 'bank_logo.dart';

/// Searchable, grouped list of Indian banks and wallets with their logos.
/// Returns the chosen [BankInfo], or null if dismissed.
class BankPickerSheet extends StatefulWidget {
  final String? selectedName;

  const BankPickerSheet({super.key, this.selectedName});

  static Future<BankInfo?> show(BuildContext context, {String? selectedName}) {
    return showModalBottomSheet<BankInfo>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.88,
        child: BankPickerSheet(selectedName: selectedName),
      ),
    );
  }

  @override
  State<BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<BankPickerSheet> {
  String _query = '';

  List<BankInfo> get _matches {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return indianBanks;
    return indianBanks
        .where(
          (b) =>
              b.name.toLowerCase().contains(q) ||
              b.shortName.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final matches = _matches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Select bank or wallet',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search e.g. SBI, HDFC, Paytm',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: scheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: matches.isEmpty
              ? Center(
                  child: Text(
                    'No bank matches "$_query"',
                    style: GoogleFonts.inter(color: scheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final bank = matches[index];
                    final showHeader =
                        index == 0 || matches[index - 1].group != bank.group;
                    final selected = bank.name == widget.selectedName;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showHeader)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                            child: Text(
                              bank.group.label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ListTile(
                          onTap: () => Navigator.pop(context, bank),
                          leading: BankLogo(bank: bank, size: 44),
                          title: Text(
                            bank.name,
                            style: GoogleFonts.inter(
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
