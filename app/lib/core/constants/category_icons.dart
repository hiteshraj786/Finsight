import 'package:flutter/material.dart';

/// Icons a category can use. Custom categories store the key, so keys must
/// never be renamed once released.
class CategoryIcons {
  CategoryIcons._();

  static const String fallbackKey = 'category';

  static const Map<String, IconData> byKey = {
    'category': Icons.category_rounded,
    'food': Icons.restaurant_rounded,
    'grocery': Icons.shopping_cart_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'travel': Icons.directions_car_rounded,
    'bills': Icons.receipt_long_rounded,
    'sports': Icons.fitness_center_rounded,
    'study': Icons.school_rounded,
    'health': Icons.local_hospital_rounded,
    'entertainment': Icons.movie_rounded,
    'salary': Icons.payments_rounded,
    'home': Icons.home_rounded,
    'cafe': Icons.local_cafe_rounded,
    'flight': Icons.flight_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'phone': Icons.phone_android_rounded,
    'clothing': Icons.checkroom_rounded,
    'gift': Icons.card_giftcard_rounded,
    'pets': Icons.pets_rounded,
    'kids': Icons.child_care_rounded,
    'beauty': Icons.spa_rounded,
    'repairs': Icons.build_rounded,
    'charity': Icons.volunteer_activism_rounded,
    'investment': Icons.trending_up_rounded,
    'savings': Icons.savings_rounded,
    'bank': Icons.account_balance_rounded,
    'party': Icons.celebration_rounded,
    'transfer': Icons.swap_horiz_rounded,
  };

  static IconData of(String key) => byKey[key] ?? byKey[fallbackKey]!;
}
