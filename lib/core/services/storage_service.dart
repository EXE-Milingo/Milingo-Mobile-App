import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

/// Service for uploading cropped object images to Firebase Cloud Storage.
///
/// Images are stored at: `users/{uid}/flashcards/{filename}.jpg`
///
/// Before uploading, the service resizes and JPEG-compresses the image so
/// saved cards do not keep large raw YOLO crops in Storage.
class StorageService {
  StorageService() : _storage = FirebaseStorage.instance;

  final FirebaseStorage _storage;

  static const int _maxDimension = 768;
  static const int _jpegQuality = 68;

  /// Takes a base64-encoded image, compresses it, uploads the result to
  /// Firebase Storage, and returns the download URL.
  ///
  /// [base64Image] — The raw base64 JPEG from the YOLO detection.
  /// [keyword] — Used to build a meaningful filename.
  ///
  /// Returns the public download URL, or `null` if the upload fails.
  Future<String?> uploadCroppedObjectImage({
    required String base64Image,
    required String keyword,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      // 1. Decode base64 → raw bytes
      final Uint8List originalBytes = base64Decode(base64Image);

      // 2. Only resize/compress if the image is large (> 200 KB) to save CPU cycles
      final Uint8List compressedBytes = originalBytes.length > 200 * 1024
          ? _compressImage(originalBytes)
          : originalBytes;

      // 3. Build storage path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = keyword
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final path = 'users/$uid/flashcards/${safeName}_$timestamp.jpg';

      // 4. Upload to Firebase Storage
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'keyword': keyword,
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      );

      await ref.putData(compressedBytes, metadata);

      // 5. Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('[StorageService] Upload failed: $e');
      return null;
    }
  }

  Uint8List _compressImage(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return imageBytes;

    var output = decoded;
    final longestSide =
        decoded.width > decoded.height ? decoded.width : decoded.height;

    if (longestSide > _maxDimension) {
      if (decoded.width >= decoded.height) {
        output = img.copyResize(decoded, width: _maxDimension);
      } else {
        output = img.copyResize(decoded, height: _maxDimension);
      }
    }

    return Uint8List.fromList(
      img.encodeJpg(output, quality: _jpegQuality),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Riverpod Provider
// ─────────────────────────────────────────────────────────

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
