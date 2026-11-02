import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/category_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/category_definition.dart';
import '../../data/repositories/category_repository.dart';
import '../../services/categories/category_registry.dart';

/// Lists every category. All of them, built-in ones included, can be
/// edited or deleted; only Uncategorized is fixed.
class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  Future<void> _restoreBuiltIns(BuildContext context) async {
    final added = await CategoryRegistry.instance.restoreBuiltIns();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added == 0
              ? 'All built-in categories are already there.'
              : 'Restored $added built-in ${added == 1 ? 'category' : 'categories'}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registry = CategoryRegistry.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          PopupMenuButton<void>(
            tooltip: 'More',
            itemBuilder: (_) => [
              PopupMenuItem(
                onTap: () => _restoreBuiltIns(context),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.restore_rounded),
                  title: Text('Restore built-in categories'),
                  subtitle: Text('Adds back any you deleted'),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CategoryEditorSheet.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New category'),
      ),
      body: ListenableBuilder(
        listenable: registry,
        builder: (context, _) {
          final fixed = registry.all.where((c) => !c.isCustom);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              const _EmptyCustomHint(),
              const SizedBox(height: 12),
              for (final category in registry.editable)
                _CategoryTile(
                  category: category,
                  onTap: () =>
                      CategoryEditorSheet.show(context, existing: category),
                  trailing: IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _confirmDelete(context, category),
                  ),
                ),
              for (final category in fixed)
                _CategoryTile(
                  category: category,
                  trailing: const Tooltip(
                    message: 'Every transaction falls back to this one',
                    child: Icon(Icons.lock_outline_rounded, size: 18),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CategoryDefinition category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete "${category.name}"?'),
        content: const Text(
          'Transactions in this category will move to Uncategorized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await CategoryRegistry.instance.delete(category);
  }
}

class _EmptyCustomHint extends StatelessWidget {
  const _EmptyCustomHint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        'Tap a category to rename it, change its icon or edit its keywords. '
        'New SMS transactions from merchants matching a keyword are sorted '
        'into it automatically.',
        style: GoogleFonts.inter(
          fontSize: 13,
          height: 1.4,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryDefinition category;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _CategoryTile({required this.category, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final keywords = category.keywords.join(', ');
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(
            CategoryIcons.of(category.iconKey),
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          category.name,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        subtitle: keywords.isEmpty
            ? null
            : Text(
                keywords,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 12),
              ),
        trailing: trailing,
      ),
    );
  }
}

/// Bottom sheet to create a custom category, or edit [existing].
class CategoryEditorSheet extends StatefulWidget {
  final CategoryDefinition? existing;

  const CategoryEditorSheet({super.key, this.existing});

  /// Returns the saved category name, or null if the user cancelled.
  static Future<String?> show(
    BuildContext context, {
    CategoryDefinition? existing,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CategoryEditorSheet(existing: existing),
    );
  }

  @override
  State<CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<CategoryEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _keywords;
  late String _iconKey;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _keywords = TextEditingController(
      text: existing?.keywords.join(', ') ?? '',
    );
    _iconKey = existing?.iconKey ?? 'home';
  }

  @override
  void dispose() {
    _name.dispose();
    _keywords.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final registry = CategoryRegistry.instance;
    try {
      final existing = widget.existing;
      if (existing == null) {
        await registry.add(
          name: _name.text,
          iconKey: _iconKey,
          keywords: _keywords.text,
        );
      } else {
        await registry.update(
          existing,
          name: _name.text,
          iconKey: _iconKey,
          keywords: _keywords.text,
        );
      }
      if (mounted) {
        Navigator.pop(context, _name.text.trim().replaceAll(RegExp(r'\s+'), ' '));
      }
    } on CategoryException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Could not save the category. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEditing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? 'Edit category' : 'New category',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: !isEditing,
              textCapitalization: TextCapitalization.words,
              maxLength: 24,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Rent',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _keywords,
              decoration: const InputDecoration(
                labelText: 'Keywords (optional)',
                hintText: 'e.g. nobroker, landlord',
                helperText:
                    'Comma-separated. New SMS from merchants containing a '
                    'keyword go into this category.',
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Icon',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final entry in CategoryIcons.byKey.entries)
                  InkWell(
                    onTap: () => setState(() => _iconKey = entry.key),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _iconKey == entry.key
                            ? AppColors.primary
                            : scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        entry.value,
                        size: 22,
                        color: _iconKey == entry.key
                            ? Colors.white
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: GoogleFonts.inter(color: AppColors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isEditing ? 'Save changes' : 'Create category'),
            ),
          ],
        ),
      ),
    );
  }
}
