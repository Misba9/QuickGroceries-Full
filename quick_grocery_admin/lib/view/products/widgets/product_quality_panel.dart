import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/reviews/services/review_admin_service.dart';

class ProductQualityPanel extends StatefulWidget {
  const ProductQualityPanel({super.key, required this.productId});

  final String productId;

  @override
  State<ProductQualityPanel> createState() => _ProductQualityPanelState();
}

class _ProductQualityPanelState extends State<ProductQualityPanel> {
  final _service = ReviewAdminService();
  final _overrideController = TextEditingController();
  bool _featured = false;
  bool _premium = false;
  bool _fresh = false;
  bool _trending = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snap = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .get();
    final m = snap.data() ?? {};
    if (mounted) {
      setState(() {
        _overrideController.text =
            '${(m['quality_score_override'] as num?)?.toInt() ?? ''}';
        _featured = m['featured_quality_badge'] == true;
        _premium = m['premium_badge'] == true;
        _fresh = m['fresh_product_tag'] == true;
        _trending = m['isTrending'] == true;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final override = int.tryParse(_overrideController.text.trim());
    await _service.updateProductQuality(
      productId: widget.productId,
      qualityOverride: override,
      featuredQuality: _featured,
      premiumBadge: _premium,
      freshTag: _fresh,
      trendingTag: _trending,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quality settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LinearProgressIndicator();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Product quality control', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _overrideController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Manual quality score % (0 = auto)',
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              title: const Text('Featured quality badge'),
              value: _featured,
              activeColor: AppColor.primary,
              onChanged: (v) => setState(() => _featured = v),
            ),
            SwitchListTile(
              title: const Text('Premium badge'),
              value: _premium,
              activeColor: AppColor.primary,
              onChanged: (v) => setState(() => _premium = v),
            ),
            SwitchListTile(
              title: const Text('Fresh product tag'),
              value: _fresh,
              activeColor: AppColor.primary,
              onChanged: (v) => setState(() => _fresh = v),
            ),
            SwitchListTile(
              title: const Text('Trending tag'),
              value: _trending,
              activeColor: AppColor.primary,
              onChanged: (v) => setState(() => _trending = v),
            ),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(backgroundColor: AppColor.primary),
              child: const Text('Save quality settings'),
            ),
          ],
        ),
      ),
    );
  }
}
