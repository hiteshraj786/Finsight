import 'package:flutter/material.dart';
import '../../domain/category_colors.dart';

class CategoryIconTile extends StatelessWidget {
  final String category;
  final double size;

  const CategoryIconTile({
    super.key,
    required this.category,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final color = CategoryColors.forCategory(category);
    final icon = CategoryColors.iconForCategory(category);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.52,
      ),
    );
  }
}
