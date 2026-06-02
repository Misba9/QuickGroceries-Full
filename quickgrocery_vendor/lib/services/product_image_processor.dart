import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:quickgrocery_vendor/constants/product_image_limits.dart';
import 'package:quickgrocery_vendor/services/product_image_upload_service.dart';

/// Validates, compresses, and normalizes vendor product images before upload.
class ProductImageProcessor {
  /// Reads file, validates format/size/dimensions, returns optimized JPEG/PNG bytes.
  static Future<File> prepareForUpload(File source) async {
    final bytes = await source.readAsBytes();
    if (bytes.isEmpty) {
      throw ProductImageException('Image file is empty or corrupted');
    }

    if (bytes.length > ProductImageLimits.maxFileBytes) {
      throw ProductImageException(
        'Image is too large (max ${ProductImageLimits.maxFileBytes ~/ (1024 * 1024)} MB)',
      );
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw ProductImageException('Could not read image — file may be corrupted');
    }

    if (decoded.width < ProductImageLimits.minWidth ||
        decoded.height < ProductImageLimits.minHeight) {
      throw ProductImageException(
        'Image must be at least ${ProductImageLimits.minWidth}×'
        '${ProductImageLimits.minHeight} pixels (yours: ${decoded.width}×${decoded.height})',
      );
    }

    var working = decoded;
    if (working.width > ProductImageLimits.maxWidth ||
        working.height > ProductImageLimits.maxHeight) {
      working = img.copyResize(
        working,
        width: working.width > working.height
            ? ProductImageLimits.maxWidth
            : null,
        height: working.height >= working.width
            ? ProductImageLimits.maxHeight
            : null,
        interpolation: img.Interpolation.linear,
      );
    }

    final ext = source.path.split('.').last.toLowerCase();
    final Uint8List out;
    if (ext == 'png') {
      out = Uint8List.fromList(img.encodePng(working));
    } else {
      out = Uint8List.fromList(img.encodeJpg(working, quality: 88));
    }

    final outFile = File(
      '${source.parent.path}/qg_opt_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await outFile.writeAsBytes(out, flush: true);
    return outFile;
  }

  /// 90° clockwise rotation for vendor preview editing.
  static Future<File> rotate90(File source) async {
    final bytes = await source.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw ProductImageException('Could not rotate image');
    }
    final rotated = img.copyRotate(decoded, angle: 90);
    final out = Uint8List.fromList(img.encodeJpg(rotated, quality: 90));
    final path = '${source.parent.path}/rot_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(path);
    await file.writeAsBytes(out);
    return file;
  }
}
