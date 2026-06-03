import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/model/banner_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/banners/banner_theme.dart';
import 'package:quick_grocery_admin/view/banners/models/banner_form_state.dart';
import 'package:quick_grocery_admin/view/banners/services/banner_asset_downloader.dart';
import 'package:quick_grocery_admin/view/banners/widgets/banner_video_player_dialog.dart';

/// Existing banners list — shrink-wrapped inside [AdminPageWrapper] scroll.
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
      mainAxisSize: MainAxisSize.min,
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
          const _BannerListSkeleton()
        else if (filtered.isEmpty)
          const _EmptyBanners()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final b = filtered[index];
              return _BannerListRow(
                banner: b,
                onEdit: () => onEdit(b),
                onDuplicate: () => onDuplicate(b),
                onDelete: () => onDelete(b),
                onToggleActive: (v) => onToggleActive(b, v),
              );
            },
          ),
      ],
    );
  }
}

class _BannerListRow extends StatefulWidget {
  const _BannerListRow({
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
  State<_BannerListRow> createState() => _BannerListRowState();
}

class _BannerListRowState extends State<_BannerListRow> {
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

    return Material(
      color: BannerTheme.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BannerTheme.cardRadius,
        side: const BorderSide(color: BannerTheme.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onEdit,
        borderRadius: BannerTheme.cardRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: b.isVideo && b.video.isNotEmpty
                      ? Material(
                          color: Colors.black12,
                          child: InkWell(
                            onTap: () => showDialog<void>(
                              context: context,
                              builder: (_) => BannerVideoPlayerDialog(
                                videoUrl: b.video,
                              ),
                            ),
                            child: _Thumb(banner: b),
                          ),
                        )
                      : _Thumb(banner: b),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 6),
                    Text(
                      '${_fmt(b.viewCount)} views · ${_fmt(b.clickCount)} clicks · ${b.ctrPercent.toStringAsFixed(1)}% CTR',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: b.isActive,
                    activeThumbColor: AppColor.primary,
                    onChanged: widget.onToggleActive,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
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
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
          ),
        ],
      );
    }
    if (banner.image.isNotEmpty) {
      return Image.network(
        banner.image,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFE8EAED),
        child: const Icon(Icons.image_outlined, size: 32, color: Colors.grey),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BannerTheme.cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No banners yet',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first promotional banner below',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _BannerListSkeleton extends StatelessWidget {
  const _BannerListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 112,
        decoration: BannerTheme.cardDecoration(),
      ),
    );
  }
}
