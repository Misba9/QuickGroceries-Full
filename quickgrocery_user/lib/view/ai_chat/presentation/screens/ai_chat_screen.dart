import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/auth/guest_auth_guard.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/navigation/product_navigation.dart';
import 'package:quickgrocery/view/ai_chat/models/ai_chat_models.dart';
import 'package:quickgrocery/view/ai_chat/presentation/providers/ai_chat_providers.dart';
import 'package:quickgrocery/view/ai_chat/presentation/widgets/ai_chat_product_rail.dart';
import 'package:quickgrocery/view/ai_chat/presentation/widgets/ai_typing_indicator.dart';

/// Premium grocery AI assistant chat.
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _submit([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;

    final ok = await GuestAuthGuard.requireAuth(context, ref);
    if (!ok || !mounted) return;

    if (preset == null) _input.clear();
    await ref.read(aiChatControllerProvider.notifier).send(text);
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatControllerProvider);
    ref.listen(aiChatControllerProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.isTyping != next.isTyping) {
        _scrollToEnd();
      }
    });

    final surface = AppSurface.of(context);
    final lastAssistant = state.messages.reversed
        .where((m) => m.isAssistant && m.quickReplies.isNotEmpty)
        .firstOrNull;

    return Scaffold(
      backgroundColor: surface.scaffold,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grocery Assistant',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              state.isTyping ? 'Typing…' : 'Powered by QuickGrocery AI',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: surface.textMuted,
              ),
            ),
          ],
        ),
        backgroundColor: surface.card,
        foregroundColor: surface.textPrimary,
        elevation: 0.4,
        actions: [
          IconButton(
            tooltip: 'New chat',
            onPressed: () async {
              await ref.read(aiChatControllerProvider.notifier).clearChat();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: state.messages.length + (state.isTyping ? 1 : 0),
              itemBuilder: (context, i) {
                if (state.isTyping && i == state.messages.length) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 10, left: 4),
                    child: AiTypingIndicator(),
                  );
                }
                final msg = state.messages[i];
                return _MessageBlock(
                  message: msg,
                  onQuickReply: _submit,
                  onOpenProduct: (id) =>
                      ProductNavigation.openProductById(context, id),
                  onAddProduct: (id) =>
                      ProductNavigation.openProductById(context, id),
                );
              },
            ),
          ),
          if (lastAssistant != null && !state.isTyping)
            _QuickReplyBar(
              replies: lastAssistant.quickReplies,
              onTap: _submit,
            ),
          _Composer(
            controller: _input,
            focusNode: _focus,
            sending: state.sending,
            onSend: () => _submit(),
          ),
        ],
      ),
    );
  }
}

class _MessageBlock extends StatelessWidget {
  const _MessageBlock({
    required this.message,
    required this.onQuickReply,
    required this.onOpenProduct,
    required this.onAddProduct,
  });

  final AiChatMessage message;
  final ValueChanged<String> onQuickReply;
  final ValueChanged<String> onOpenProduct;
  final ValueChanged<String> onAddProduct;

  @override
  Widget build(BuildContext context) {
    final mine = message.isUser;
    final surface = AppSurface.of(context);
    final time = DateFormat('h:mm a').format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                mine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!mine) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColor.primary.withValues(alpha: 0.2),
                  child: const Icon(Icons.smart_toy_rounded, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: mine
                        ? AppColor.primary.withValues(alpha: 0.92)
                        : message.status == AiChatStatus.error
                            ? surface.danger.withValues(alpha: 0.1)
                            : surface.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(mine ? 16 : 4),
                      bottomRight: Radius.circular(mine ? 4 : 16),
                    ),
                    border: mine
                        ? null
                        : Border.all(color: surface.border.withValues(alpha: 0.7)),
                    boxShadow: AppShadow.dim,
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: mine
                          ? Colors.black
                          : message.status == AiChatStatus.error
                              ? surface.danger
                              : surface.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: mine ? 0 : 36, right: mine ? 4 : 0),
            child: Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: surface.textMuted,
              ),
            ),
          ),
          if (!mine && message.productIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            AiChatProductRail(
              productIds: message.productIds,
              onOpen: onOpenProduct,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickReplyBar extends StatelessWidget {
  const _QuickReplyBar({required this.replies, required this.onTap});

  final List<String> replies;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        scrollDirection: Axis.horizontal,
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final q = replies[i];
          return ActionChip(
            label: Text(
              q,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppSurface.of(context).card,
            side: BorderSide(color: AppSurface.of(context).border),
            onPressed: () => onTap(q),
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: surface.card,
          border: Border(top: BorderSide(color: surface.border)),
        ),
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
                  hintText: 'Ask about products, offers, orders…',
                  filled: true,
                  fillColor: surface.subtle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
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
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
