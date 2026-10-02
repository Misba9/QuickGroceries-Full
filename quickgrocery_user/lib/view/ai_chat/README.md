# Grocery AI Assistant

In-app shopping assistant for Quick Grocery (Flutter + Cloud Functions + Gemini).

## Architecture

```
User message
  → AiChatScreen (Riverpod)
  → AiChatApi (callable `aiGroceryAssistant`, region us-central1)
  → Cloud Function
      1. Auth check
      2. Catalog search (Firestore products)
      3. Offers + recent orders context
      4. Gemini 2.0 Flash (if GEMINI_API_KEY set)
      5. Else catalog-grounded structured reply
  → JSON { reply, productIds, quickReplies, intent, source }
  → UI bubbles + product cards + typing indicator
  → Local SharedPreferences history
```

## Deploy Functions

```bash
cd quick_grocery_admin/functions
npm run build
firebase deploy --only functions:aiGroceryAssistant
```

### Optional Gemini key (recommended)

```bash
firebase functions:secrets:set GEMINI_API_KEY
```

Then add to the callable options in `ai_assistant_callable.ts`:

```ts
import { geminiSecretBindings } from "./gemini_config";
// ...
secrets: geminiSecretBindings(),
```

Without a key, the assistant still answers from live catalog search (no invented products).

## Flutter entry points

- Home FAB: **Ask AI**
- Profile → Support → **Grocery Assistant**

Requires signed-in user for the callable (`GuestAuthGuard` on send).

## Message roles

| Role | Meaning |
|------|---------|
| `user` | Customer |
| `assistant` | AI |

Never mix roles — enforced in API history mapping.

## Security

- API key stays in Cloud Functions / Secret Manager only
- Callable requires Firebase Auth
- Prompts instruct model to use only CATALOG_RESULTS ids
- Client validates empty replies and maps HTTP/Functions errors to friendly copy
