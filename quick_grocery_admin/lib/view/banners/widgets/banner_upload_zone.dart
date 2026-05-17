import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/banners/banner_theme.dart';
import 'dart:typed_data';

/// Drag-style upload area (tap to pick on all platforms).
class BannerUploadZone extends StatefulWidget {
  const BannerUploadZone({
    super.key,
    required this.bannerType,
    required this.imageBytes,
    required this.videoSelected,
    required this.onPick,
    this.onPickThumbnail,
    this.thumbnailReady = false,
  });

  final String bannerType;
  final Uint8List? imageBytes;
  final bool videoSelected;
  final VoidCallback onPick;
  final VoidCallback? onPickThumbnail;
  final bool thumbnailReady;

  @override
  State<BannerUploadZone> createState() => _BannerUploadZoneState();
}

class _BannerUploadZoneState extends State<BannerUploadZone> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isImage = widget.bannerType == 'image';
    final hasPreview = isImage
        ? widget.imageBytes != null
        : widget.videoSelected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: widget.onPick,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: hasPreview ? 180 : 140,
              decoration: BoxDecoration(
                color: _hovering
                    ? AppColor.primary.withValues(alpha: 0.06)
                    : const Color(0xFFFAFAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _hovering ? AppColor.primary : const Color(0xFFDDE1E6),
                  width: _hovering ? 2 : 1.5,
                ),
              ),
              child: hasPreview
                  ? _buildPreview(isImage)
                  : _buildEmpty(isImage),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isImage
              ? 'Recommended: 1200×400px · JPG, PNG, WEBP · Max 5MB'
              : 'Recommended: 16:9 MP4 · Max 25MB · Thumbnail optional',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        if (!isImage && widget.onPickThumbnail != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: BannerTheme.outlineButtonStyle(),
              onPressed: widget.onPickThumbnail,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: Text(
                widget.thumbnailReady
                    ? 'Thumbnail ready — change'
                    : 'Upload thumbnail (recommended)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmpty(bool isImage) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isImage ? Icons.cloud_upload_outlined : Icons.video_file_outlined,
          size: 36,
          color: Colors.grey.shade500,
        ),
        const SizedBox(height: 8),
        Text(
          kIsWeb ? 'Click to upload' : 'Tap to upload',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          isImage ? 'or drag & drop here' : 'Select a video file',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPreview(bool isImage) {
    if (isImage && widget.imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(widget.imageBytes!, fit: BoxFit.cover),
      );
    }
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        Container(color: Colors.black87),
        const Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Video selected',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }
}
