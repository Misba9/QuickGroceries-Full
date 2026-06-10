import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_admin/model/maintenance_config_model.dart';
import 'package:quick_grocery_admin/view/maintenance/services/maintenance_management_service.dart';
import 'package:quick_grocery_admin/view/maintenance/widgets/ops_dashboard_widgets.dart';

class MaintenanceLiveStatusTab extends StatelessWidget {
  const MaintenanceLiveStatusTab({required this.svc});
  final MaintenanceManagementService svc;

  @override
  Widget build(BuildContext context) {
    final ops = svc.opsSnapshot;
    final c = svc.previewConfig;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        OpsSystemStateCard(svc: svc),
        const SizedBox(height: 16),
        OpsConnectionStrip(svc: svc),
        const SizedBox(height: 20),
        OpsAppStatusCard(
          title: 'User app',
          icon: Icons.phone_iphone_rounded,
          status: ops.userApp,
          body: _userBody(c),
          metric: c.enabled && c.affectedUserApp
              ? 'Customers see maintenance — orders blocked'
              : 'Normal shopping experience',
        ),
        const SizedBox(height: 12),
        OpsAppStatusCard(
          title: 'Vendor app',
          icon: Icons.storefront_rounded,
          status: ops.vendorApp,
          body: ops.vendorApp.detail,
        ),
        const SizedBox(height: 12),
        OpsAppStatusCard(
          title: 'Driver app',
          icon: Icons.delivery_dining_rounded,
          status: ops.driverApp,
          body: ops.driverApp.detail,
        ),
      ],
    );
  }

  String _userBody(MaintenanceConfigModel c) {
    if (!c.enabled || !c.affectedUserApp) {
      return 'Customers can browse and place orders normally.';
    }
    if (c.mode == 'soft') {
      return 'Customers can browse products but cannot place orders.';
    }
    if (c.mode == 'hard') {
      return 'Full block — customers only see the maintenance screen.';
    }
    return 'Read-only mode — cart and payments disabled.';
  }
}

class MaintenanceControlsTab extends StatelessWidget {
  const MaintenanceControlsTab({required this.svc});
  final MaintenanceManagementService svc;

  @override
  Widget build(BuildContext context) {
    final c = svc.config;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
          OpsGlassCard(
            title: 'Maintenance mode',
            icon: Icons.build_circle_outlined,
            child: Column(
              children: [
                _HighlightSwitch(
                  title: 'Enable maintenance',
                  subtitle: 'Turn on platform-wide maintenance controls',
                  value: c.enabled,
                  dirty: svc.isDirty,
                  onChanged: (v) => svc.updateConfig(c.copyWith(enabled: v)),
                ),
                _OpsDropdown(
                  label: 'Mode',
                  value: c.mode,
                  items: const ['soft', 'hard', 'read_only'],
                  labels: const {
                    'soft': 'Soft — browse, no orders',
                    'hard': 'Hard — full block',
                    'read_only': 'Read only',
                  },
                  onChanged: (v) => svc.updateConfig(c.copyWith(mode: v)),
                ),
                const Divider(),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Affected apps (admin always accessible)'),
                ),
                CheckboxListTile(
                  title: const Text('User app'),
                  value: c.affectedUserApp,
                  onChanged: (v) =>
                      svc.updateConfig(c.copyWith(affectedUserApp: v ?? false)),
                ),
                CheckboxListTile(
                  title: const Text('Vendor app'),
                  value: c.affectedVendorApp,
                  onChanged: (v) => svc.updateConfig(
                    c.copyWith(affectedVendorApp: v ?? false),
                  ),
                ),
                CheckboxListTile(
                  title: const Text('Driver app'),
                  value: c.affectedDriverApp,
                  onChanged: (v) => svc.updateConfig(
                    c.copyWith(affectedDriverApp: v ?? false),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Legacy store open'),
                  subtitle: const Text('Backward compatible isActive gate'),
                  value: c.legacyStoreActive,
                  onChanged: (v) =>
                      svc.updateConfig(c.copyWith(legacyStoreActive: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OpsGlassCard(
            title: 'Messages',
            icon: Icons.translate_rounded,
            child: Column(
              children: [
                OpsFormField(
                  label: 'Title (English)',
                  controller: svc.titleEn,
                  dirty: svc.isDirty,
                ),
                OpsFormField(
                  label: 'Subtitle (English)',
                  controller: svc.subtitleEn,
                  dirty: svc.isDirty,
                ),
                OpsFormField(
                  label: 'Message (English)',
                  controller: svc.messageEn,
                  maxLines: 3,
                  dirty: svc.isDirty,
                ),
                Row(
                  children: [
                    Expanded(
                      child: OpsFormField(
                        label: 'Reopen date',
                        controller: svc.reopenDate,
                        dirty: svc.isDirty,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OpsFormField(
                        label: 'Reopen time',
                        controller: svc.reopenTime,
                        dirty: svc.isDirty,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _StoreHoursCard(svc: svc),
        ],
    );
  }
}

class _StoreHoursCard extends StatelessWidget {
  const _StoreHoursCard({required this.svc});
  final MaintenanceManagementService svc;

  @override
  Widget build(BuildContext context) {
    final c = svc.config;
    final s = c.schedule;
    return OpsGlassCard(
      title: 'Store hours & scheduler',
      icon: Icons.schedule_rounded,
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Enable daily schedule'),
            value: s.enabled,
            onChanged: (v) => svc.updateConfig(
              c.copyWith(
                schedule: MaintenanceSchedule(
                  enabled: v,
                  dailyOpenTime: s.dailyOpenTime,
                  dailyCloseTime: s.dailyCloseTime,
                  timezone: s.timezone,
                  weeklyHolidays: s.weeklyHolidays,
                  festivalClosures: s.festivalClosures,
                  emergencyClose: s.emergencyClose,
                  autoReopen: s.autoReopen,
                ),
              ),
            ),
          ),
          OpsFormField(
            label: 'Daily open',
            controller: svc.openTime,
            dirty: svc.isDirty,
          ),
          OpsFormField(
            label: 'Daily close',
            controller: svc.closeTime,
            dirty: svc.isDirty,
          ),
          OpsFormField(
            label: 'Timezone',
            controller: svc.timezone,
            dirty: svc.isDirty,
          ),
          SwitchListTile(
            title: const Text('Emergency close now'),
            value: s.emergencyClose,
            onChanged: (v) => svc.updateConfig(
              c.copyWith(
                schedule: MaintenanceSchedule(
                  enabled: s.enabled,
                  dailyOpenTime: s.dailyOpenTime,
                  dailyCloseTime: s.dailyCloseTime,
                  timezone: s.timezone,
                  weeklyHolidays: s.weeklyHolidays,
                  festivalClosures: s.festivalClosures,
                  emergencyClose: v,
                  autoReopen: s.autoReopen,
                ),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Auto reopen'),
            value: s.autoReopen,
            onChanged: (v) => svc.updateConfig(
              c.copyWith(
                schedule: MaintenanceSchedule(
                  enabled: s.enabled,
                  dailyOpenTime: s.dailyOpenTime,
                  dailyCloseTime: s.dailyCloseTime,
                  timezone: s.timezone,
                  weeklyHolidays: s.weeklyHolidays,
                  festivalClosures: s.festivalClosures,
                  emergencyClose: s.emergencyClose,
                  autoReopen: v,
                ),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            children: List.generate(7, (i) {
              final day = i + 1;
              final selected = s.weeklyHolidays.contains(day);
              return FilterChip(
                label: Text(_weekdayLabel(day)),
                selected: selected,
                onSelected: (on) {
                  final next = List<int>.from(s.weeklyHolidays);
                  if (on) {
                    next.add(day);
                  } else {
                    next.remove(day);
                  }
                  next.sort();
                  svc.updateConfig(
                    c.copyWith(
                      schedule: MaintenanceSchedule(
                        enabled: s.enabled,
                        dailyOpenTime: s.dailyOpenTime,
                        dailyCloseTime: s.dailyCloseTime,
                        timezone: s.timezone,
                        weeklyHolidays: next,
                        festivalClosures: s.festivalClosures,
                        emergencyClose: s.emergencyClose,
                        autoReopen: s.autoReopen,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(int d) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];
}

class CustomerExperienceTab extends StatelessWidget {
  const CustomerExperienceTab({required this.svc});
  final MaintenanceManagementService svc;

  @override
  Widget build(BuildContext context) {
    final c = svc.config;
    final eng = c.engagement;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
          OpsGlassCard(
            title: 'Maintenance screen UI',
            icon: Icons.palette_outlined,
            child: Column(
              children: [
                OpsFormField(
                  label: 'Lottie URL',
                  controller: svc.lottieUrl,
                  dirty: svc.isDirty,
                ),
                OpsFormField(
                  label: 'Banner image URL',
                  controller: svc.bannerUrl,
                  dirty: svc.isDirty,
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'light', label: Text('Light')),
                    ButtonSegment(value: 'dark', label: Text('Dark')),
                  ],
                  selected: {c.theme},
                  onSelectionChanged: (s) =>
                      svc.updateConfig(c.copyWith(theme: s.first)),
                ),
                OpsFormField(
                  label: 'Support phone',
                  controller: svc.supportPhone,
                  dirty: svc.isDirty,
                ),
                OpsFormField(
                  label: 'Support email',
                  controller: svc.supportEmail,
                  dirty: svc.isDirty,
                ),
                SwitchListTile(
                  title: const Text('Show retry'),
                  value: c.showRetryButton,
                  onChanged: (v) =>
                      svc.updateConfig(c.copyWith(showRetryButton: v)),
                ),
                SwitchListTile(
                  title: const Text('Show contact support'),
                  value: c.showSupportButton,
                  onChanged: (v) =>
                      svc.updateConfig(c.copyWith(showSupportButton: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OpsGlassCard(
            title: 'Engagement during downtime',
            icon: Icons.local_offer_outlined,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Show coupons'),
                  value: eng.showCoupons,
                  onChanged: (v) => svc.updateConfig(
                    c.copyWith(
                      engagement: MaintenanceEngagement(
                        showCoupons: v,
                        showOffers: eng.showOffers,
                        showReferral: eng.showReferral,
                        showComingSoon: eng.showComingSoon,
                        couponCodes: eng.couponCodes,
                        offerHeadline: eng.offerHeadline,
                      ),
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Show offers'),
                  value: eng.showOffers,
                  onChanged: (v) => svc.updateConfig(
                    c.copyWith(
                      engagement: MaintenanceEngagement(
                        showCoupons: eng.showCoupons,
                        showOffers: v,
                        showReferral: eng.showReferral,
                        showComingSoon: eng.showComingSoon,
                        couponCodes: eng.couponCodes,
                        offerHeadline: eng.offerHeadline,
                      ),
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Referral banner'),
                  value: eng.showReferral,
                  onChanged: (v) => svc.updateConfig(
                    c.copyWith(
                      engagement: MaintenanceEngagement(
                        showCoupons: eng.showCoupons,
                        showOffers: eng.showOffers,
                        showReferral: v,
                        showComingSoon: eng.showComingSoon,
                        couponCodes: eng.couponCodes,
                        offerHeadline: eng.offerHeadline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
    );
  }
}

class AuditLogsTab extends StatelessWidget {
  const AuditLogsTab({required this.svc});
  final MaintenanceManagementService svc;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [OpsAuditPanel(svc: svc)],
    );
  }
}

class _HighlightSwitch extends StatelessWidget {
  const _HighlightSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.dirty = false,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool dirty;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFFFFF7ED)
            : (dirty ? const Color(0xFFFFF7ED) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value || dirty
              ? const Color(0xFFD97706)
              : Colors.grey.shade200,
        ),
      ),
      child: SwitchListTile(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _OpsDropdown<T> extends StatelessWidget {
  const _OpsDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.labels,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final Map<T, String> labels;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(labels[e] ?? e.toString()),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
