import '../models/category_definition.dart';
import 'default_category_rules.dart';

/// The category every transaction falls back to. It cannot be edited or
/// deleted and must stay last in pickers.
const String uncategorizedCategory = 'Uncategorized';

/// Categories that ship with the app. Their keywords come from
/// [categoryRules] so auto-categorization and pickers stay in sync.
final List<CategoryDefinition> predefinedCategories = [
  for (final entry in const {
    'Food': 'food',
    'Grocery': 'grocery',
    'Shopping': 'shopping',
    'Travel': 'travel',
    'Bills': 'bills',
    'Health': 'health',
    'Entertainment': 'entertainment',
    'Salary': 'salary',
    'Sports': 'sports',
    'Study': 'study',
  }.entries)
    CategoryDefinition(
      name: entry.key,
      iconKey: entry.value,
      keywords: categoryRules[entry.key] ?? const [],
    ),
  const CategoryDefinition(name: uncategorizedCategory, iconKey: 'category'),
];
