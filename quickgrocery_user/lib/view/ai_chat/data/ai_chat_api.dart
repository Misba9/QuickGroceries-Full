import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/view/ai_chat/models/ai_chat_models.dart';

class AiChatApiException implements Exception {
  AiChatApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Talks to Cloud Function `aiGroceryAssistant` (Gemini + catalog grounding).
class AiChatApi {
  AiChatApi({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _fn;

  Future<AiChatResponse> send({
    required String message,
    required String sessionId,
    required List<AiChatMessage> history,
  }) async {
    final payload = {
      'message': message,
      'sessionId': sessionId,
      'history': history
          .where((m) => m.role != AiChatRole.system)
          .where((m) => m.status != AiChatStatus.error)
          .map((m) => m.toApiHistoryTurn())
          .toList(),
    };

    if (kDebugMode) {
      debugPrint(
        '[AiChatApi] → session=$sessionId msgLen=${message.length} '
        'history=${payload['history'] is List ? (payload['history'] as List).length : 0}',
      );
    }

    try {
      final res = await _fn.httpsCallable('aiGroceryAssistant').call(payload);
      final data = Map<String, dynamic>.from(res.data as Map? ?? {});
      if (kDebugMode) {
        debugPrint(
          '[AiChatApi] ← source=${data['source']} intent=${data['intent']} '
          'latency=${data['latencyMs']}ms products=${(data['productIds'] as List?)?.length ?? 0}',
        );
      }
      final parsed = AiChatResponse.fromMap(data);
      if (parsed.reply.isEmpty) {
        throw AiChatApiException(
          'The assistant returned an empty reply. Please try again.',
          code: 'empty',
        );
      }
      return parsed;
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint('[AiChatApi] error code=${e.code} message=${e.message}');
      }
      throw AiChatApiException(_friendlyFunctionsError(e), code: e.code);
    } catch (e) {
      if (e is AiChatApiException) rethrow;
      throw AiChatApiException(
        'Could not reach the assistant. Check your connection and try again.',
      );
    }
  }

  String _friendlyFunctionsError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Please sign in to chat with the grocery assistant.';
      case 'resource-exhausted':
        return 'Too many requests. Please wait a moment and try again.';
      case 'deadline-exceeded':
        return 'The assistant timed out. Please try again.';
      case 'unavailable':
        return 'Assistant is temporarily unavailable. Please try again.';
      case 'failed-precondition':
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Assistant is not configured yet.';
      case 'invalid-argument':
        return e.message ?? 'That message could not be sent.';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Something went wrong. Please try again.';
    }
  }
}
