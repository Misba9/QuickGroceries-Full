import 'dart:ui_web' as ui_web;

/// Ensures web text editing / platform-view integration is initialized.
/// Mitigates rare "DOM element for this text editing strategy is not active"
/// issues when the engine tree-shakes web-only symbols.
void ensureWebTextInputInitialized() {
  try {
    final _ = ui_web.platformViewRegistry;
    // ignore: unnecessary_statements
    _;
  } catch (_) {}
}
