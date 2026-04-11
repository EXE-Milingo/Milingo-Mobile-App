import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:milingo/core/network/ai_service.dart';
import 'package:milingo/core/network/ai_provider.dart';
import 'package:milingo/features/snap_and_learn/models/milingo_result.dart';
import 'package:milingo/shared/utils/image_utils.dart';
import 'package:milingo/core/constants/app_constants.dart';

export 'package:milingo/features/snap_and_learn/models/milingo_result.dart';

// ─────────────────────────────────────────────────────────
// SnapState
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
  final List<int>? capturedImageBytes;
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
// SnapController
// ─────────────────────────────────────────────────────────

class SnapController extends StateNotifier<SnapState> {
  SnapController(this._aiService) : super(const SnapState());
  final AIService _aiService;

  void setLanguage(String languageCode) {
    state = state.copyWith(selectedLanguage: languageCode);
  }

  void showVocab() {
    state = state.copyWith(showVocabulary: true);
  }

  void hideVocab() {
    state = state.copyWith(showVocabulary: false);
  }

  Future<void> captureFromCamera(String targetLanguage) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final File? imageFile = await ImageUtils.pickFromCamera();
      if (imageFile == null) {
        state = const SnapState();
        return;
      }
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

  /// Analyze a file captured from the embedded camera preview.
  Future<void> analyzeFile(File imageFile, String targetLanguage) async {
    state = state.copyWith(isLoading: true, error: null, capturedImage: imageFile);
    try {
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
      await _analyzeFromFile(imageFile, targetLanguage);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi khi chụp ảnh: ${e.toString()}',
      );
    }
  }

  Future<void> pickFromGallery(String targetLanguage) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final xFile = await ImageUtils.pickImageAsXFile();
      if (xFile == null) {
        state = const SnapState();
        return;
      }
      final imageBytes = await ImageUtils.xFileToBytes(xFile);
      if (imageBytes.length > AppConstants.maxImageSizeBytes) {
        state = state.copyWith(
          isLoading: false,
          error: 'Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 5MB.',
        );
        return;
      }
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

  Future<void> _analyzeFromBytes(
      List<int> imageBytes, String targetLanguage) async {
    try {
      final result = await _aiService.analyzeImageForLanguage(
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
  final aiService = ref.watch(aiServiceProvider);
  return SnapController(aiService);
});
