import 'package:quickgrocery/view/orders/domain/order_models.dart';

/// Suggested next-step after a bot reply.
enum OrderSupportAction {
  none,
  openEditProfile,
  openAddresses,
}

class OrderSupportReply {
  const OrderSupportReply({
    required this.text,
    this.quickReplies = const [],
    this.action = OrderSupportAction.none,
  });

  final String text;
  final List<String> quickReplies;
  final OrderSupportAction action;
}

/// Local smart assistant for **Order support** only.
///
/// Allowed topics: this order’s status/delivery + user account/profile updates.
/// Everything else is politely declined.
abstract final class OrderSupportBot {
  OrderSupportBot._();

  static const welcomeQuickReplies = <String>[
    'Where is my order?',
    'Update my profile',
    'Change delivery address',
    'Payment status',
    'Cancel order',
  ];

  static OrderSupportReply welcome(LiveOrder? order) {
    final idShort = _shortId(order?.id);
    final status = order == null ? '' : _statusLabel(order.status);
    final intro = order == null
        ? "Hi! I'm your Order Support assistant."
        : "Hi! I'm your Order Support assistant for order #$idShort ($status).";

    return OrderSupportReply(
      text: '$intro\n\n'
          'I can help with:\n'
          '• Order tracking & delivery\n'
          '• Your account / profile details\n'
          '• Address updates\n\n'
          'I can’t help with shopping, products, or offers here — '
          'use the Grocery Assistant for that.\n\n'
          'Pick an option or type your question.',
      quickReplies: welcomeQuickReplies,
    );
  }

  static OrderSupportReply reply({
    required String message,
    required LiveOrder? order,
  }) {
    final q = message.trim().toLowerCase();
    if (q.isEmpty) {
      return const OrderSupportReply(
        text: 'Please type a question, or pick an option below.',
        quickReplies: welcomeQuickReplies,
      );
    }

    if (_isOffTopic(q)) {
      return const OrderSupportReply(
        text: 'I only help with this order and your account details '
            '(name, phone, address, profile).\n\n'
            'For products, offers, or browsing, open the Grocery Assistant '
            'from Home.\n\n'
            'What would you like help with here?',
        quickReplies: welcomeQuickReplies,
      );
    }

    if (_matches(q, const [
      'where',
      'track',
      'status',
      'location',
      'reached',
      'coming',
      'arriving',
      'order status',
    ])) {
      return _statusReply(order);
    }

    if (_matches(q, const [
      'eta',
      'time',
      'when',
      'how long',
      'delay',
      'late',
      'minutes',
    ])) {
      return _etaReply(order);
    }

    if (_matches(q, const [
      'rider',
      'delivery partner',
      'delivery boy',
      'driver',
      'assigned',
    ])) {
      return _riderReply(order);
    }

    if (_matches(q, const [
      'cancel',
      'cancelled',
      'stop order',
      'dont want',
      "don't want",
    ])) {
      return _cancelReply(order);
    }

    if (_matches(q, const ['tip', 'tips', 'gratuity', 'thank partner'])) {
      return _tipReply(order);
    }

    if (_matches(q, const [
      'invoice',
      'bill',
      'receipt',
      'payment',
      'paid',
      'refund',
      'money',
    ])) {
      return _paymentReply(order);
    }

    if (_matches(q, const [
      'item',
      'items',
      'product',
      'what did i order',
      'my order details',
      'qty',
    ])) {
      return _itemsReply(order);
    }

    if (_matches(q, const [
      'address',
      'change address',
      'delivery address',
      'wrong address',
      'update address',
    ])) {
      return const OrderSupportReply(
        text: 'You can update saved addresses from your Profile → Address.\n\n'
            'If this order is already out for delivery, the drop location '
            'usually can’t be changed — cancel before pickup if needed, '
            'or contact us after delivery for help.\n\n'
            'Want to open your addresses now?',
        quickReplies: [
          'Open addresses',
          'Where is my order?',
          'Cancel order',
        ],
      );
    }

    if (_matches(q, const [
      'profile',
      'account',
      'update name',
      'change name',
      'update phone',
      'change phone',
      'my information',
      'user information',
      'edit profile',
      'update profile',
      'my details',
      'update my profile',
    ])) {
      return const OrderSupportReply(
        text: 'You can update your account details anytime:\n'
            '• Name & gender\n'
            '• Phone number\n'
            '• Profile photo\n\n'
            'Open Edit Profile to make changes. '
            'Your order tracking details stay linked to this account.',
        quickReplies: [
          'Open edit profile',
          'Change delivery address',
          'Where is my order?',
        ],
      );
    }

    if (_matches(q, const ['open edit profile', 'edit my profile'])) {
      return const OrderSupportReply(
        text: 'Opening your profile editor so you can update your information.',
        quickReplies: const ['Where is my order?', 'Change delivery address'],
        action: OrderSupportAction.openEditProfile,
      );
    }

    if (_matches(q, const ['open addresses', 'my addresses'])) {
      return const OrderSupportReply(
        text: 'Opening your saved addresses.',
        quickReplies: const ['Update my profile', 'Where is my order?'],
        action: OrderSupportAction.openAddresses,
      );
    }

    if (_matches(q, const ['help', 'support', 'need help', 'what can you'])) {
      return welcome(order);
    }

    // Soft fallback still on-topic.
    return OrderSupportReply(
      text: 'I can help with this order’s tracking, payment, tips, cancellation, '
          'and your account/profile or address updates.\n\n'
          'Try one of these:',
      quickReplies: welcomeQuickReplies,
    );
  }

  static OrderSupportReply _statusReply(LiveOrder? order) {
    if (order == null) {
      return const OrderSupportReply(
        text: 'I couldn’t load this order yet. Pull to refresh on Track order, '
            'then ask again.',
        quickReplies: welcomeQuickReplies,
      );
    }
    final status = _statusLabel(order.status);
    final detail = switch (order.status) {
      OrderStatus.orderPlaced =>
        'We’ve received your order and the store is preparing it.',
      OrderStatus.deliveryAssigned =>
        'A delivery partner is assigned and heading to pick up your order.',
      OrderStatus.outForDelivery =>
        'A delivery partner is on the way to you. Watch the live map on '
            'Track order for progress.',
      OrderStatus.delivered =>
        'This order is delivered. Enjoy your groceries!',
      OrderStatus.cancelled || OrderStatus.vendorRejected =>
        'This order was cancelled. You can reorder from the Track order screen.',
    };

    return OrderSupportReply(
      text: 'Order #${_shortId(order.id)} is currently: $status.\n\n$detail',
      quickReplies: const [
        'When will it arrive?',
        'Delivery partner',
        'Update my profile',
        'Cancel order',
      ],
    );
  }

  static OrderSupportReply _etaReply(LiveOrder? order) {
    if (order == null) {
      return const OrderSupportReply(
        text: 'Open Track order to see the live ETA on the map.',
        quickReplies: welcomeQuickReplies,
      );
    }
    if (order.isDelivered) {
      return const OrderSupportReply(
        text: 'This order is already delivered — no ETA needed.',
        quickReplies: ['Update my profile', 'Order items'],
      );
    }
    if (order.isCancelled) {
      return const OrderSupportReply(
        text: 'This order was cancelled, so there’s no delivery ETA.',
        quickReplies: ['Update my profile', 'Where is my order?'],
      );
    }
    final slot = (order.slotLabel ?? '').trim();
    final slotLine = slot.isNotEmpty
        ? 'Scheduled slot: $slot.'
        : (order.slotExpress
            ? 'This is an express delivery.'
            : 'We’re delivering as soon as it’s ready.');

    return OrderSupportReply(
      text: '$slotLine\n\n'
          'Check the live map on Track order for the most accurate arrival time. '
          'Status right now: ${_statusLabel(order.status)}.',
      quickReplies: const [
        'Where is my order?',
        'Delivery partner',
        'Update my profile',
      ],
    );
  }

  static OrderSupportReply _riderReply(LiveOrder? order) {
    if (order == null) {
      return const OrderSupportReply(
        text: 'I couldn’t load rider details yet. Try again in a moment.',
        quickReplies: welcomeQuickReplies,
      );
    }
    if (order.hasRider) {
      return OrderSupportReply(
        text: 'A delivery partner is assigned to order #${_shortId(order.id)}.\n\n'
            'You’ll see their live location on the Track order map once they’re '
            'moving toward you.',
        quickReplies: const [
          'Where is my order?',
          'When will it arrive?',
          'Add a tip',
        ],
      );
    }
    return OrderSupportReply(
      text: 'A delivery partner isn’t assigned yet. '
          'Current status: ${_statusLabel(order.status)}.\n\n'
          'You’ll get an update here as soon as someone picks up your order.',
      quickReplies: const [
        'Where is my order?',
        'When will it arrive?',
        'Update my profile',
      ],
    );
  }

  static OrderSupportReply _cancelReply(LiveOrder? order) {
    if (order == null) {
      return const OrderSupportReply(
        text: 'Open Track order and use Cancel if the order still allows it.',
        quickReplies: welcomeQuickReplies,
      );
    }
    if (order.isCancelled) {
      return const OrderSupportReply(
        text: 'This order is already cancelled.',
        quickReplies: ['Update my profile', 'Order items'],
      );
    }
    if (order.isDelivered) {
      return const OrderSupportReply(
        text: 'Delivered orders can’t be cancelled. '
            'If something’s wrong with an item, tell me and I’ll guide you.',
        quickReplies: ['Order items', 'Update my profile'],
      );
    }
    if (order.status == OrderStatus.outForDelivery || order.hasRider) {
      return const OrderSupportReply(
        text: 'Once a delivery partner is assigned / out for delivery, '
            'cancellation may not be available from the app.\n\n'
            'Use Cancel on Track order if the button is still enabled, '
            'otherwise wait for delivery and report an issue after.',
        quickReplies: const [
          'Where is my order?',
          'Delivery partner',
          'Update my profile',
        ],
      );
    }
    return const OrderSupportReply(
      text: 'You can cancel from the Track order screen before pickup.\n\n'
          'Tap Cancel order there — this can’t be undone.',
      quickReplies: const [
        'Where is my order?',
        'Update my profile',
        'Payment status',
      ],
    );
  }

  static OrderSupportReply _tipReply(LiveOrder? order) {
    return const OrderSupportReply(
      text: 'You can tip your delivery partner from the yellow tip card '
          'on the Track order screen (Add ₹10 / ₹20 / ₹50 or Custom Tip).\n\n'
          'Tips show appreciation and go to your delivery partner.',
      quickReplies: [
        'Where is my order?',
        'Delivery partner',
        'Update my profile',
      ],
    );
  }

  static OrderSupportReply _paymentReply(LiveOrder? order) {
    if (order == null) {
      return const OrderSupportReply(
        text: 'Check payment details on Track order → Order details / Invoice.',
        quickReplies: welcomeQuickReplies,
      );
    }
    final paid = order.isPaid ? 'Paid' : 'Pending / unpaid';
    final method = order.paymentMethodId.trim().isEmpty
        ? '—'
        : order.paymentMethodId;
    return OrderSupportReply(
      text: 'Payment for order #${_shortId(order.id)}:\n'
          '• Status: $paid (${order.paymentStatus})\n'
          '• Method: $method\n\n'
          'Use Invoice on Track order for a shareable bill.',
      quickReplies: const [
        'Where is my order?',
        'Order items',
        'Update my profile',
      ],
    );
  }

  static OrderSupportReply _itemsReply(LiveOrder? order) {
    if (order == null || order.legacy.products.isEmpty) {
      return const OrderSupportReply(
        text: 'I couldn’t find items for this order yet.',
        quickReplies: welcomeQuickReplies,
      );
    }
    final lines = order.legacy.products.take(8).map((p) {
      final qty = p.itemCount;
      final name = p.name.trim().isEmpty ? 'Item' : p.name.trim();
      return '• $name × $qty';
    }).join('\n');
    final extra = order.legacy.products.length > 8
        ? '\n…and ${order.legacy.products.length - 8} more'
        : '';
    return OrderSupportReply(
      text: 'Items in this order:\n$lines$extra\n\n'
          'See full details on the Track order screen.',
      quickReplies: const [
        'Where is my order?',
        'Payment status',
        'Update my profile',
      ],
    );
  }

  static bool _isOffTopic(String q) {
    const shopping = [
      'buy',
      'add to cart',
      'discount',
      'offer',
      'coupon',
      'amul',
      'milk',
      'vegetables',
      'suggest',
      'recommend',
      'breakfast',
      'recipe',
      'price of',
      'do you have',
      'stock of',
    ];
    // Allow "order items" etc. — only flag pure shopping intent.
    if (_matches(q, const ['where is my order', 'order status', 'my order'])) {
      return false;
    }
    return _matches(q, shopping) &&
        !_matches(q, const [
          'order',
          'delivery',
          'profile',
          'account',
          'address',
          'cancel',
          'payment',
          'invoice',
          'tip',
        ]);
  }

  static bool _matches(String q, List<String> keys) {
    for (final k in keys) {
      if (q.contains(k)) return true;
    }
    return false;
  }

  static String _shortId(String? id) {
    if (id == null || id.isEmpty) return '—';
    if (id.length <= 6) return id.toUpperCase();
    return id.substring(id.length - 6).toUpperCase();
  }

  static String _statusLabel(OrderStatus status) {
    return switch (status) {
      OrderStatus.orderPlaced => 'Order placed',
      OrderStatus.deliveryAssigned => 'Delivery partner assigned',
      OrderStatus.outForDelivery => 'Out for delivery',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Cancelled',
      OrderStatus.vendorRejected => 'Cancelled by store',
    };
  }
}
