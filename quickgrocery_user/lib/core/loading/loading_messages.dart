/// Friendly rotating loading copy — never used for brand/legal text.
abstract final class LoadingMessages {
  LoadingMessages._();

  static const friendly = <String>[
    'Getting today\'s offers...',
    'Finding the best deals...',
    'Collecting groceries...',
    'Almost ready...',
    'Sorting products...',
    'Checking nearby vendors...',
    'Loading your cart...',
    'Preparing recommendations...',
    'Loading discounts...',
    'Just a moment...',
    'Fetching today\'s prices...',
    'Polishing the shelves...',
    'Finding what you love...',
    'Warming up the store...',
    'Hang tight — freshness loading...',
  ];

  static const search = <String>[
    'Searching the aisle...',
    'Looking across categories...',
    'Matching the freshest picks...',
    'Finding similar products...',
  ];

  static const cart = <String>[
    'Loading your cart...',
    'Checking item availability...',
    'Updating prices...',
  ];

  static const orders = <String>[
    'Fetching your orders...',
    'Checking delivery status...',
    'Loading order timeline...',
  ];

  static const checkout = <String>[
    'Preparing checkout...',
    'Loading delivery slots...',
    'Calculating bill summary...',
  ];
}
