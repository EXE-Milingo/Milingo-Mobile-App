import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for uploading cropped object images to Firebase Cloud Storage.
///
/// Images are stored at: `users/{uid}/flashcards/{filename}.jpg`
///
/// Before uploading, the service draws a white border around the
/// decoded image so that the stored version is visually distinct.
class StorageService {
  StorageService() : _storage = FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Border thickness in logical pixels drawn around the cropped object.
  static const double kBorderWidth = 6.0;

  /// Border color.
  static const Color kBorderColor = Colors.white;

  /// Takes a base64-encoded JPEG, draws a white border around it,
  /// uploads the result to Firebase Storage, and returns the download URL.
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

      // 2. Draw white border around the image
      final Uint8List borderedBytes = await _addWhiteBorder(originalBytes);

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

      await ref.putData(borderedBytes, metadata);

      // 5. Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('[StorageService] Upload failed: $e');
      return null;
    }
  }

  /// Decodes a JPEG byte array, draws a white border around it,
  /// and re-encodes as JPEG bytes.
  Future<Uint8List> _addWhiteBorder(Uint8List imageBytes) async {
    // Decode the image
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final originalImage = frame.image;

    final int imgW = originalImage.width;
    final int imgH = originalImage.height;
    final int border = kBorderWidth.toInt();

    // New canvas size = original + border on each side
    final int canvasW = imgW + border * 2;
    final int canvasH = imgH + border * 2;

    // Create a picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, canvasW.toDouble(), canvasH.toDouble()),
    );

    // Fill entire canvas with white (the border)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasW.toDouble(), canvasH.toDouble()),
      Paint()..color = kBorderColor,
    );

    // Draw the original image centered (offset by border width)
    canvas.drawImage(
      originalImage,
      Offset(border.toDouble(), border.toDouble()),
      Paint(),
    );

    // Convert to image
    final picture = recorder.endRecording();
    final borderedImage = await picture.toImage(canvasW, canvasH);

    // Encode as PNG first (Flutter doesn't have direct JPEG encoding),
    // then we'll use the PNG bytes (which Firebase Storage accepts fine)
    final byteData = await borderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    originalImage.dispose();
    borderedImage.dispose();

    if (byteData == null) return imageBytes; // fallback to original
    return byteData.buffer.asUint8List();
  }
}

// ─────────────────────────────────────────────────────────
// Riverpod Provider
// ─────────────────────────────────────────────────────────

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
