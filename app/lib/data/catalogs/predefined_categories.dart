import '../models/category_definition.dart';
import '../../features/sms/rules/category_rules.dart';

const uncategorizedCategory = 'Uncategorized';

final predefinedCategories = <CategoryDefinition>[
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
  const CategoryDefinition(
    name: uncategorizedCategory,
    iconKey: 'category',
    isCustom: false,
  ),
];
