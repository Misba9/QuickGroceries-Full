/// Grocery category meta used by premium loaders.
class LoadingCategory {
  const LoadingCategory({
    required this.id,
    required this.label,
    required this.emoji,
    required this.loadingMessage,
  });

  final String id;
  final String label;
  final String emoji;
  final String loadingMessage;
}

/// Curated grocery categories for rotating loaders (Blinkit/Zepto style).
abstract final class LoadingCategories {
  LoadingCategories._();

  static const all = <LoadingCategory>[
    LoadingCategory(
      id: 'vegetables',
      label: 'Fresh Vegetables',
      emoji: '🥬',
      loadingMessage: 'Loading Fresh Vegetables...',
    ),
    LoadingCategory(
      id: 'fruits',
      label: 'Fresh Fruits',
      emoji: '🍎',
      loadingMessage: 'Picking the freshest fruits...',
    ),
    LoadingCategory(
      id: 'dairy',
      label: 'Dairy Products',
      emoji: '🥛',
      loadingMessage: 'Preparing Dairy Products...',
    ),
    LoadingCategory(
      id: 'bakery',
      label: 'Bakery',
      emoji: '🥖',
      loadingMessage: 'Warming up the bakery aisle...',
    ),
    LoadingCategory(
      id: 'grains',
      label: 'Rice & Atta',
      emoji: '🍚',
      loadingMessage: 'Sorting Rice & Atta...',
    ),
    LoadingCategory(
      id: 'spices',
      label: 'Spices',
      emoji: '🧂',
      loadingMessage: 'Gathering aromatic spices...',
    ),
    LoadingCategory(
      id: 'beverages',
      label: 'Beverages',
      emoji: '🥤',
      loadingMessage: 'Chilling refreshing beverages...',
    ),
    LoadingCategory(
      id: 'snacks',
      label: 'Snacks',
      emoji: '🍪',
      loadingMessage: 'Finding tasty snacks...',
    ),
    LoadingCategory(
      id: 'chocolates',
      label: 'Chocolates',
      emoji: '🍫',
      loadingMessage: 'Unwrapping chocolates...',
    ),
    LoadingCategory(
      id: 'meat',
      label: 'Meat',
      emoji: '🍗',
      loadingMessage: 'Selecting fresh meat...',
    ),
    LoadingCategory(
      id: 'seafood',
      label: 'Seafood',
      emoji: '🐟',
      loadingMessage: 'Catching fresh seafood...',
    ),
    LoadingCategory(
      id: 'eggs',
      label: 'Eggs',
      emoji: '🥚',
      loadingMessage: 'Collecting farm-fresh eggs...',
    ),
    LoadingCategory(
      id: 'icecream',
      label: 'Ice Cream',
      emoji: '🍦',
      loadingMessage: 'Scooping ice cream treats...',
    ),
    LoadingCategory(
      id: 'personal_care',
      label: 'Personal Care',
      emoji: '🧴',
      loadingMessage: 'Loading personal care essentials...',
    ),
    LoadingCategory(
      id: 'cleaning',
      label: 'Cleaning Supplies',
      emoji: '🧹',
      loadingMessage: 'Stocking cleaning supplies...',
    ),
    LoadingCategory(
      id: 'household',
      label: 'Household',
      emoji: '🧻',
      loadingMessage: 'Arranging household items...',
    ),
    LoadingCategory(
      id: 'baby',
      label: 'Baby Care',
      emoji: '👶',
      loadingMessage: 'Preparing baby care products...',
    ),
    LoadingCategory(
      id: 'pet',
      label: 'Pet Food',
      emoji: '🐶',
      loadingMessage: 'Fetching pet food favourites...',
    ),
    LoadingCategory(
      id: 'flowers',
      label: 'Flowers',
      emoji: '🌼',
      loadingMessage: 'Arranging fresh flowers...',
    ),
    LoadingCategory(
      id: 'health',
      label: 'Health Care',
      emoji: '💊',
      loadingMessage: 'Loading health care essentials...',
    ),
  ];

  static const emojiPool = <String>[
    '🥦',
    '🥕',
    '🍅',
    '🍎',
    '🥛',
    '🥖',
    '🥚',
    '🍚',
    '🛒',
    '🥬',
    '🍪',
    '🥤',
  ];
}
