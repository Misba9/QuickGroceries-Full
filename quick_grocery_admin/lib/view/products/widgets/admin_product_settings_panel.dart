import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';

class AdminProductSettingsPanel extends StatefulWidget {
  const AdminProductSettingsPanel({super.key, required this.productId});

  final String productId;

  @override
  State<AdminProductSettingsPanel> createState() =>
      _AdminProductSettingsPanelState();
}

class _AdminProductSettingsPanelState extends State<AdminProductSettingsPanel> {
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() {
        _data = snap.data() ?? {};
        _loading = false;
      });
    });
  }

  Future<void> _patch(Map<String, dynamic> fields) async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .set(
        {
          ...fields,
          'lastEdited': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product settings updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _flag(String key) => _data[key] == true;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LinearProgressIndicator();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront_outlined),
                AppSpacing.w10,
                const Expanded(
                  child: Text(
                    'Vendor product settings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (_saving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            AppSpacing.h10,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ReadChip('Active', _flag('is_active')),
                _ReadChip('Flash Sale', _flag('is_flash_sale')),
                _ReadChip("Today's Best", _flag('is_todays_best')),
                _ReadChip('Most Selling', _flag('is_most_selling')),
                _ReadChip('Trending', _flag('isTrending')),
                _ReadChip('Featured', _flag('isFeatured')),
                _ReadChip('Recommended', _flag('is_recommended')),
                _ReadChip('New Arrival', _flag('is_new_arrival')),
              ],
            ),
            const Divider(height: 24),
            const Text('Admin overrides', style: TextStyle(fontWeight: FontWeight.w600)),
            AppSpacing.h10,
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Approve featured placement'),
              subtitle: const Text('Required for featured rail on user app'),
              value: _data['admin_featured_approved'] != false,
              activeThumbColor: AppColor.primary,
              onChanged: (v) => _patch({'admin_featured_approved': v}),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lock vendor settings'),
              subtitle: const Text('Vendor cannot change toggles'),
              value: _data['admin_settings_locked'] == true,
              activeThumbColor: AppColor.primary,
              onChanged: (v) => _patch({'admin_settings_locked': v}),
            ),
            AppSpacing.h10,
            FilledButton.icon(
              onPressed: () => _patch({
                'is_active': true,
                'isAvailable': true,
                'isFeatured': true,
                'is_featured': true,
                'admin_featured_approved': true,
              }),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Force feature product'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadChip extends StatelessWidget {
  const _ReadChip(this.label, this.on);
  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        on ? Icons.check_circle : Icons.cancel_outlined,
        size: 16,
        color: on ? Colors.green : Colors.grey,
      ),
      label: Text(label),
      backgroundColor: on ? Colors.green.shade50 : Colors.grey.shade100,
    );
  }
}
