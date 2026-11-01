import 'package:flutter/material.dart';

class CategoryColors {
  CategoryColors._();

  static const Color foodAndDining = Color(0xFF7F3DFF); // Vibrant Purple
  static const Color shopping = Color(0xFFFC8B3D);      // Orange
  static const Color billsAndUtilities = Color(0xFF007AFF); // Electric Blue
  static const Color transport = Color(0xFF00A86B);     // Emerald Green
  static const Color entertainment = Color(0xFFFD3C4A); // Ruby Red
  static const Color health = Color(0xFF00C896);        // Mint Green
  static const Color others = Color(0xFF91919F);        // Slate Gray

  static Color forCategory(String category) {
    final normalized = category.toLowerCase().trim();
    if (normalized.contains('food') || normalized.contains('dining')) {
      return foodAndDining;
    }
    if (normalized.contains('shop')) {
      return shopping;
    }
    if (normalized.contains('bill') || normalized.contains('utility')) {
      return billsAndUtilities;
    }
    if (normalized.contains('transport') || normalized.contains('travel') || normalized.contains('fuel')) {
      return transport;
    }
    if (normalized.contains('entertain') || normalized.contains('movie') || normalized.contains('game')) {
      return entertainment;
    }
    if (normalized.contains('health') || normalized.contains('medical')) {
      return health;
    }
    return others;
  }

  static IconData iconForCategory(String category) {
    final normalized = category.toLowerCase().trim();
    if (normalized.contains('food') || normalized.contains('dining')) {
      return Icons.restaurant_rounded;
    }
    if (normalized.contains('shop')) {
      return Icons.shopping_bag_outlined;
    }
    if (normalized.contains('bill') || normalized.contains('utility')) {
      return Icons.receipt_long_outlined;
    }
    if (normalized.contains('transport') || normalized.contains('travel') || normalized.contains('fuel')) {
      return Icons.directions_car_outlined;
    }
    if (normalized.contains('entertain') || normalized.contains('movie') || normalized.contains('game')) {
      return Icons.movie_outlined;
    }
    if (normalized.contains('health') || normalized.contains('medical')) {
      return Icons.favorite_border_rounded;
    }
    return Icons.category_outlined;
  }
}
