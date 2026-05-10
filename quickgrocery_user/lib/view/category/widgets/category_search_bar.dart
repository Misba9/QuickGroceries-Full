import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';

/// Inline search field used inside [CategoryScreen]'s sticky app-bar
/// region. Emits keystrokes via [onChanged] so the screen can debounce
/// or filter live.
///
/// Visuals:
/// * Pill shape, soft surface, subtle shadow.
/// * Search icon on the left.
/// * Trailing **clear** button when there's text, otherwise a
///   **mic** icon (placeholder hook for voice search).
class CategorySearchBar extends StatefulWidget {
  const CategorySearchBar({
    super.key,
    required this.onChanged,
    this.onMicTap,
    this.hint = 'Search products',
  });

  final ValueChanged<String> onChanged;
  final VoidCallback? onMicTap;
  final String hint;

  @override
  State<CategorySearchBar> createState() => _CategorySearchBarState();
}

class _CategorySearchBarState extends State<CategorySearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppSurface.border),
        boxShadow: AppShadow.dim,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppSurface.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (v) {
                widget.onChanged(v);
                setState(() {}); // refresh trailing icon
              },
              cursorColor: Colors.black,
              cursorHeight: 18,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: AppSurface.text,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: AppSurface.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              textAlignVertical: TextAlignVertical.center,
            ),
          ),
          AnimatedSwitcher(
            duration: AppMotion.short,
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: hasText
                ? IconButton(
                    key: const ValueKey('clear'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minHeight: 32, minWidth: 32),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppSurface.textMuted,
                    ),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                      setState(() {});
                    },
                  )
                : IconButton(
                    key: const ValueKey('mic'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minHeight: 32, minWidth: 32),
                    icon: const Icon(
                      Icons.mic_none_rounded,
                      size: 20,
                      color: AppSurface.textMuted,
                    ),
                    onPressed: widget.onMicTap,
                  ),
          ),
        ],
      ),
    );
  }
}
