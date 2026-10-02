# AI Chat audit & rebuild report

Date: 2026-07-30

## 1. Root cause(s)

1. **No AI system existed.** The only chat was order `support_messages` (customer → Firestore). Nobody (admin or Cloud Function) wrote `author: support` replies, so the thread looked “broken / AI silent.”
2. **No LLM callable, models, roles, typing, or product-grounded answers.**

## 2. Files modified / added

### Backend (`quick_grocery_admin/functions`)
- `src/ai/gemini_config.ts` (new)
- `src/ai/grocery_context.ts` (new)
- `src/ai/assistant_engine.ts` (new)
- `src/ai/ai_assistant_callable.ts` (new) → export `aiGroceryAssistant`
- `src/index.ts` (export)

### Flutter (`quickgrocery_user`)
- `lib/view/ai_chat/**` (models, API, local store, providers, UI, entry)
- `profile_sections.dart` — Support list tile
- `landing_screen.dart` — Ask AI FAB

## 3. Backend / API issues found

- Zero OpenAI/Gemini/Anthropic integrations previously
- Support chat had no server auto-reply path
- Secrets correctly planned server-side (Gemini key never in app)

## 4. Frontend issues found

- Support chat: silent send failures, no typing, no roles (`author` only), order-scoped only
- Rider “chat” icon opened human support, not a bot

## 5. State management

- New Riverpod `AiChatController` with explicit `user` / `assistant` roles, typing flag, local persistence
- History sent with each request for session context

## 6. UI improvements

- Bubbles, avatar, timestamps, typing dots, quick replies, product mini-cards, dark/light theme

## 7. Performance

- ListView chat (not full-tree rebuild of app)
- Product cards fetched by id batch (`whereIn`)
- History capped at 80 locally / 12 in API payload

## 8. Security

- Auth-gated callable
- Catalog-grounding + id allow-list
- No client-side API keys

## 9. Remaining recommendations

1. Deploy `aiGroceryAssistant` and set `GEMINI_API_KEY` for natural-language quality
2. Add composite product search index / Algolia for large catalogs
3. Store server-side chat transcripts under `users/{uid}/ai_chats` for QA
4. Keep order **Support Chat** for human agents; escalate CTA from AI when needed
5. Markdown renderer for assistant replies if richer formatting is desired

## Confirmation

The grocery AI chat is implemented end-to-end: every signed-in user message receives a structured assistant response (Gemini when configured, otherwise catalog-grounded). Product recommendations render as tappable cards opening Product Details.
