import 'package:flutter/material.dart';

import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/view/ai_chat/presentation/screens/ai_chat_screen.dart';

/// Opens the grocery AI assistant screen.
Future<void> openAiAssistant(BuildContext context) {
  return Navigator.of(context).push(
    AppPageRoutes.material(
      name: 'ai_chat',
      builder: (_) => const AiChatScreen(),
    ),
  );
}
