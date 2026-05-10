import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';

import '../design/app_tokens.dart';

/// Modern, Zepto/Blinkit-inspired search bar.
///
/// Two operating modes:
///   1. **Tappable** (default) — looks like a search field, but tapping
///      runs [onTap] and lets the host screen push a search route. Great
///      for the home screen.
///   2. **Live** — pass a [controller] / [onChanged] and the field
///      becomes a real, editable input with a clear button.
///
/// In tappable mode, the placeholder cycles through a list of [hints]
/// every 2.5s with a fade animation, mimicking the rotating placeholder
/// you see on Zepto.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    this.hints = const ['Search "milk"', 'Search "bread"', 'Search "snacks"'],
    this.onTap,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.showMic = true,
    this.onMicTap,
    this.live = false,
  });

  /// Rotating hint texts (tappable mode only).
  final List<String> hints;
  final VoidCallback? onTap;

  /// Live controller (live mode).
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  final bool showMic;
  final VoidCallback? onMicTap;

  /// If true, renders a real editable input; otherwise, a tappable label.
  final bool live;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  int _hintIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!widget.live && widget.hints.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
        if (!mounted) return;
        setState(() => _hintIndex = (_hintIndex + 1) % widget.hints.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadii.all(AppRadii.pill),
      elevation: 0,
      child: InkWell(
        borderRadius: AppRadii.all(AppRadii.pill),
        onTap: widget.live ? null : widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadii.all(AppRadii.pill),
            border: Border.all(
              color: AppSurface.border.withValues(alpha: 0.65),
            ),
            boxShadow: AppShadow.raised,
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded,
                  color: AppColor.primary.withValues(alpha: 0.85), size: 22),
              const SizedBox(width: 14),
              Expanded(child: _buildField()),
              if (widget.live && widget.controller != null &&
                  widget.controller!.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppSurface.textMuted, size: 18),
                  onPressed: () {
                    widget.controller?.clear();
                    widget.onChanged?.call('');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24, minHeight: 24,
                  ),
                ),
              if (widget.showMic) ...[
                const SizedBox(width: 6),
                _MicButton(onTap: widget.onMicTap),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField() {
    if (widget.live) {
      return TextField(
        controller: widget.controller,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        textInputAction: TextInputAction.search,
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: AppSurface.textPrimary,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText:
              widget.hints.isEmpty ? 'Search products...' : widget.hints.first,
          hintStyle: GoogleFonts.poppins(
            fontSize: 13.5,
            color: AppSurface.textMuted,
          ),
        ),
      );
    }

    final hint = widget.hints.isEmpty ? 'Search products...' : widget.hints[_hintIndex];
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.4),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(
        hint,
        key: ValueKey(hint),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: AppSurface.textMuted,
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      radius: 22,
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppSurface.subtle,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.mic_rounded,
          size: 18,
          color: AppSurface.textPrimary,
        ),
      ),
    );
  }
}
