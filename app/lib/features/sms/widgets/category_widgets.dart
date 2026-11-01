import 'package:flutter/material.dart';
import '../../../core/constants/category_icons.dart';
import '../../../data/catalogs/predefined_categories.dart';
import '../../../services/categories/category_registry.dart';
import '../../categories/manage_categories_screen.dart';
import '../theme/sms_theme.dart';

class CategoryMeta {
  final String name;
  final IconData icon;

  const CategoryMeta(this.name, this.icon);

  /// Predefined and custom category names, with Uncategorized last.
  static List<String> get validCategories => CategoryRegistry.instance.names;

  static IconData getIcon(String category) {
    final definition = CategoryRegistry.instance.find(category);
    return CategoryIcons.of(definition?.iconKey ?? CategoryIcons.fallbackKey);
  }

  static String sanitize(String category) =>
      CategoryRegistry.instance.find(category)?.name ?? uncategorizedCategory;
}

/// "+ New category" link shown under category pickers. Calls [onCreated]
/// with the new category's name once the user saves it.
class NewCategoryButton extends StatelessWidget {
  final ValueChanged<String> onCreated;

  const NewCategoryButton({super.key, required this.onCreated});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () async {
          final name = await CategoryEditorSheet.show(context);
          if (name != null) onCreated(name);
        },
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text(
          'New category',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    );
  }
}

class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 40,
    this.iconSize = 20,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final icon = CategoryMeta.getIcon(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor ?? AppColors.primary,
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showIcon;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final cleanName = CategoryMeta.sanitize(category);
    final icon = CategoryMeta.getIcon(cleanName);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              cleanName,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

