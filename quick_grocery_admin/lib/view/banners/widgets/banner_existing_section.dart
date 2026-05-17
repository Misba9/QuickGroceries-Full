import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/model/banner_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/banners/banner_theme.dart';
import 'package:quick_grocery_admin/view/banners/models/banner_form_state.dart';
import 'package:quick_grocery_admin/view/banners/services/banner_asset_downloader.dart';
import 'package:quick_grocery_admin/view/banners/widgets/banner_video_player_dialog.dart';

/// Grid of existing banners with compact cards.
class BannerExistingSection extends StatelessWidget {
  const BannerExistingSection({
    super.key,
    required this.banners,
    required this.loading,
    required this.searchQuery,
    required this.filter,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onToggleActive,
  });

  final List<BannerModel> banners;
  final bool loading;
  final String searchQuery;
  final BannerListFilter filter;
  final ValueChanged<BannerModel> onEdit;
  final ValueChanged<BannerModel> onDuplicate;
  final ValueChanged<BannerModel> onDelete;
  final void Function(BannerModel banner, bool active) onToggleActive;

  List<BannerModel> get _filtered {
    var list = banners;
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (b) =>
                b.title.toLowerCase().contains(q) ||
                b.subtitle.toLowerCase().contains(q) ||
                b.id.toLowerCase().contains(q),
          )
          .toList();
    }
    return list.where((b) {
      switch (filter) {
        case BannerListFilter.all:
          return true;
        case BannerListFilter.active:
          return b.lifecycleStatus == BannerLifecycleStatus.active;
        case BannerListFilter.inactive:
          return b.lifecycleStatus == BannerLifecycleStatus.inactive;
        case BannerListFilter.scheduled:
          return b.lifecycleStatus == BannerLifecycleStatus.scheduled;
        case BannerListFilter.image:
          return b.isImage;
        case BannerListFilter.video:
          return b.isVideo;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Existing banners',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${filtered.length} banner${filtered.length == 1 ? '' : 's'}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (loading && banners.isEmpty)
          const _BannerSkeletonGrid()
        else if (filtered.isEmpty)
          const _EmptyBanners()
        else
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final cols = w >= 900 ? 3 : (w >= 560 ? 2 : 1);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: cols == 1 ? 1.35 : 0.82,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _BannerListCard(
                  banner: filtered[i],
                  onEdit: () => onEdit(filtered[i]),
                  onDuplicate: () => onDuplicate(filtered[i]),
                  onDelete: () => onDelete(filtered[i]),
                  onToggleActive: (v) => onToggleActive(filtered[i], v),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _BannerListCard extends StatefulWidget {
  const _BannerListCard({
    required this.banner,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onToggleActive,
  });

  final BannerModel banner;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  @override
  State<_BannerListCard> createState() => _BannerListCardState();
}

class _BannerListCardState extends State<_BannerListCard> {
  bool _hover = false;
  bool _downloading = false;

  bool get _hasDownloadableMedia {
    final b = widget.banner;
    if (b.isVideo && b.video.isNotEmpty) return true;
    if (b.image.isNotEmpty) return true;
    if (b.thumbnailUrl.isNotEmpty) return true;
    return false;
  }

  Future<void> _download() async {
    if (_downloading || !_hasDownloadableMedia) return;
    setState(() => _downloading = true);
    try {
      await downloadBannerAsset(widget.banner);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Downloaded ${bannerDownloadFilename(widget.banner)}',
          ),
        ),
      );
    } on BannerDownloadException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.banner;
    final status = b.lifecycleStatus;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BannerTheme.cardDecoration(hovered: _hover),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: GestureDetector(
                  onTap: b.isVideo && b.video.isNotEmpty
                      ? () => showDialog<void>(
                            context: context,
                            builder: (_) => BannerVideoPlayerDialog(
                              videoUrl: b.video,
                            ),
                          )
                      : null,
                  child: _Thumb(banner: b),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.title.isEmpty ? 'Untitled banner' : b.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Badge(
                        label: switch (status) {
                          BannerLifecycleStatus.active => 'Active',
                          BannerLifecycleStatus.inactive => 'Inactive',
                          BannerLifecycleStatus.scheduled => 'Scheduled',
                        },
                        color: switch (status) {
                          BannerLifecycleStatus.active => Colors.green,
                          BannerLifecycleStatus.inactive => Colors.grey,
                          BannerLifecycleStatus.scheduled => Colors.orange,
                        },
                      ),
                      if (b.showInHome) const _Badge(label: 'Home', color: Colors.blue),
                      if (b.showInOffers) const _Badge(label: 'Offers', color: Colors.purple),
                      if (b.showAsPopup) const _Badge(label: 'Popup', color: Colors.teal),
                      _Badge(
                        label: 'P${b.priority}',
                        color: AppColor.primary,
                        textDark: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_fmt(b.viewCount)} views · ${_fmt(b.clickCount)} clicks · ${b.ctrPercent.toStringAsFixed(1)}% CTR',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              visualDensity: VisualDensity.compact,
                              onPressed: widget.onEdit,
                              icon: const Icon(Icons.edit_outlined, size: 20),
                            ),
                            IconButton(
                              tooltip: 'Duplicate',
                              visualDensity: VisualDensity.compact,
                              onPressed: widget.onDuplicate,
                              icon: const Icon(Icons.copy_outlined, size: 20),
                            ),
                            IconButton(
                              tooltip: 'Download',
                              visualDensity: VisualDensity.compact,
                              onPressed: _hasDownloadableMedia && !_downloading
                                  ? _download
                                  : null,
                              icon: _downloading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.grey.shade600,
                                      ),
                                    )
                                  : Icon(
                                      Icons.download_outlined,
                                      size: 20,
                                      color: _hasDownloadableMedia
                                          ? null
                                          : Colors.grey.shade400,
                                    ),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              visualDensity: VisualDensity.compact,
                              onPressed: widget.onDelete,
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: b.isActive,
                        activeThumbColor: AppColor.primary,
                        onChanged: widget.onToggleActive,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  String _downloadLabel(BannerModel b) =>
      b.isVideo ? 'video' : 'image';
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.banner});
  final BannerModel banner;

  @override
  Widget build(BuildContext context) {
    if (banner.isVideo) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (banner.thumbnailUrl.isNotEmpty)
            Image.network(banner.thumbnailUrl, fit: BoxFit.cover)
          else
            Container(color: Colors.black87),
          const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
          ),
        ],
      );
    }
    if (banner.image.isNotEmpty) {
      return Image.network(
        banner.image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFE8EAED),
        child: const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.textDark = false,
  });

  final String label;
  final Color color;
  final bool textDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: textDark ? 0.35 : 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textDark ? const Color(0xFF1A1A1A) : color.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _EmptyBanners extends StatelessWidget {
  const _EmptyBanners();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BannerTheme.cardDecoration(),
      child: Column(
        children: [
          Icon(Icons.campaign_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No banners yet',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first promotional banner above',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _BannerSkeletonGrid extends StatelessWidget {
  const _BannerSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        decoration: BannerTheme.cardDecoration(),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 120, color: Colors.grey.shade100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
