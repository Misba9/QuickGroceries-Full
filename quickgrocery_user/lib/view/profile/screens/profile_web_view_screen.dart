import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:quickgrocery/core/loading/loading.dart';

class ProfileWebViewScreen extends StatefulWidget {
  const ProfileWebViewScreen({
    super.key,
    required this.url,
    this.title,
  });

  final String url;
  final String? title;

  @override
  State<ProfileWebViewScreen> createState() => _ProfileWebViewScreenState();
}

class _ProfileWebViewScreenState extends State<ProfileWebViewScreen> {
  WebViewController? _controller;
  bool _loading = true;
  bool _fallbackTriggered = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _loading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onWebResourceError: (_) => _fallbackToBrowser(),
          ),
        )
        ..loadRequest(Uri.parse(widget.url));

      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (_) {
      await _fallbackToBrowser();
    }
  }

  Future<void> _fallbackToBrowser() async {
    if (_fallbackTriggered) return;
    _fallbackTriggered = true;

    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reload() async {
    await _controller?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = widget.title ?? 'Quick Groceries';

    return Scaffold(
      backgroundColor: AppSurface.of(context).background,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        foregroundColor: AppSurface.of(context).text,
        title: Text(
          pageTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          if (_controller != null)
            IconButton(
              tooltip: 'Reload',
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          IconButton(
            tooltip: 'Open in browser',
            onPressed: _fallbackToBrowser,
            icon: const Icon(Icons.open_in_browser_rounded),
          ),
        ],
      ),
      body: _controller == null
          ? AppLoading.center
          : Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_loading)
                  const Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: 28,
                      child: AppLoading.micro,
                    ),
                  ),
              ],
            ),
    );
  }
}
