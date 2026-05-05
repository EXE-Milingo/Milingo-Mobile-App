import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/features/snap_and_learn/models/milingo_result.dart';
import 'package:milingo/shared/utils/image_utils.dart';
import 'package:milingo/core/constants/app_constants.dart';

export 'package:milingo/features/snap_and_learn/models/milingo_result.dart';

// ─────────────────────────────────────────────────────────
// SnapState (unchanged shape — UI needs no changes)
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
    this.allVocabItems = const [],
    this.currentVocabIndex = 0,
    this.coinsAwarded = 0,
  });

  final bool isLoading;
  final MilingoResult? result;
  final String? error;
  final File? capturedImage;
  final List<int>? capturedImageBytes;
  final String selectedLanguage;
  final bool showVocabulary;

  /// All vocabulary items from the backend (multi-object support).
  final List<MilingoResult> allVocabItems;

  /// Index of the currently displayed vocab item.
  final int currentVocabIndex;

  /// Coins awarded by the backend for this snap.
  final int coinsAwarded;

  SnapState copyWith({
    bool? isLoading,
    MilingoResult? result,
    String? error,
    File? capturedImage,
    List<int>? capturedImageBytes,
    String? selectedLanguage,
    bool? showVocabulary,
    List<MilingoResult>? allVocabItems,
    int? currentVocabIndex,
    int? coinsAwarded,
  }) {
    return SnapState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error, // null clears the error
      capturedImage: capturedImage ?? this.capturedImage,
      capturedImageBytes: capturedImageBytes ?? this.capturedImageBytes,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      showVocabulary: showVocabulary ?? this.showVocabulary,
      allVocabItems: allVocabItems ?? this.allVocabItems,
      currentVocabIndex: currentVocabIndex ?? this.currentVocabIndex,
      coinsAwarded: coinsAwarded ?? this.coinsAwarded,
    );
  }
}

// ─────────────────────────────────────────────────────────
// Mapping helper: SnapVocabItem → MilingoResult
// Keeps the existing MilingoResult shape so snap UI widgets
// need zero changes.
// ─────────────────────────────────────────────────────────

MilingoResult _vocabItemToMilingoResult(SnapVocabItem item) {
  return MilingoResult(
    keyword: item.keyword,
    translation: item.translation,
    pronunciation: item.pronunciation,
    partOfSpeech: 'Noun',
    sentence: item.exampleSentence,
    sentenceTranslation: '',
    relatedWords: const [],
  );
}

// ─────────────────────────────────────────────────────────
// SnapController
// ─────────────────────────────────────────────────────────

class SnapController extends StateNotifier<SnapState> {
  SnapController(this._api) : super(const SnapState());

  final MilingoApiService _api;

  void setLanguage(String languageCode) {
    state = state.copyWith(selectedLanguage: languageCode);
  }

  void showVocab() => state = state.copyWith(showVocabulary: true);
  void hideVocab() => state = state.copyWith(showVocabulary: false);

  /// Navigate between multiple detected objects.
  void nextVocabItem() {
    if (state.allVocabItems.isEmpty) return;
    final next = (state.currentVocabIndex + 1) % state.allVocabItems.length;
    state = state.copyWith(currentVocabIndex: next, result: state.allVocabItems[next]);
  }

  void prevVocabItem() {
    if (state.allVocabItems.isEmpty) return;
    final prev = (state.currentVocabIndex - 1 + state.allVocabItems.length) % state.allVocabItems.length;
    state = state.copyWith(currentVocabIndex: prev, result: state.allVocabItems[prev]);
  }

  // ── Capture / pick ─────────────────────────────────────

  Future<void> captureFromCamera(String targetLanguage) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final File? imageFile = await ImageUtils.pickFromCamera();
      if (imageFile == null) { state = SnapState(selectedLanguage: state.selectedLanguage); return; }
      if (!await ImageUtils.validateFileSize(imageFile, AppConstants.maxImageSizeBytes)) {
        state = state.copyWith(isLoading: false, error: 'Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 5MB.');
        return;
      }
      state = state.copyWith(capturedImage: imageFile);
      await _analyzeFile(imageFile);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Lỗi khi chụp ảnh: ${e.toString()}');
    }
  }

  Future<void> analyzeFile(File imageFile, String targetLanguage) async {
    state = state.copyWith(isLoading: true, error: null, capturedImage: imageFile);
    try {
      if (!await ImageUtils.validateFileSize(imageFile, AppConstants.maxImageSizeBytes)) {
        state = state.copyWith(isLoading: false, error: 'Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 5MB.');
        return;
      }
      await _analyzeFile(imageFile);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Lỗi khi chụp ảnh: ${e.toString()}');
    }
  }

  Future<void> pickFromGallery(String targetLanguage) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final xFile = await ImageUtils.pickImageAsXFile();
      if (xFile == null) { state = SnapState(selectedLanguage: state.selectedLanguage); return; }
      final imageBytes = await ImageUtils.xFileToBytes(xFile);
      if (imageBytes.length > AppConstants.maxImageSizeBytes) {
        state = state.copyWith(isLoading: false, error: 'Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 5MB.');
        return;
      }
      final file = File(xFile.path);
      if (kIsWeb) {
        state = state.copyWith(capturedImageBytes: imageBytes);
      } else {
        state = state.copyWith(capturedImage: file);
      }
      await _analyzeFile(file);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Lỗi khi chọn ảnh: ${e.toString()}');
    }
  }

  // ── Core analysis ──────────────────────────────────────

  Future<void> _analyzeFile(File file) async {
    try {
      final snapResponse = await _api.analyzeSnap(file);
      final allResults = snapResponse.vocabItems.map(_vocabItemToMilingoResult).toList();

      if (allResults.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Không nhận ra đối tượng nào. Vui lòng thử ảnh khác.',
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        result: allResults.first,
        allVocabItems: allResults,
        currentVocabIndex: 0,
        coinsAwarded: snapResponse.coinsAwarded,
        error: null,
      );
    } on MilingoApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Lỗi phân tích ảnh: ${e.toString()}');
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
  final api = ref.watch(milingoApiServiceProvider);
  return SnapController(api);
});