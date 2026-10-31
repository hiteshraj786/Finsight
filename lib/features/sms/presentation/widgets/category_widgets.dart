import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryMeta {
  final String name;
  final IconData icon;

  const CategoryMeta(this.name, this.icon);

  static const List<String> validCategories = [
    'Food',
    'Grocery',
    'Shopping',
    'Travel',
    'Bills',
    'Sports',
    'Study',
    'Uncategorized',
  ];

  static IconData getIcon(String category) {
    switch (category.trim().toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'grocery':
        return Icons.shopping_cart_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'travel':
        return Icons.directions_car_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'sports':
        return Icons.fitness_center_rounded;
      case 'study':
        return Icons.school_rounded;
      case 'uncategorized':
      default:
        return Icons.category_rounded;
    }
  }

  static String sanitize(String category) {
    for (final c in validCategories) {
      if (c.toLowerCase() == category.trim().toLowerCase()) {
        return c;
      }
    }
    return 'Uncategorized';
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

