import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/delivery_tips/models/delivery_tips_settings_model.dart';

class DeliveryTipsSettingsPanel extends StatefulWidget {
  const DeliveryTipsSettingsPanel({
    super.key,
    required this.initial,
    required this.onSave,
  });

  final DeliveryTipsSettingsModel initial;
  final Future<void> Function(DeliveryTipsSettingsModel) onSave;

  @override
  State<DeliveryTipsSettingsPanel> createState() =>
      _DeliveryTipsSettingsPanelState();
}

class _DeliveryTipsSettingsPanelState extends State<DeliveryTipsSettingsPanel> {
  late bool _enabled = widget.initial.enabled;
  late final TextEditingController _maxTip =
      TextEditingController(text: '${widget.initial.maxTipAmount}');
  late List<int> _suggested = List.from(widget.initial.suggestedTips);
  bool _saving = false;

  @override
  void dispose() {
    _maxTip.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        DeliveryTipsSettingsModel(
          enabled: _enabled,
          suggestedTips: _suggested,
          maxTipAmount: int.tryParse(_maxTip.text.trim()) ?? 500,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tip settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tip Feature',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable delivery partner tips'),
              value: _enabled,
              activeColor: AppColor.primary,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxTip,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Maximum tip amount (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Suggested tip amounts',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final t in _suggested)
                  Chip(
                    label: Text('₹$t'),
                    onDeleted: _suggested.length > 1
                        ? () => setState(() => _suggested.remove(t))
                        : null,
                  ),
                ActionChip(
                  label: const Text('+ Add'),
                  onPressed: () async {
                    final ctrl = TextEditingController();
                    final v = await showDialog<int>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Add suggested tip'),
                        content: TextField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(prefixText: '₹ '),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              final n = int.tryParse(ctrl.text.trim());
                              Navigator.pop(ctx, n);
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );
                    if (v != null && v > 0 && !_suggested.contains(v)) {
                      setState(() => _suggested.add(v));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
