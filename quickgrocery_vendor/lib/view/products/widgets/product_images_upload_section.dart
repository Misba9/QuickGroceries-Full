import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quickgrocery_vendor/constants/product_image_limits.dart';
import 'package:quickgrocery_vendor/models/product_image_slot.dart';
import 'package:quickgrocery_vendor/services/product_image_upload_service.dart';
import 'package:quickgrocery_vendor/style/app_color.dart';
import 'package:quickgrocery_vendor/utils/app_spacing.dart';

typedef ProductImagesChanged = void Function(List<ProductImageSlot> slots);

class ProductImagesUploadSection extends StatefulWidget {
  const ProductImagesUploadSection({
    super.key,
    required this.initialUrls,
    required this.onChanged,
    this.uploadProgress,
    this.isUploading = false,
  });

  final List<String> initialUrls;
  final ProductImagesChanged onChanged;
  final double? uploadProgress;
  final bool isUploading;

  @override
  State<ProductImagesUploadSection> createState() =>
      _ProductImagesUploadSectionState();
}

class _ProductImagesUploadSectionState extends State<ProductImagesUploadSection> {
  final _pickerService = ProductImageUploadService();
  late List<ProductImageSlot> _slots;
  int _previewIndex = 0;

  @override
  void initState() {
    super.initState();
    _slots = ProductImageSlot.fromUrls(widget.initialUrls);
  }

  @override
  void didUpdateWidget(covariant ProductImagesUploadSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialUrls != widget.initialUrls &&
        widget.initialUrls.isNotEmpty &&
        _slots.every((s) => s.isRemote)) {
      _slots = ProductImageSlot.fromUrls(widget.initialUrls);
    }
  }

  void _notify() => widget.onChanged(List.unmodifiable(_slots));

  bool get _canAddMore => _slots.length < ProductImageLimits.maxImages;

  Future<void> _addFromGallery() async {
    try {
      final remaining = ProductImageLimits.maxImages - _slots.length;
      final files = await _pickerService.pickFromGallery(
        remainingSlots: remaining,
      );
      if (files.isEmpty) return;
      setState(() {
        for (final f in files) {
          _slots.add(
            ProductImageSlot(
              key: 'local_${f.path}_${DateTime.now().microsecondsSinceEpoch}',
              localFile: f,
            ),
          );
        }
      });
      _notify();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              files.length == 1
                  ? 'Image added'
                  : '${files.length} images added',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on ProductImageException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Upload failed, retry again');
    }
  }

  Future<void> _addFromCamera() async {
    if (!_canAddMore) {
      _showError('Maximum image limit reached');
      return;
    }
    try {
      final file = await _pickerService.pickFromCamera();
      setState(() {
        _slots.add(
          ProductImageSlot(
            key: 'local_${file.path}_${DateTime.now().microsecondsSinceEpoch}',
            localFile: file,
          ),
        );
      });
      _notify();
    } on ProductImageException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Upload failed, retry again');
    }
  }

  void _removeAt(int index) {
    if (_slots.length <= ProductImageLimits.minImages) {
      _showError('At least 1 image is required');
      return;
    }
    setState(() {
      _slots.removeAt(index);
      if (_previewIndex >= _slots.length) {
        _previewIndex = _slots.length - 1;
      }
    });
    _notify();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _slots.removeAt(oldIndex);
      _slots.insert(newIndex, item);
      _previewIndex = newIndex;
    });
    _notify();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _openFullscreen(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenGallery(
          slots: _slots,
          initialIndex: index,
        ),
      ),
    );
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              subtitle: Text(
                _canAddMore
                    ? 'Select up to ${ProductImageLimits.maxImages - _slots.length} more'
                    : 'Limit reached',
              ),
              enabled: _canAddMore,
              onTap: _canAddMore
                  ? () {
                      Navigator.pop(ctx);
                      _addFromGallery();
                    }
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              enabled: _canAddMore,
              onTap: _canAddMore
                  ? () {
                      Navigator.pop(ctx);
                      _addFromCamera();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewImage(ProductImageSlot slot) {
    if (slot.isLocal) {
      return Image.file(slot.localFile!, fit: BoxFit.cover);
    }
    return Image.network(
      slot.remoteUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = _slots.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library_outlined),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Product images',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${_slots.length}/${ProductImageLimits.maxImages}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Min ${ProductImageLimits.minImages}, max ${ProductImageLimits.maxImages} · JPG, PNG, WebP',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            if (widget.isUploading) ...[
              AppSpacing.h10,
              LinearProgressIndicator(
                value: widget.uploadProgress,
                backgroundColor: Colors.grey.shade200,
                color: AppColor.primary,
              ),
              AppSpacing.h5,
              Text(
                'Uploading images…',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ],
            AppSpacing.h15,
            GestureDetector(
              onTap: hasImages ? () => _openFullscreen(_previewIndex) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasImages
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          _previewImage(_slots[_previewIndex]),
                          if (_previewIndex == 0)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: _ChipLabel('Main', AppColor.primary),
                            ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.black45,
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(Icons.fullscreen, color: Colors.white),
                                onPressed: () => _openFullscreen(_previewIndex),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Add at least 1 product image',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
            ),
            AppSpacing.h10,
            SizedBox(
              height: 108,
              child: Row(
                children: [
                  Expanded(
                    child: ReorderableListView.builder(
                      scrollDirection: Axis.horizontal,
                      buildDefaultDragHandles: false,
                      onReorder: _onReorder,
                      itemCount: _slots.length,
                      itemBuilder: (context, index) {
                        final slot = _slots[index];
                        return _ThumbTile(
                          key: ValueKey(slot.key),
                          index: index,
                          slot: slot,
                          selected: index == _previewIndex,
                          onTap: () => setState(() => _previewIndex = index),
                          onRemove: () => _removeAt(index),
                          image: _previewImage(slot),
                        );
                      },
                    ),
                  ),
                  if (_canAddMore) _AddTile(onTap: _showSourceSheet),
                ],
              ),
            ),
            AppSpacing.h10,
            OutlinedButton.icon(
              onPressed: _canAddMore && !widget.isUploading ? _showSourceSheet : null,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add more images'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _ThumbTile extends StatelessWidget {
  const _ThumbTile({
    super.key,
    required this.index,
    required this.slot,
    required this.selected,
    required this.onTap,
    required this.onRemove,
    required this.image,
  });

  final int index;
  final ProductImageSlot slot;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final Widget image;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        width: 88,
        child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColor.primary : Colors.grey.shade300,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      image,
                      if (index == 0)
                        const Positioned(
                          left: 4,
                          bottom: 4,
                          child: _ChipLabel('Main', AppColor.primary),
                        ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        left: 2,
                        child: ReorderableDragStartListener(
                          index: index,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.drag_handle,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            color: Colors.grey.shade50,
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 28, color: Colors.grey),
              SizedBox(height: 4),
              Text('Add', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery({
    required this.slots,
    required this.initialIndex,
  });

  final List<ProductImageSlot> slots;
  final int initialIndex;

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.slots.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.slots.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) {
          final slot = widget.slots[i];
          final child = slot.isLocal
              ? Image.file(slot.localFile!, fit: BoxFit.contain)
              : Image.network(slot.remoteUrl!, fit: BoxFit.contain);
          return InteractiveViewer(minScale: 0.8, maxScale: 4, child: Center(child: child));
        },
      ),
    );
  }
}
