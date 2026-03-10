import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:milingo/core/network/gemini_api_service.dart';
import 'package:milingo/shared/utils/image_utils.dart';
import 'package:milingo/core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────
// SnapState - Immutable state for Snap & Learn feature
// ─────────────────────────────────────────────────────────

class SnapState {
  const SnapState({
    this.isLoading = false,
    this.result,
    this.error,
    this.capturedImage,
    this.capturedImageBytes,
    this.selectedLanguage = 'en',
    this.showVocabulary = false,
  });

  final bool isLoading;
  final MilingoResult? result;
  final String? error;
  final File? capturedImage;
  final List<int>? capturedImageBytes; // For web platform
  final String selectedLanguage;
  final bool showVocabulary;

  SnapState copyWith({
    bool? isLoading,
    MilingoResult? result,
    String? error,
    File? capturedImage,
    List<int>? capturedImageBytes,
    String? selectedLanguage,
    bool? showVocabulary,
  }) {
    return SnapState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error,
      capturedImage: capturedImage ?? this.capturedImage,
      capturedImageBytes: capturedImageBytes ?? this.capturedImageBytes,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      showVocabulary: showVocabulary ?? this.showVocabulary,
    );
  }
}

// ─────────────────────────────────────────────────────────
// SnapController - Business logic for Snap & Learn
// ─────────────────────────────────────────────────────────

class SnapController extends StateNotifier<SnapState> {
  SnapController(this._geminiService) : super(const SnapState());
  final GeminiApiService _geminiService;

  /// Update selected language
  void setLanguage(String languageCode) {
    state = state.copyWith(selectedLanguage: languageCode);
  }

  /// Show vocabulary view (when user taps an object marker)
  void showVocab() {
    state = state.copyWith(showVocabulary: true);
  }

  /// Hide vocabulary view (back to detected markers view)
  void hideVocab() {
    state = state.copyWith(showVocabulary: false);
  }

  /// Capture image from camera and analyze
  Future<void> captureFromCamera(String targetLanguage) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final File? imageFile = await ImageUtils.pickFromCamera();

      if (imageFile == null) {
        // User cancelled - just reset loading, no error
        state = const SnapState();
        return;
      }

      // Validate file size
      final isValidSize = await ImageUtils.validateFileSize(
        imageFile,
        AppConstants.maxImageSizeBytes,
      );

      if (!isValidSize) {
        state = state.copyWith(
          isLoading: false,
          error: 'Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 5MB.',
        );
        return;
      }

      state = state.copyWith(capturedImage: imageFile);
      await _analyzeFromFile(imageFile, targetLanguage);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi khi chụp ảnh: ${e.toString()}',
      );
    }
  }

  /// Pick image from gallery and analyze
  Future<void> pickFromGallery(String targetLanguage) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final XFile? xFile = await ImageUtils.pickImageAsXFile();

      if (xFile == null) {
        // User cancelled - just reset loading, no error
        state = const SnapState();
        return;
      }

      final imageBytes = await ImageUtils.xFileToBytes(xFile);

      // Validate file size
      if (imageBytes.length > AppConstants.maxImageSizeBytes) {
        state = state.copyWith(
          isLoading: false,
          error: 'Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 5MB.',
        );
        return;
      }

      // Update state with image
      if (kIsWeb) {
        state = state.copyWith(capturedImageBytes: imageBytes);
      } else {
        state = state.copyWith(capturedImage: File(xFile.path));
      }

      await _analyzeFromBytes(imageBytes, targetLanguage);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi khi chọn ảnh: ${e.toString()}',
      );
    }
  }

  /// Analyze image from File
  Future<void> _analyzeFromFile(File file, String targetLanguage) async {
    try {
      final bytes = await ImageUtils.fileToBytes(file);
      await _analyzeFromBytes(bytes, targetLanguage);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi phân tích ảnh: ${e.toString()}',
      );
    }
  }

  /// Analyze image bytes with Gemini AI
  Future<void> _analyzeFromBytes(
      List<int> imageBytes, String targetLanguage) async {
    try {
      final result = await _geminiService.analyzeImageForLanguage(
        imageBytes: Uint8List.fromList(imageBytes),
        targetLanguage: targetLanguage,
      );

      state = state.copyWith(
        isLoading: false,
        result: result,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi phân tích ảnh: ${e.toString()}',
      );
    }
  }

  /// Reset state (preserve selected language)
  void reset() {
    final lang = state.selectedLanguage;
    state = SnapState(selectedLanguage: lang);
  }
}

// ─────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────

final snapControllerProvider =
    StateNotifierProvider<SnapController, SnapState>((ref) {
  final geminiService = ref.watch(geminiApiServiceProvider);
  return SnapController(geminiService);
});
