import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/ai_chat/models/ai_chat_admin_models.dart';
import 'package:quick_grocery_admin/view/ai_chat/services/ai_chat_admin_service.dart';

/// Admin inbox for user-app Grocery AI assistant transcripts.
class AiChatInboxScreen extends StatefulWidget {
  const AiChatInboxScreen({super.key});

  @override
  State<AiChatInboxScreen> createState() => _AiChatInboxScreenState();
}

class _AiChatInboxScreenState extends State<AiChatInboxScreen> {
  final _service = AiChatAdminService();
  final _search = TextEditingController();
  AiChatSession? _selected;
  List<AiChatSession>? _callableSessions;
  bool _refreshing = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refreshFromServer() async {
    setState(() => _refreshing = true);
    try {
      final items = await _service.listSessionsViaCallable();
      if (!mounted) return;
      setState(() {
        _callableSessions = items;
        _refreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            items.isEmpty
                ? 'Still empty — send a chat from the User App first'
                : 'Loaded ${items.length} chat(s)',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _refreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refresh failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final pad = adminResponsivePadding(c.maxWidth);
        final wide = c.maxWidth >= 960;
        return ColoredBox(
          color: const Color(0xFFF8FAFC),
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'AI Chat Inbox',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search name, phone, message…',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Messages from the User App grocery assistant appear here live.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<List<AiChatSession>>(
                    stream: _service.watchSessions(),
                    builder: (context, snap) {
                      if (snap.hasError && _callableSessions == null) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Could not load chats.\n${snap.error}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed:
                                      _refreshing ? null : _refreshFromServer,
                                  icon: _refreshing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.refresh),
                                  label: const Text('Refresh from server'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (!snap.hasData && _callableSessions == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Prefer live Firestore; fall back to last callable refresh.
                      final live = snap.data ?? const <AiChatSession>[];
                      final source = live.isNotEmpty
                          ? live
                          : (_callableSessions ?? live);

                      final q = _search.text.trim().toLowerCase();
                      final sessions = source.where((s) {
                        if (q.isEmpty) return true;
                        return s.displayName.toLowerCase().contains(q) ||
                            s.customerPhone.toLowerCase().contains(q) ||
                            s.lastMessage.toLowerCase().contains(q) ||
                            s.uid.toLowerCase().contains(q);
                      }).toList();

                      if (sessions.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.forum_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  q.isEmpty
                                      ? 'No AI chats yet'
                                      : 'No chats match your search',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  q.isEmpty
                                      ? 'Open the User App → AI assistant, send a message,\nthen refresh here. Only chats after the latest\nfunction deploy appear in this inbox.'
                                      : 'Try a different name, phone, or message.',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed:
                                      _refreshing ? null : _refreshFromServer,
                                  icon: _refreshing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.refresh),
                                  label: const Text('Refresh from server'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final selected = _selected != null &&
                              sessions.any((s) => s.id == _selected!.id)
                          ? sessions.firstWhere((s) => s.id == _selected!.id)
                          : sessions.first;

                      if (_selected?.id != selected.id) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _selected = selected);
                        });
                      }

                      if (!wide) {
                        return _mobileLayout(sessions, selected);
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 340,
                            child: _sessionList(sessions, selected),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _transcript(selected)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mobileLayout(List<AiChatSession> sessions, AiChatSession selected) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: _sessionList(sessions, selected),
        ),
        const SizedBox(height: 12),
        Expanded(child: _transcript(selected)),
      ],
    );
  }

  Widget _sessionList(List<AiChatSession> sessions, AiChatSession selected) {
    final fmt = DateFormat('dd MMM, hh:mm a');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: sessions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final s = sessions[i];
          final active = s.id == selected.id;
          return ListTile(
            selected: active,
            selectedTileColor: AppColor.primary.withValues(alpha: 0.08),
            title: Text(
              s.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              s.lastMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  s.updatedAt != null ? fmt.format(s.updatedAt!) : '',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${s.messageCount}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
            onTap: () => setState(() => _selected = s),
          );
        },
      ),
    );
  }

  Widget _transcript(AiChatSession session) {
    final fmt = DateFormat('dd MMM, hh:mm a');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (session.customerPhone.isNotEmpty) session.customerPhone,
                    'UID ${session.uid}',
                    if (session.lastIntent.isNotEmpty)
                      'intent: ${session.lastIntent}',
                    if (session.lastSource.isNotEmpty)
                      'source: ${session.lastSource}',
                  ].join(' · '),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<AiChatMessageDoc>>(
              stream: _service.watchMessages(session.id),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snap.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages in this session.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final align =
                        m.isUser ? Alignment.centerRight : Alignment.centerLeft;
                    final bg = m.isUser
                        ? AppColor.primary.withValues(alpha: 0.15)
                        : const Color(0xFFF1F5F9);
                    final time = m.createdAt != null
                        ? fmt.format(m.createdAt!)
                        : '';
                    return Align(
                      alignment: align,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.isUser ? 'Customer' : 'AI Assistant',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                m.text,
                                style: const TextStyle(fontSize: 14, height: 1.35),
                              ),
                              if (m.productIds.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Products: ${m.productIds.join(', ')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                              if (time.isNotEmpty || m.source != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  [
                                    if (time.isNotEmpty) time,
                                    if (m.source != null) m.source!,
                                    if (m.latencyMs != null)
                                      '${m.latencyMs}ms',
                                  ].join(' · '),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
