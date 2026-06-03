import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/view/refer_earn/models/refer_earn_settings_model.dart';
import 'package:quick_grocery_admin/view/refer_earn/services/refer_earn_admin_service.dart';

class ReferEarnSettingsPanel extends StatefulWidget {
  const ReferEarnSettingsPanel({super.key, required this.service});

  final ReferEarnAdminService service;

  @override
  State<ReferEarnSettingsPanel> createState() => _ReferEarnSettingsPanelState();
}

class _ReferEarnSettingsPanelState extends State<ReferEarnSettingsPanel> {
  final _playStore = TextEditingController();
  final _template = TextEditingController();
  final _referrerReward = TextEditingController();
  final _friendReward = TextEditingController();
  final _minOrder = TextEditingController();
  final _expiryDays = TextEditingController();
  final _maxReferrals = TextEditingController();
  final _prefix = TextEditingController();
  bool _enabled = false;
  bool _autoGrant = true;
  bool _saving = false;
  bool _hydrated = false;
  String _activeCampaignId = '';

  @override
  void dispose() {
    _playStore.dispose();
    _template.dispose();
    _referrerReward.dispose();
    _friendReward.dispose();
    _minOrder.dispose();
    _expiryDays.dispose();
    _maxReferrals.dispose();
    _prefix.dispose();
    super.dispose();
  }

  void _hydrate(ReferEarnSettingsModel s) {
    _enabled = s.enabled;
    _autoGrant = s.autoGrantRewards;
    _activeCampaignId = s.activeCampaignId;
    _playStore.text = s.playStoreUrl;
    _template.text = s.shareMessageTemplate;
    _referrerReward.text = '${s.referrerRewardAmount}';
    _friendReward.text = '${s.newUserRewardAmount}';
    _minOrder.text = '${s.minimumOrderValue}';
    _expiryDays.text = '${s.couponExpiryDays}';
    _maxReferrals.text = '${s.maxReferralsPerUser}';
    _prefix.text = s.couponCodePrefix;
  }

  int _int(TextEditingController c, {int fallback = 0}) =>
      int.tryParse(c.text.trim()) ?? fallback;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final model = ReferEarnSettingsModel(
        enabled: _enabled,
        activeCampaignId: _activeCampaignId,
        playStoreUrl: _playStore.text.trim(),
        shareMessageTemplate: _template.text.trim(),
        referrerRewardAmount: _int(_referrerReward, fallback: 50),
        newUserRewardAmount: _int(_friendReward, fallback: 50),
        minimumOrderValue: _int(_minOrder, fallback: 199),
        couponExpiryDays: _int(_expiryDays, fallback: 30),
        maxReferralsPerUser: _int(_maxReferrals, fallback: 10),
        autoGrantRewards: _autoGrant,
        couponCodePrefix: _prefix.text.trim(),
      );
      await widget.service.saveSettings(model);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refer & Earn settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ReferEarnSettingsModel>(
      stream: widget.service.watchSettings(),
      builder: (context, snap) {
        final settings = snap.data ?? ReferEarnSettingsModel.defaults();
        if (snap.hasData && !_hydrated && !snap.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _hydrate(settings);
              _hydrated = true;
            }
          });
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Enable Referral Program'),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _playStore,
              decoration: const InputDecoration(
                labelText: 'Play Store URL',
                hintText:
                    'https://play.google.com/store/apps/details?id=com.quickgrocery.io',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _template,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Share message template',
                helperText:
                    'Placeholders: {code}, {friend_reward}, {referrer_reward}, {min_order}, {play_store_url}',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _referrerReward,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Referrer reward (₹)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _friendReward,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Friend reward (₹)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minOrder,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minimum order (₹)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _expiryDays,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Coupon expiry (days)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _maxReferrals,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max referrals per user',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _prefix,
                    decoration: const InputDecoration(
                      labelText: 'Coupon prefix',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto-grant rewards on eligible delivery'),
              value: _autoGrant,
              onChanged: (v) => setState(() => _autoGrant = v),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save settings'),
            ),
          ],
        );
      },
    );
  }
}
