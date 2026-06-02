import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:quickgrocery_vendor/constants/product_image_limits.dart';
import 'package:quickgrocery_vendor/models/product_image_slot.dart';
import 'package:quickgrocery_vendor/services/product_image_processor.dart';
import 'package:quickgrocery_vendor/services/storage_service.dart';

class ProductImageUploadService {
  ProductImageUploadService({
    ImagePicker? picker,
    StorageService? storage,
  })  : _picker = picker ?? ImagePicker(),
        _storage = storage ?? StorageService();

  final ImagePicker _picker;
  final StorageService _storage;

  Future<List<File>> pickFromGallery({required int remainingSlots}) async {
    if (remainingSlots <= 0) {
      throw ProductImageException('Maximum image limit reached');
    }
    final files = await _picker.pickMultiImage(
      imageQuality: ProductImageLimits.pickQuality,
      maxWidth: ProductImageLimits.maxWidth.toDouble(),
      maxHeight: ProductImageLimits.maxHeight.toDouble(),
    );
    if (files.isEmpty) return [];
    final out = <File>[];
    for (final f in files.take(remainingSlots)) {
      out.add(await _validateFile(f));
    }
    return out;
  }

  Future<File> pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: ProductImageLimits.pickQuality,
      maxWidth: ProductImageLimits.maxWidth.toDouble(),
      maxHeight: ProductImageLimits.maxHeight.toDouble(),
    );
    if (file == null) {
      throw ProductImageException('No image captured');
    }
    return _validateFile(file);
  }

  Future<File> rotateImage(File file) => ProductImageProcessor.rotate90(file);

  Future<File> _validateFile(XFile file) async {
    final path = file.path;
    if (!ProductImageLimits.isAllowedExtension(path)) {
      throw ProductImageException(
        'Only JPG, PNG, and WEBP are allowed',
      );
    }
    return ProductImageProcessor.prepareForUpload(File(path));
  }

  Future<List<String>> uploadSlots({
    required List<ProductImageSlot> slots,
    required String vendorId,
    String? productId,
    void Function(int completed, int total)? onProgress,
  }) async {
    final urls = <String>[];
    final local = slots.where((s) => s.isLocal).toList();
    var done = 0;

    for (final slot in slots) {
      if (slot.isRemote) {
        urls.add(slot.remoteUrl!);
        continue;
      }
      if (slot.localFile == null) continue;

      final url = await _storage.uploadProductImage(
        imageFile: slot.localFile!,
        vendorId: vendorId,
        productId: productId,
      );
      urls.add(url);
      done++;
      onProgress?.call(done, local.length);
    }
    return urls;
  }

  Future<void> deleteRemovedUrls({
    required List<String> previousUrls,
    required List<String> nextUrls,
  }) async {
    for (final url in previousUrls) {
      if (!nextUrls.contains(url)) {
        await _storage.deleteImage(url);
      }
    }
  }
}

class ProductImageException implements Exception {
  ProductImageException(this.message);
  final String message;

  @override
  String toString() => message;
}
