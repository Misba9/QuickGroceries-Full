import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/core/theme/app_text_styles.dart';
import 'package:quick_grocery_admin/model/banner_model.dart';
import 'package:quick_grocery_admin/view/banners/banner_theme.dart';
import 'package:quick_grocery_admin/view/banners/models/banner_form_state.dart';
import 'package:quick_grocery_admin/view/banners/widgets/banner_analytics_row.dart';
import 'package:quick_grocery_admin/view/banners/widgets/banner_delete_dialog.dart';
import 'package:quick_grocery_admin/view/banners/widgets/banner_existing_section.dart';
import 'package:quick_grocery_admin/view/banners/widgets/banner_form_panel.dart';
import 'package:quick_grocery_admin/view/banners/widgets/banner_preview_panel.dart';
import 'package:quick_grocery_admin/view/home/services/dash_board_services.dart';

/// Premium banner management — scroll via [AdminPageSlot] / [AdminPageWrapper].
class AddBannerScreen extends StatefulWidget {
  const AddBannerScreen({super.key});

  @override
  State<AddBannerScreen> createState() => _AddBannerScreenState();
}

class _AddBannerScreenState extends State<AddBannerScreen> {
  final _form = BannerFormControllers();
  final _searchCtrl = TextEditingController();
  final _formScrollKey = GlobalKey();
  final _previewTick = ValueNotifier<int>(0);

  BannerListFilter _filter = BannerListFilter.all;

  @override
  void initState() {
    super.initState();
    for (final c in [_form.title, _form.subtitle, _form.cta, _form.redirectId]) {
      c.addListener(_bumpPreview);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashBoardServices>().fetchBanners();
      }
    });
  }

  void _bumpPreview() {
    if (!mounted) return;
    _previewTick.value++;
  }

  @override
  void dispose() {
    for (final c in [
      _form.title,
      _form.subtitle,
      _form.cta,
      _form.redirectId,
    ]) {
      c.removeListener(_bumpPreview);
    }
    _form.dispose();
    _searchCtrl.dispose();
    _previewTick.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (!mounted) return;
    _bumpPreview();
    setState(() {});
  }

  void _resetForm(DashBoardServices provider) {
    _form.reset();
    provider.resetBannerFormMedia();
    _onFormChanged();
  }

  void _loadBanner(BannerModel b, DashBoardServices provider, {bool duplicate = false}) {
    _form.loadFromBanner(b, duplicate: duplicate);
    provider.setBannerType(b.type);
    if (!duplicate) {
      provider.clearPickedMedia();
    }
    _scrollToForm();
    _onFormChanged();
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duplicated — edit and save as new')),
      );
    }
  }

  void _scrollToForm() {
    final ctx = _formScrollKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _save(DashBoardServices provider) async {
    final pop = int.tryParse(_form.popupSecs.text.trim()) ?? 12;
    final startsRaw = _form.startsAt != null
        ? DateTime(
            _form.startsAt!.year,
            _form.startsAt!.month,
            _form.startsAt!.day,
          ).toIso8601String()
        : '';
    final endsRaw = _form.endsAt != null
        ? DateTime(
            _form.endsAt!.year,
            _form.endsAt!.month,
            _form.endsAt!.day,
          ).toIso8601String()
        : '';

    final common = (
      title: _form.title.text.trim(),
      subtitle: _form.subtitle.text.trim(),
      ctaText: _form.cta.text.trim().isEmpty ? 'Shop now' : _form.cta.text.trim(),
      redirectType: _form.redirectType,
      redirectId: _form.redirectId.text.trim(),
      priority: _form.priorityTier.value,
      isActive: _form.isActive,
      showInHome: _form.showInHome,
      showInOffers: _form.showInOffers,
      showAsPopup: _form.showAsPopup,
      autoplay: _form.autoplay,
      loop: _form.loop,
      muted: _form.muted,
      popupAutoCloseSeconds: pop.clamp(3, 120),
      startsAtRaw: startsRaw,
      endsAtRaw: endsRaw,
    );

    if (_form.editingId != null) {
      await provider.updateBanner(
        context,
        _form.editingId!,
        existingImageUrl: _form.existingImageUrl,
        existingVideoUrl: _form.existingVideoUrl,
        existingThumbnailUrl: _form.existingThumbnailUrl,
        title: common.title,
        subtitle: common.subtitle,
        ctaText: common.ctaText,
        redirectType: common.redirectType,
        redirectId: common.redirectId,
        priority: common.priority,
        isActive: common.isActive,
        showInHome: common.showInHome,
        showInOffers: common.showInOffers,
        showAsPopup: common.showAsPopup,
        autoplay: common.autoplay,
        loop: common.loop,
        muted: common.muted,
        popupAutoCloseSeconds: common.popupAutoCloseSeconds,
        startsAtRaw: common.startsAtRaw,
        endsAtRaw: common.endsAtRaw,
      );
    } else {
      final hasMedia = provider.bannerType == 'image'
          ? provider.imageBytes != null
          : provider.videoBytes != null;
      if (!hasMedia) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload an image or video')),
        );
        return;
      }
      await provider.addBanner(
        context,
        title: common.title,
        subtitle: common.subtitle,
        ctaText: common.ctaText,
        redirectType: common.redirectType,
        redirectId: common.redirectId,
        priority: common.priority,
        isActive: common.isActive,
        showInHome: common.showInHome,
        showInOffers: common.showInOffers,
        showAsPopup: common.showAsPopup,
        autoplay: common.autoplay,
        loop: common.loop,
        muted: common.muted,
        popupAutoCloseSeconds: common.popupAutoCloseSeconds,
        startsAtRaw: common.startsAtRaw,
        endsAtRaw: common.endsAtRaw,
      );
    }
    if (mounted) _resetForm(provider);
  }

  Future<void> _confirmDelete(DashBoardServices provider) async {
    final id = _form.editingId;
    if (id == null) return;
    final ok = await showBannerDeleteDialog(context);
    if (!mounted) return;
    if (ok == true) {
      await provider.deleteBanner(id);
      if (!mounted) return;
      _resetForm(provider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner deleted')),
      );
    }
  }

  Future<void> _confirmDeleteList(BannerModel b, DashBoardServices provider) async {
    final ok = await showBannerDeleteDialog(context);
    if (!mounted) return;
    if (ok == true) {
      await provider.deleteBanner(b.id);
      if (!mounted) return;
      if (_form.editingId == b.id) _resetForm(provider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner deleted')),
      );
    }
  }

  void _openPreview(DashBoardServices provider) {
    showBannerPreviewDialog(
      context,
      preview: BannerPreviewPanel(
        data: _form.previewData(
          bannerType: provider.bannerType,
          imageBytes: provider.imageBytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashBoardServices>();
    final banners = provider.banners ?? [];
    final isEditing = _form.editingId != null;

    final formCol = KeyedSubtree(
      key: _formScrollKey,
      child: BannerFormPanel(
        form: _form,
        isSaving: provider.isLoading,
        isEditing: isEditing,
        onChanged: _onFormChanged,
        onSave: () => _save(provider),
        onPreview: () => _openPreview(provider),
        onDuplicate: () {
          if (_form.editingId == null) return;
          final b = banners.firstWhere(
            (x) => x.id == _form.editingId,
            orElse: () => banners.first,
          );
          _loadBanner(b, provider, duplicate: true);
        },
        onDelete: () => _confirmDelete(provider),
      ),
    );

    final previewCol = ValueListenableBuilder<int>(
      valueListenable: _previewTick,
      builder: (_, __, ___) => BannerPreviewPanel(
        data: _form.previewData(
          bannerType: provider.bannerType,
          imageBytes: provider.imageBytes,
        ),
      ),
    );

    return ColoredBox(
      color: BannerTheme.pageBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PageTitle(),
          const SizedBox(height: 20),
          _ExistingBannersToolbar(
            searchController: _searchCtrl,
            filter: _filter,
            onFilterChanged: (f) => setState(() => _filter = f),
            onCreateNew: () {
              _resetForm(provider);
              _scrollToForm();
            },
            onSearchChanged: () => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (banners.isNotEmpty) ...[
            BannerAnalyticsRow(banners: banners),
            const SizedBox(height: 20),
          ],
          BannerExistingSection(
            banners: banners,
            loading: provider.bannersLoading,
            searchQuery: _searchCtrl.text,
            filter: _filter,
            onEdit: (b) => _loadBanner(b, provider),
            onDuplicate: (b) => _loadBanner(b, provider, duplicate: true),
            onDelete: (b) => _confirmDeleteList(b, provider),
            onToggleActive: (b, active) =>
                provider.toggleBannerActive(b.id, active),
          ),
          const SizedBox(height: 36),
          const _SectionHeading(
            title: 'Add or edit banner',
            subtitle: 'Create a new banner or update the one loaded from the list',
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final wide = w >= 900;
              if (wide) {
                final formW = w * 0.58;
                final previewW = w - formW - 20;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: formW, child: formCol),
                    const SizedBox(width: 20),
                    SizedBox(width: previewW, child: previewCol),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  formCol,
                  const SizedBox(height: 20),
                  previewCol,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Banner Management', style: AppTextStyles.heading),
        const SizedBox(height: 4),
        Text(
          'Review existing banners, then add or edit creatives below',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _ExistingBannersToolbar extends StatelessWidget {
  const _ExistingBannersToolbar({
    required this.searchController,
    required this.filter,
    required this.onFilterChanged,
    required this.onCreateNew,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final BannerListFilter filter;
  final ValueChanged<BannerListFilter> onFilterChanged;
  final VoidCallback onCreateNew;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final stacked = adminIsMobileWidth(w);

    return Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: stacked ? 320 : 220,
              child: TextField(
                controller: searchController,
                onChanged: (_) => onSearchChanged(),
                decoration: BannerTheme.fieldDecoration(
                  label: 'Search',
                  hint: 'Title or ID…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                ),
              ),
            ),
            SizedBox(
              width: stacked ? 320 : 160,
              child: DropdownButtonFormField<BannerListFilter>(
                value: filter,
                decoration: BannerTheme.fieldDecoration(label: 'Filter'),
                items: const [
                  DropdownMenuItem(value: BannerListFilter.all, child: Text('All')),
                  DropdownMenuItem(value: BannerListFilter.active, child: Text('Active')),
                  DropdownMenuItem(
                    value: BannerListFilter.inactive,
                    child: Text('Inactive'),
                  ),
                  DropdownMenuItem(
                    value: BannerListFilter.scheduled,
                    child: Text('Scheduled'),
                  ),
                  DropdownMenuItem(value: BannerListFilter.image, child: Text('Image')),
                  DropdownMenuItem(value: BannerListFilter.video, child: Text('Video')),
                ],
                onChanged: (v) {
                  if (v != null) onFilterChanged(v);
                },
              ),
            ),
            ElevatedButton.icon(
              style: BannerTheme.primaryButtonStyle(),
              onPressed: onCreateNew,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Create new banner',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
  }
}
