import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/models/rating_model.dart';
import 'package:quickgrocery/view/product_view/data/review_api_client.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({
    super.key,
    required this.product,
    this.orderId = '',
    this.existingReview,
  });

  final ProductModel product;
  final String orderId;
  final RatingModel? existingReview;

  bool get isEdit => existingReview != null;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _api = ReviewApiClient();
  final _reviewController = TextEditingController();
  final _picker = ImagePicker();

  double _productQuality = 5;
  double _freshness = 5;
  double _packaging = 5;
  double _delivery = 5;
  double _value = 5;
  final List<File> _images = [];
  final List<String> _existingImageUrls = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReview;
    if (existing == null) return;
    _reviewController.text = existing.review;
    _productQuality = existing.categoryRatings.productQuality;
    _freshness = existing.categoryRatings.freshness;
    _packaging = existing.categoryRatings.packaging;
    _delivery = existing.categoryRatings.deliveryExperience;
    _value = existing.categoryRatings.valueForMoney;
    _existingImageUrls.addAll(existing.reviewImages);
  }

  bool get _withinEditWindow {
    final existing = widget.existingReview;
    if (existing == null) return true;
    final created = existing.createdAt.toDate();
    return DateTime.now().difference(created).inHours < 24;
  }

  CategoryRatings get _categories => CategoryRatings(
        productQuality: _productQuality,
        freshness: _freshness,
        packaging: _packaging,
        deliveryExperience: _delivery,
        valueForMoney: _value,
      );

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 75);
    if (files.isEmpty) return;
    setState(() {
      _images.addAll(files.map((x) => File(x.path)).take(6 - _images.length));
    });
  }

  Future<List<String>> _uploadImages() async {
    final urls = <String>[];
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    for (var i = 0; i < _images.length; i++) {
      final ref = FirebaseStorage.instance.ref(
        'review_images/$uid/${widget.product.id}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
      );
      await ref.putFile(_images[i]);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> _submit() async {
    if (!_withinEditWindow) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reviews can only be edited within 24 hours')),
      );
      return;
    }
    if (_reviewController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write at least 10 characters')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final newUrls = await _uploadImages();
      final allUrls = [..._existingImageUrls, ...newUrls];
      final user = FirebaseAuth.instance.currentUser;
      if (widget.isEdit) {
        await _api.update(
          reviewId: widget.existingReview!.id,
          reviewText: _reviewController.text.trim(),
          reviewImages: allUrls,
          reviewVideo: widget.existingReview!.reviewVideo,
          categoryRatings: _categories,
        );
      } else {
        await _api.submit(
          productId: widget.product.id,
          productName: widget.product.name,
          vendorId: widget.product.vendorId,
          orderId: widget.orderId,
          userName: user?.displayName ?? 'Customer',
          reviewText: _reviewController.text.trim(),
          reviewImages: allUrls,
          reviewVideo: '',
          categoryRatings: _categories,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'Review updated'
                : 'Review submitted! It will appear after approval.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit review' : 'Write a review'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.product.name,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const _VerifiedBanner(),
          const SizedBox(height: 16),
          _CategoryRow('Product Quality', _productQuality, (v) => setState(() => _productQuality = v)),
          _CategoryRow('Freshness', _freshness, (v) => setState(() => _freshness = v)),
          _CategoryRow('Packaging', _packaging, (v) => setState(() => _packaging = v)),
          _CategoryRow('Delivery Experience', _delivery, (v) => setState(() => _delivery = v)),
          _CategoryRow('Value for Money', _value, (v) => setState(() => _value = v)),
          const SizedBox(height: 16),
          TextField(
            controller: _reviewController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Your review',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _images.length >= 6 ? null : _pickImages,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text('Add photos (${_images.length}/6)'),
          ),
          if (_existingImageUrls.isNotEmpty || _images.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _existingImageUrls.length + _images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i < _existingImageUrls.length) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _existingImageUrls[i],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    );
                  }
                  final file = _images[i - _existingImageUrls.length];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.isEdit ? 'Save changes' : 'Submit review'),
          ),
        ],
      ),
    );
  }
}

class _VerifiedBanner extends StatelessWidget {
  const _VerifiedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 6),
          Text(
            'Verified Purchase',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow(this.label, this.value, this.onChanged);

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 13))),
          RatingBar.builder(
            initialRating: value,
            minRating: 1,
            itemCount: 5,
            itemSize: 22,
            glow: false,
            itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: AppColor.primary),
            onRatingUpdate: onChanged,
          ),
        ],
      ),
    );
  }
}
