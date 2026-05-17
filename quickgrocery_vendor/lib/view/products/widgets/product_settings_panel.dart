import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickgrocery_vendor/models/product_model.dart';
import 'package:quickgrocery_vendor/models/product_settings.dart';
import 'package:quickgrocery_vendor/services/product_service.dart';
import 'package:quickgrocery_vendor/style/app_color.dart';
import 'package:quickgrocery_vendor/utils/app_spacing.dart';

typedef SettingsChanged = void Function(ProductSettings settings);

class ProductSettingsPanel extends StatefulWidget {
  const ProductSettingsPanel({
    super.key,
    required this.productId,
    this.initialProduct,
    this.initialSettings,
    this.onLocalChanged,
    this.readOnly = false,
  });

  /// When null, settings are held locally until product is created.
  final String? productId;
  final ProductModel? initialProduct;
  final ProductSettings? initialSettings;
  final SettingsChanged? onLocalChanged;
  final bool readOnly;

  @override
  State<ProductSettingsPanel> createState() => _ProductSettingsPanelState();
}

class _ProductSettingsPanelState extends State<ProductSettingsPanel> {
  final _productService = ProductService();
  late ProductSettings _settings;
  bool _saving = false;
  String? _statusMessage;
  bool _statusError = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings ??
        widget.initialProduct?.settings ??
        const ProductSettings();
  }

  Future<void> _persist(ProductSettings next, {String? successMsg}) async {
    final productId = widget.productId;
    widget.onLocalChanged?.call(next);
    if (productId == null || productId.isEmpty) {
      setState(() => _settings = next);
      return;
    }

    final previous = _settings;
    setState(() {
      _settings = next;
      _saving = true;
      _statusMessage = null;
    });

    try {
      await _productService.patchSettings(
        productId: productId,
        settings: next,
        specialCat: widget.initialProduct?.specialCat,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _statusMessage = successMsg ?? 'Changes saved';
        _statusError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _settings = previous;
        _saving = false;
        _statusMessage = _messageForError(e);
        _statusError = true;
      });
    }
  }

  String _messageForError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('network') || s.contains('unavailable')) {
      return 'Network error — tap to retry';
    }
    return 'Failed to update product';
  }

  Future<void> _applyAutomation() async {
    final p = widget.initialProduct;
    if (p == null) return;
    final automated = _productService.settingsService.applyAutomation(
      current: _settings,
      stock: p.stockInt,
      totalSold: p.totalSold,
      createdAt: p.createdAt.toDate(),
    );
    await _persist(automated, successMsg: 'Automation applied');
  }

  void _toggle(
    ProductSettings Function(ProductSettings) transform, {
    String? label,
  }) {
    if (widget.readOnly || _settings.adminSettingsLocked) return;
    HapticFeedback.lightImpact();
    _persist(transform(_settings), successMsg: label ?? 'Changes saved');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.productId != null && widget.productId!.isNotEmpty) {
      return StreamBuilder<ProductModel?>(
        stream: _productService.watchProduct(widget.productId!),
        builder: (context, snap) {
          if (snap.hasData && snap.data != null && !_saving) {
            _settings = snap.data!.settings;
            widget.onLocalChanged?.call(_settings);
          }
          return _buildPanel(context);
        },
      );
    }
    return _buildPanel(context);
  }

  Widget _buildPanel(BuildContext context) {
    final locked = widget.readOnly || _settings.adminSettingsLocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(saving: _saving, locked: locked),
        if (_settings.adminSettingsLocked)
          _InfoBanner(
            icon: Icons.lock_outline,
            text: 'Admin locked these settings',
            color: Colors.orange.shade50,
          ),
        if (!_settings.isActive)
          _InfoBanner(
            icon: Icons.visibility_off_outlined,
            text: 'Inactive — hidden from user app, search & checkout',
            color: Colors.red.shade50,
          ),
        _SettingsCard(
          title: 'Visibility',
          icon: Icons.visibility_outlined,
          children: [
            _SettingToggle(
              icon: Icons.check_circle_outline,
              title: 'Active',
              subtitle: 'Show in store, search & categories',
              value: _settings.isActive,
              locked: locked,
              onChanged: (v) => _toggle((s) => s.copyWith(isActive: v),
                  label: v ? 'Product activated' : 'Product hidden'),
            ),
          ],
        ),
        AppSpacing.h10,
        _SettingsCard(
          title: 'Promotions',
          icon: Icons.local_offer_outlined,
          children: [
            _SettingToggle(
              icon: Icons.bolt,
              title: 'Flash Sale',
              subtitle: 'Limited-time offer with countdown',
              value: _settings.isFlashSale,
              locked: locked,
              onChanged: (v) => _toggle((s) => s.copyWith(isFlashSale: v),
                  label: 'Flash sale updated'),
            ),
            if (_settings.isFlashSale) ...[
              AppSpacing.h10,
              _FlashSaleDetails(
                settings: _settings,
                locked: locked,
                onChanged: _persist,
              ),
            ],
            _SettingToggle(
              icon: Icons.star_outline,
              title: "Today's Best",
              subtitle: 'Featured in today\'s deals',
              value: _settings.isTodaysBest,
              locked: locked,
              onChanged: (v) => _toggle((s) => s.copyWith(isTodaysBest: v)),
            ),
            _SettingToggle(
              icon: Icons.trending_up,
              title: 'Most Selling',
              subtitle: 'Best seller badge',
              value: _settings.isMostSelling,
              locked: locked,
              onChanged: (v) => _toggle((s) => s.copyWith(isMostSelling: v)),
            ),
          ],
        ),
        AppSpacing.h10,
        _SettingsCard(
          title: 'Badges & highlights',
          icon: Icons.verified_outlined,
          children: [
            _SettingToggle(
              icon: Icons.whatshot_outlined,
              title: 'Trending Product',
              value: _settings.isTrending,
              locked: locked,
              onChanged: (v) => _toggle((s) => s.copyWith(isTrending: v)),
            ),
            _SettingToggle(
              icon: Icons.thumb_up_alt_outlined,
              title: 'Recommended Product',
              value: _settings.isRecommended,
              locked: locked,
              onChanged: (v) => _toggle((s) => s.copyWith(isRecommended: v)),
            ),
            _SettingToggle(
              icon: Icons.featured_play_list_outlined,
              title: 'Featured Product',
              subtitle: _settings.adminFeaturedApproved
                  ? 'Shows on featured rail'
                  : 'Pending admin approval',
              value: _settings.isFeatured,
              locked: locked || !_settings.adminFeaturedApproved,
              onChanged: (v) => _toggle((s) => s.copyWith(isFeatured: v)),
            ),
            _SettingToggle(
              icon: Icons.diamond_outlined,
              title: 'Premium Product',
              value: _settings.isPremium,
              locked: locked,
              onChanged: (v) => _toggle((s) => s.copyWith(isPremium: v)),
            ),
            _SettingToggle(
              icon: Icons.fiber_new_outlined,
              title: 'New Arrival',
              value: _settings.isNewArrival,
              locked: locked,
              onChanged: (v) => _toggle((s) => s.copyWith(isNewArrival: v)),
            ),
            _SettingToggle(
              icon: Icons.inventory_2_outlined,
              title: 'Limited Stock',
              value: _settings.isLimitedStock,
              locked: locked,
              onChanged: (v) => _toggle((s) => s.copyWith(isLimitedStock: v)),
            ),
            _SettingToggle(
              icon: Icons.eco_outlined,
              title: 'Organic Product',
              value: _settings.isOrganic,
              locked: locked,
              onChanged: (v) => _toggle((s) => s.copyWith(isOrganic: v)),
            ),
            _SettingToggle(
              icon: Icons.speed,
              title: 'Fast Selling',
              value: _settings.isFastSelling,
              locked: locked,
              onChanged: (v) => _toggle((s) => s.copyWith(isFastSelling: v)),
            ),
            _SettingToggle(
              icon: Icons.wb_sunny_outlined,
              title: 'Seasonal Product',
              value: _settings.isSeasonal,
              locked: locked,
              onChanged: (v) => _toggle((s) => s.copyWith(isSeasonal: v)),
            ),
          ],
        ),
        AppSpacing.h10,
        _SettingsCard(
          title: 'Smart automation',
          icon: Icons.auto_awesome_outlined,
          children: [
            _SettingToggle(
              icon: Icons.auto_graph,
              title: 'Auto Most Selling',
              subtitle: 'Based on sales volume',
              value: _settings.autoMostSelling,
              locked: locked,
              onChanged: (v) =>
                  _toggle((s) => s.copyWith(autoMostSelling: v)),
            ),
            _SettingToggle(
              icon: Icons.insights_outlined,
              title: 'Auto Trending',
              subtitle: 'Based on orders & views',
              value: _settings.autoTrending,
              locked: locked,
              onChanged: (v) => _toggle((s) => s.copyWith(autoTrending: v)),
            ),
            _SettingToggle(
              icon: Icons.warning_amber_outlined,
              title: 'Auto Limited Stock',
              subtitle: 'When stock ≤ 5',
              value: _settings.autoLimitedStock,
              locked: locked,
              onChanged: (v) =>
                  _toggle((s) => s.copyWith(autoLimitedStock: v)),
            ),
            _SettingToggle(
              icon: Icons.schedule,
              title: 'Auto New Arrival',
              subtitle: 'Products under 14 days',
              value: _settings.autoNewArrival,
              locked: locked,
              onChanged: (v) => _toggle((s) => s.copyWith(autoNewArrival: v)),
            ),
            if (widget.productId != null && !locked) ...[
              AppSpacing.h10,
              OutlinedButton.icon(
                onPressed: _saving ? null : _applyAutomation,
                icon: const Icon(Icons.play_arrow_outlined),
                label: const Text('Apply automation now'),
              ),
            ],
          ],
        ),
        if (_statusMessage != null) ...[
          AppSpacing.h10,
          Material(
            color: _statusError ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
            child: ListTile(
              dense: true,
              leading: Icon(
                _statusError ? Icons.error_outline : Icons.check_circle_outline,
                color: _statusError ? Colors.red : Colors.green.shade700,
                size: 20,
              ),
              title: Text(
                _statusMessage!,
                style: const TextStyle(fontSize: 12),
              ),
              onTap: _statusError
                  ? () => _persist(_settings, successMsg: 'Product updated successfully')
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.saving, required this.locked});
  final bool saving;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColor.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.tune, color: Colors.black87),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                locked
                    ? 'View only'
                    : saving
                        ? 'Saving…'
                        : 'Changes sync instantly',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (saving)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.black87),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  const _SettingToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final bool locked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: SwitchListTile(
        key: ValueKey('$title-$value'),
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, size: 22, color: Colors.black54),
        title: Text(title, style: TextStyle(fontSize: 14)),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              )
            : null,
        value: value,
        onChanged: locked ? null : onChanged,
        activeThumbColor: AppColor.primary,
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _FlashSaleDetails extends StatelessWidget {
  const _FlashSaleDetails({
    required this.settings,
    required this.locked,
    required this.onChanged,
  });

  final ProductSettings settings;
  final bool locked;
  final Future<void> Function(ProductSettings, {String? successMsg}) onChanged;

  @override
  Widget build(BuildContext context) {
    final end = settings.flashSaleEnd;
    final remaining = end != null ? end.difference(DateTime.now()) : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 18, color: Colors.amber.shade900),
              const SizedBox(width: 6),
              Text(
                'Flash Sale',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.orange.shade400],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SALE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (remaining != null && !remaining.isNegative) ...[
            const SizedBox(height: 6),
            Text(
              'Ends in ${_formatDuration(remaining)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
            ),
          ],
          const SizedBox(height: 8),
          TextFormField(
            initialValue: settings.flashSaleStockLimit > 0
                ? '${settings.flashSaleStockLimit}'
                : '',
            enabled: !locked,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Sale stock limit (optional)',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onFieldSubmitted: (v) {
              final n = int.tryParse(v) ?? 0;
              onChanged(
                settings.copyWith(flashSaleStockLimit: n),
                successMsg: 'Flash sale updated',
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: locked
                      ? null
                      : () {
                          final start = DateTime.now();
                          onChanged(
                            settings.copyWith(
                              flashSaleStart: start,
                              flashSaleEnd: start.add(const Duration(hours: 24)),
                            ),
                            successMsg: '24h flash sale started',
                          );
                        },
                  child: const Text('24h sale'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: locked
                      ? null
                      : () {
                          final start = DateTime.now();
                          onChanged(
                            settings.copyWith(
                              flashSaleStart: start,
                              flashSaleEnd: start.add(const Duration(days: 3)),
                            ),
                            successMsg: '3-day flash sale started',
                          );
                        },
                  child: const Text('3-day sale'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }
}
