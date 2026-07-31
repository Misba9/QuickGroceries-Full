import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';

/// Opens the grocery AI assistant (bottom nav tab).
Future<void> openAiAssistant(BuildContext context) async {
  legacy.Provider.of<HomeProvider>(context, listen: false)
      .onSelectedChange(AppRoutes.aiChatTabIndex);
}
