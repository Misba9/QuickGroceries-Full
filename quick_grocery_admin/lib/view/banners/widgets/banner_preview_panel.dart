import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/view/banners/banner_theme.dart';
import 'package:quick_grocery_admin/view/banners/models/banner_form_state.dart';
import 'package:quick_grocery_admin/view/banners/widgets/banner_admin_card.dart';

/// Live preview: mobile home, desktop strip, startup popup.
class BannerPreviewPanel extends StatelessWidget {
  const BannerPreviewPanel({super.key, required this.data});

  final BannerPreviewData data;

  @override
  Widget build(BuildContext context) {
    return BannerAdminCard(
      title: 'Live preview',
      subtitle: 'Updates as you edit copy and media',
      child: Column(
        children: [
          _PreviewBlock(
            label: 'Mobile app',
            icon: Icons.phone_iphone,
            child: _MobileMockup(data: data),
          ),
          const SizedBox(height: 16),
          _PreviewBlock(
            label: 'Desktop banner',
            icon: Icons.desktop_windows_outlined,
            child: _DesktopBanner(data: data),
          ),
          const SizedBox(height: 16),
          _PreviewBlock(
            label: 'Startup popup',
            icon: Icons.open_in_new,
            child: _PopupPreview(data: data),
          ),
        ],
      ),
    );
  }
}

class _PreviewBlock extends StatelessWidget {
  const _PreviewBlock({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _MobileMockup extends StatelessWidget {
  const _MobileMockup({required this.data});
  final BannerPreviewData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: BannerTheme.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storefront, size: 16),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Quick Grocery',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              Icon(Icons.notifications_none, color: Colors.grey.shade600, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          _BannerMedia(data: data, height: 88, borderRadius: 12),
          const SizedBox(height: 8),
          if (data.title.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE8EAED)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopBanner extends StatelessWidget {
  const _DesktopBanner({required this.data});
  final BannerPreviewData data;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          _BannerMedia(data: data, height: 120, borderRadius: 0),
          Positioned(
            left: 16,
            bottom: 16,
            right: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.title.isNotEmpty)
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                    ),
                  ),
                if (data.subtitle.isNotEmpty)
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 12,
                      shadows: const [Shadow(blurRadius: 6, color: Colors.black45)],
                    ),
                  ),
              ],
            ),
          ),
          if (data.ctaText.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: BannerTheme.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data.ctaText,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PopupPreview extends StatelessWidget {
  const _PopupPreview({required this.data});
  final BannerPreviewData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                ),
                _BannerMedia(data: data, height: 100, borderRadius: 10),
                const SizedBox(height: 8),
                Text(
                  data.title.isEmpty ? 'Promo title' : data.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (data.subtitle.isNotEmpty)
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                const SizedBox(height: 8),
                if (data.ctaText.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: BannerTheme.primaryButtonStyle(),
                      onPressed: null,
                      child: Text(data.ctaText),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerMedia extends StatelessWidget {
  const _BannerMedia({
    required this.data,
    required this.height,
    this.borderRadius = 12,
  });

  final BannerPreviewData data;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (data.imageBytes != null) {
      child = Image.memory(data.imageBytes!, fit: BoxFit.cover, width: double.infinity);
    } else if (data.imageUrl != null && data.imageUrl!.isNotEmpty && !data.isVideo) {
      child = Image.network(
        data.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else if (data.isVideo) {
      child = Container(
        color: Colors.black87,
        child: const Center(
          child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
        ),
      );
    } else {
      child = _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: child,
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE8EAED),
      child: Center(
        child: Icon(
          data.isVideo ? Icons.videocam_outlined : Icons.image_outlined,
          color: Colors.grey.shade500,
          size: 32,
        ),
      ),
    );
  }
}
