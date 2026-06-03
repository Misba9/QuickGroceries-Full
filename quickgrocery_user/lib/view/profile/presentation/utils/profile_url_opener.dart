import 'package:flutter/material.dart';
import 'package:quickgrocery/view/profile/screens/profile_web_view_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens legal/support URLs in an in-app webview, falling back to the browser.
Future<void> openProfileUrl(
  BuildContext context, {
  required String url,
  String? title,
}) async {
  try {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfileWebViewScreen(url: url, title: title),
      ),
    );
  } catch (_) {
    await _openExternalBrowser(url);
  }
}

Future<void> _openExternalBrowser(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
