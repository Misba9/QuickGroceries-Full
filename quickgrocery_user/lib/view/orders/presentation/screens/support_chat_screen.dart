import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/loading.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/view/orders/domain/order_models.dart';
import 'package:quickgrocery/view/orders/domain/order_support_bot.dart';
import 'package:quickgrocery/view/orders/presentation/providers/orders_providers.dart';
import 'package:quickgrocery/view/profile/presentation/providers/profile_providers.dart';
import 'package:quickgrocery/view/profile/screens/edit_profile_screen.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';

/// AI Order Support chat — scoped to this order + account/profile updates.
class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _ChatLine {
  _ChatLine({
    required this.id,
    required this.text,
    required this.isUser,
    required this.at,
    this.quickReplies = const [],
    this.action = OrderSupportAction.none,
    this.typing = false,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime at;
  final List<String> quickReplies;
  final OrderSupportAction action;
  final bool typing;
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final _rng = Random();

  final List<_ChatLine> _lines = [];
  bool _sending = false;
  bool _booted = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  LiveOrder? get _order =>
      ref.read(orderByIdStreamProvider(widget.orderId)).valueOrNull;

  void _bootIfNeeded(LiveOrder? order) {
    if (_booted) return;
    _booted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final welcome = OrderSupportBot.welcome(order);
      setState(() {
        _lines.add(
          _ChatLine(
            id: 'welcome',
            text: welcome.text,
            isUser: false,
            at: DateTime.now(),
            quickReplies: welcome.quickReplies,
            action: welcome.action,
          ),
        );
      });
      _scrollToEnd();
    });
  }

  String _newId() =>
      'm_${DateTime.now().microsecondsSinceEpoch}_${_rng.nextInt(9999)}';

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 160,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _handleAction(OrderSupportAction action) async {
    if (!mounted) return;
    switch (action) {
      case OrderSupportAction.openEditProfile:
        final profile = ref.read(customerProfileStreamProvider).valueOrNull;
        if (profile == null) {
          AppSnackBar.error(
            'Couldn’t load your profile yet. Try again in a moment.',
            context: context,
          );
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditProfileScreen(profile: profile),
          ),
        );
      case OrderSupportAction.openAddresses:
        await Navigator.push(context, AppPageRoutes.address());
      case OrderSupportAction.none:
        break;
    }
  }

  Future<void> _submit([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;

    HapticFeedback.selectionClick();
    if (preset == null) _controller.clear();

    setState(() {
      _sending = true;
      _lines.add(
        _ChatLine(
          id: _newId(),
          text: text,
          isUser: true,
          at: DateTime.now(),
        ),
      );
      _lines.add(
        _ChatLine(
          id: 'typing',
          text: '',
          isUser: false,
          at: DateTime.now(),
          typing: true,
        ),
      );
    });
    _scrollToEnd();

    // Brief typing delay for a natural feel (UI only).
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;

    final reply = OrderSupportBot.reply(message: text, order: _order);
    setState(() {
      _lines.removeWhere((l) => l.typing);
      _lines.add(
        _ChatLine(
          id: _newId(),
          text: reply.text,
          isUser: false,
          at: DateTime.now(),
          quickReplies: reply.quickReplies,
          action: reply.action,
        ),
      );
      _sending = false;
    });
    _scrollToEnd();

    if (reply.action != OrderSupportAction.none) {
      await Future<void>.delayed(const Duration(milliseconds: 280));
      if (mounted) await _handleAction(reply.action);
    }
  }

  List<String> get _activeQuickReplies {
    for (final line in _lines.reversed) {
      if (!line.isUser && !line.typing && line.quickReplies.isNotEmpty) {
        return line.quickReplies;
      }
    }
    return OrderSupportBot.welcomeQuickReplies;
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdStreamProvider(widget.orderId));
    // Keep profile warm for "Open edit profile" deep-link.
    ref.watch(customerProfileStreamProvider);
    final order = orderAsync.valueOrNull;
    _bootIfNeeded(order);

    final surface = AppSurface.of(context);

    return Scaffold(
      backgroundColor: surface.scaffold,
      appBar: AppBar(
        title: Text(
          'Order support',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: surface.card,
        foregroundColor: surface.text,
        elevation: 0.4,
      ),
      body: Column(
        children: [
          if (order != null) _OrderContextStrip(order: order),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: _lines.length,
              itemBuilder: (context, i) {
                final line = _lines[i];
                if (line.typing) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 10, left: 4),
                      child: _TypingDots(),
                    ),
                  );
                }
                return _Bubble(line: line);
              },
            ),
          ),
          if (!_sending)
            _QuickOptions(
              options: _activeQuickReplies,
              onTap: _submit,
            ),
          _Composer(
            controller: _controller,
            focusNode: _focus,
            sending: _sending,
            onSend: () => _submit(),
          ),
        ],
      ),
    );
  }
}

class _OrderContextStrip extends StatelessWidget {
  const _OrderContextStrip({required this.order});

  final LiveOrder order;

  static String _friendlyStatus(OrderStatus status) {
    return switch (status) {
      OrderStatus.orderPlaced => 'Order placed',
      OrderStatus.deliveryAssigned => 'Partner assigned',
      OrderStatus.outForDelivery => 'Out for delivery',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Cancelled',
      OrderStatus.vendorRejected => 'Cancelled by store',
    };
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    final id = order.id.length > 6
        ? order.id.substring(order.id.length - 6).toUpperCase()
        : order.id.toUpperCase();
    return Material(
      color: surface.card,
      child: InkWell(
        onTap: () => Navigator.maybePop(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: surface.border)),
          ),
          child: Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 18, color: AppColor.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Order #$id · ${_friendlyStatus(order.status)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: surface.textSecondary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: surface.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.line});

  final _ChatLine line;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    final mine = line.isUser;
    final time = DateFormat('hh:mm a').format(line.at);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppColor.primary : surface.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine ? null : Border.all(color: surface.border),
          boxShadow: AppShadow.dim,
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              line.text,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: mine ? Colors.black87 : surface.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: mine ? Colors.black54 : surface.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickOptions extends StatelessWidget {
  const _QuickOptions({required this.options, required this.onTap});

  final List<String> options;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = options[i];
          return Material(
            color: surface.card,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: InkWell(
              onTap: () => onTap(label),
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: AppColor.primary.withValues(alpha: 0.55)),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: surface.text,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: GoogleFonts.poppins(
                    color: surface.textMuted,
                    fontSize: 13.5,
                  ),
                  filled: true,
                  fillColor: surface.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: surface.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColor.primary.withValues(alpha: 0.45),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColor.primary, width: 1.6),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColor.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: sending ? null : onSend,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: sending
                        ? AppLoading.spinner(size: 18, color: Colors.black87)
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.black87,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: surface.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: surface.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_c.value + i * 0.2) % 1.0;
              final dy = (t < 0.5 ? t : 1 - t) * -4;
              return Transform.translate(
                offset: Offset(0, dy),
                child: Container(
                  width: 7,
                  height: 7,
                  margin: EdgeInsets.only(right: i == 2 ? 0 : 5),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
