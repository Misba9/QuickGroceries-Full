import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/banners/banner_theme.dart';
import 'package:quick_grocery_admin/view/banners/models/banner_form_state.dart';
import 'package:quick_grocery_admin/view/banners/widgets/banner_admin_card.dart';
import 'package:quick_grocery_admin/view/banners/widgets/banner_upload_zone.dart';
import 'package:quick_grocery_admin/view/home/services/dash_board_services.dart';

/// Left column: grouped form cards for create / edit banner.
class BannerFormPanel extends StatelessWidget {
  const BannerFormPanel({
    super.key,
    required this.form,
    required this.onChanged,
    required this.onSave,
    required this.onPreview,
    required this.onDuplicate,
    required this.onDelete,
    required this.isSaving,
    required this.isEditing,
  });

  final BannerFormControllers form;
  final VoidCallback onChanged;
  final VoidCallback onSave;
  final VoidCallback onPreview;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final bool isSaving;
  final bool isEditing;

  static const _redirectOptions = <String, String>{
    'product': 'Product',
    'category': 'Category',
    'offers_page': 'Offers page',
    'vendor': 'Vendor page',
    'url': 'External URL',
    'none': 'None',
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashBoardServices>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BannerAdminCard(
          title: 'Banner type',
          subtitle: 'Choose image or video creative',
          child: Row(
            children: [
              Expanded(
                child: _TypeTile(
                  selected: provider.bannerType == 'image',
                  icon: Icons.image_outlined,
                  label: 'Image',
                  onTap: () {
                    provider.setBannerType('image');
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeTile(
                  selected: provider.bannerType == 'video',
                  icon: Icons.play_circle_outline,
                  label: 'Video',
                  onTap: () {
                    provider.setBannerType('video');
                    onChanged();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BannerAdminCard(
          title: 'Banner content',
          subtitle: 'Title, copy, and media asset',
          child: Column(
            children: [
              TextField(
                controller: form.title,
                onChanged: (_) => onChanged(),
                decoration: BannerTheme.fieldDecoration(label: 'Banner title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: form.subtitle,
                onChanged: (_) => onChanged(),
                decoration: BannerTheme.fieldDecoration(label: 'Subtitle'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: form.cta,
                onChanged: (_) => onChanged(),
                decoration: BannerTheme.fieldDecoration(
                  label: 'CTA button text',
                  hint: 'Shop now',
                ),
              ),
              const SizedBox(height: 16),
              BannerUploadZone(
                bannerType: provider.bannerType,
                imageBytes: provider.imageBytes,
                videoSelected:
                    provider.videoBytes != null || provider.videoPath != null,
                thumbnailReady: provider.thumbnailBytes != null,
                onPick: () async {
                  if (provider.bannerType == 'image') {
                    await provider.pickImage();
                  } else {
                    await provider.pickVideo();
                  }
                  onChanged();
                },
                onPickThumbnail: provider.bannerType == 'video'
                    ? () async {
                        await provider.pickThumbnail();
                        onChanged();
                      }
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BannerAdminCard(
          title: 'Redirect settings',
          subtitle: 'Where users go when they tap the banner',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _redirectOptions.containsKey(form.redirectType)
                    ? form.redirectType
                    : 'offers_page',
                decoration: BannerTheme.fieldDecoration(label: 'Redirect type'),
                items: _redirectOptions.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  form.redirectType = v ?? 'offers_page';
                  onChanged();
                },
              ),
              const SizedBox(height: 12),
              _RedirectInput(form: form, onChanged: onChanged),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BannerAdminCard(
          title: 'Display settings',
          subtitle: 'Control visibility across the app',
          child: Column(
            children: [
              _ToggleRow(
                title: 'Enable banner',
                subtitle: 'When off, banner is hidden everywhere',
                value: form.isActive,
                onChanged: (v) {
                  form.isActive = v;
                  onChanged();
                },
              ),
              _ToggleRow(
                title: 'Show on home',
                subtitle: 'Explore promos carousel on home',
                value: form.showInHome,
                onChanged: (v) {
                  form.showInHome = v;
                  onChanged();
                },
              ),
              _ToggleRow(
                title: 'Show on offers page',
                subtitle: 'Offers & deals promotional strip',
                value: form.showInOffers,
                onChanged: (v) {
                  form.showInOffers = v;
                  onChanged();
                },
              ),
              _ToggleRow(
                title: 'Show as startup popup',
                subtitle: 'Full-screen promo when app opens',
                value: form.showAsPopup,
                onChanged: (v) {
                  form.showAsPopup = v;
                  onChanged();
                },
              ),
              if (form.showAsPopup) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: form.popupSecs,
                  keyboardType: TextInputType.number,
                  decoration: BannerTheme.fieldDecoration(
                    label: 'Popup auto-close (seconds)',
                    helper: 'Between 3 and 120 seconds',
                  ),
                ),
              ],
              if (provider.bannerType == 'video') ...[
                const Divider(height: 24),
                _ToggleRow(
                  title: 'Autoplay video',
                  subtitle: 'Start playback automatically',
                  value: form.autoplay,
                  onChanged: (v) {
                    form.autoplay = v;
                    onChanged();
                  },
                ),
                _ToggleRow(
                  title: 'Loop video',
                  subtitle: 'Repeat when finished',
                  value: form.loop,
                  onChanged: (v) {
                    form.loop = v;
                    onChanged();
                  },
                ),
                _ToggleRow(
                  title: 'Mute video',
                  subtitle: 'Play without sound by default',
                  value: form.muted,
                  onChanged: (v) {
                    form.muted = v;
                    onChanged();
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        BannerAdminCard(
          title: 'Schedule & priority',
          subtitle: 'Optional dates and sort order',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  final stacked = c.maxWidth < 520;
                  final start = _DateField(
                    label: 'Start date',
                    value: form.startsAt,
                    onPick: (d) {
                      form.startsAt = d;
                      onChanged();
                    },
                    onClear: () {
                      form.startsAt = null;
                      onChanged();
                    },
                  );
                  final end = _DateField(
                    label: 'End date',
                    value: form.endsAt,
                    onPick: (d) {
                      form.endsAt = d;
                      onChanged();
                    },
                    onClear: () {
                      form.endsAt = null;
                      onChanged();
                    },
                  );
                  if (stacked) {
                    return Column(
                      children: [
                        start,
                        const SizedBox(height: 12),
                        end,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: start),
                      const SizedBox(width: 12),
                      Expanded(child: end),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Priority — ${form.priorityTier.label}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Higher priority banners appear first',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColor.primary,
                  thumbColor: AppColor.primary,
                  inactiveTrackColor: const Color(0xFFE8EAED),
                ),
                child: Slider(
                  value: form.priorityTier.index.toDouble(),
                  min: 0,
                  max: 2,
                  divisions: 2,
                  label: form.priorityTier.label,
                  onChanged: (v) {
                    form.priorityTier =
                        BannerPriorityTier.values[v.round().clamp(0, 2)];
                    onChanged();
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: BannerPriorityTier.values
                    .map((t) => Text(t.label, style: const TextStyle(fontSize: 12)))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BannerAdminCard(
          title: 'Actions',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: BannerTheme.primaryButtonStyle(),
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isEditing ? Icons.save_outlined : Icons.add),
                label: Text(isEditing ? 'Save banner' : 'Save banner'),
              ),
              OutlinedButton.icon(
                style: BannerTheme.outlineButtonStyle(),
                onPressed: onPreview,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Preview'),
              ),
              if (isEditing) ...[
                OutlinedButton.icon(
                  style: BannerTheme.outlineButtonStyle(),
                  onPressed: onDuplicate,
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: const Text('Duplicate'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColor.primary.withValues(alpha: 0.12) : const Color(0xFFFAFAFB),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColor.primary : const Color(0xFFE8EAED),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? const Color(0xFF1A1A1A) : Colors.grey),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      value: value,
      activeTrackColor: AppColor.primary.withValues(alpha: 0.4),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColor.primary;
        return null;
      }),
      onChanged: onChanged,
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final text = value != null
        ? '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}'
        : '';
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: BannerTheme.fieldDecoration(
          label: label,
          hint: 'Optional',
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text.isEmpty ? 'Select date' : text,
                style: TextStyle(
                  color: text.isEmpty ? Colors.grey.shade500 : null,
                ),
              ),
            ),
            if (value != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const Icon(Icons.calendar_today_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}

class _RedirectInput extends StatelessWidget {
  const _RedirectInput({required this.form, required this.onChanged});

  final BannerFormControllers form;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final type = form.redirectType;
    if (type == 'none') {
      return Text(
        'No redirect — banner is display-only',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      );
    }

    String label;
    String hint;
    switch (type) {
      case 'product':
        label = 'Product ID';
        hint = 'Paste Firestore product document ID';
        break;
      case 'category':
        label = 'Category ID';
        hint = 'Category document ID or slug';
        break;
      case 'vendor':
        label = 'Vendor ID';
        hint = 'Vendor document ID';
        break;
      case 'url':
        label = 'External URL';
        hint = 'https://example.com/promo';
        break;
      case 'offers_page':
        return Text(
          'Opens the Offers & deals tab in the user app',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        );
      default:
        label = 'Redirect target';
        hint = 'ID or URL';
    }

    return TextField(
      controller: form.redirectId,
      onChanged: (_) => onChanged(),
      decoration: BannerTheme.fieldDecoration(label: label, hint: hint),
    );
  }
}
