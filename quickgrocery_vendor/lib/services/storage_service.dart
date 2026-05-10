import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload image to Firebase Storage
  /// Returns the download URL
  Future<String> uploadProductImage({
    required File imageFile,
    required String vendorId,
    String? productId,
  }) async {
    try {
      // Get file extension
      final String extension = imageFile.path.split('.').last;
      
      // Create a unique filename
      final String fileName = productId != null
          ? 'products/$vendorId/$productId/${DateTime.now().millisecondsSinceEpoch}.$extension'
          : 'products/$vendorId/temp/${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Create reference to the file location
      final Reference ref = _storage.ref().child(fileName);

      // Upload the file
      final UploadTask uploadTask = ref.putFile(imageFile);

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract the path from the URL
      final Uri uri = Uri.parse(imageUrl);
      final String path = uri.pathSegments
          .skipWhile((segment) => segment != 'o')
          .skip(1)
          .join('/');

      // Decode the path (URL encoding)
      final String decodedPath = Uri.decodeComponent(path.split('?').first);

      // Create reference and delete
      final Reference ref = _storage.ref(decodedPath);
      await ref.delete();
    } catch (e) {
      // If deletion fails, just log it but don't throw
      // The image might already be deleted or URL format might be different
      print('Error deleting image: $e');
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String vendorId,
    String? productId,
  }) async {
    try {
      final List<String> downloadUrls = [];

      for (var imageFile in imageFiles) {
        final url = await uploadProductImage(
          imageFile: imageFile,
          vendorId: vendorId,
          productId: productId,
        );
        downloadUrls.add(url);
      }

      return downloadUrls;
    } catch (e) {
      rethrow;
    }
  }
}

