import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/core/services/storage_service.dart';
import 'package:milingo/features/snap_and_learn/models/milingo_result.dart';
import 'package:milingo/shared/utils/image_utils.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/features/gamification/providers/user_stats_provider.dart';
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
    this.detectedObjects = const [],
    this.currentDetectedIndex = 0,
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

  /// YOLO-only detections waiting for user confirmation.
  final List<DetectedObjectResult> detectedObjects;

  final int currentDetectedIndex;

  DetectedObjectResult? get currentDetectedObject {
    if (detectedObjects.isEmpty) return null;
    if (currentDetectedIndex < 0) return detectedObjects.first;
    if (currentDetectedIndex >= detectedObjects.length) {
      return detectedObjects.last;
    }
    return detectedObjects[currentDetectedIndex];
  }

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
    List<DetectedObjectResult>? detectedObjects,
    int? currentDetectedIndex,
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
      detectedObjects: detectedObjects ?? this.detectedObjects,
      currentDetectedIndex: currentDetectedIndex ?? this.currentDetectedIndex,
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
    boundingBox: item.boundingBox == null
        ? null
        : ObjectBoundingBox(
            x: item.boundingBox!.x,
            y: item.boundingBox!.y,
            width: item.boundingBox!.width,
            height: item.boundingBox!.height,
          ),
    segmentation: item.segmentation == null
        ? null
        : ObjectSegmentation(
            points: [
              for (final point in item.segmentation!.points)
                ObjectSegmentationPoint(x: point.x, y: point.y),
            ],
          ),
    objectImageBase64: item.croppedImageBase64,
  );
}

DetectedObjectResult _detectedObjectToResult(SnapDetectedObject item) {
  return DetectedObjectResult(
    label: item.label,
    confidence: item.confidence,
    boundingBox: ObjectBoundingBox(
      x: item.boundingBox.x,
      y: item.boundingBox.y,
      width: item.boundingBox.width,
      height: item.boundingBox.height,
    ),
    segmentation: item.segmentation == null
        ? null
        : ObjectSegmentation(
            points: [
              for (final point in item.segmentation!.points)
                ObjectSegmentationPoint(x: point.x, y: point.y),
            ],
          ),
    objectImageBase64: item.croppedImageBase64,
  );
}

SnapDetectedObject _resultToDetectedObject(DetectedObjectResult item) {
  return SnapDetectedObject(
    label: item.label,
    confidence: item.confidence,
    boundingBox: SnapBoundingBox(
      x: item.boundingBox.x,
      y: item.boundingBox.y,
      width: item.boundingBox.width,
      height: item.boundingBox.height,
    ),
    segmentation: item.segmentation == null
        ? null
        : SnapSegmentation(
            points: [
              for (final point in item.segmentation!.points)
                SnapSegmentationPoint(x: point.x, y: point.y),
            ],
          ),
    croppedImageBase64: item.objectImageBase64,
  );
}

// ─────────────────────────────────────────────────────────
// SnapController
// ─────────────────────────────────────────────────────────

class SnapController extends StateNotifier<SnapState> {
  SnapController(this._api, this._ref) : super(const SnapState());
  final MilingoApiService _api;
  final Ref _ref;

  void setLanguage(String languageCode) {
    state = state.copyWith(selectedLanguage: languageCode);
  }

  void showVocab() => state = state.copyWith(showVocabulary: true);
  void hideVocab() => state = state.copyWith(showVocabulary: false);

  /// Navigate between multiple detected objects.
  void nextVocabItem() {
    if (state.allVocabItems.isEmpty) return;
    final next = (state.currentVocabIndex + 1) % state.allVocabItems.length;
    state = state.copyWith(
        currentVocabIndex: next, result: state.allVocabItems[next]);
  }

  void prevVocabItem() {
    if (state.allVocabItems.isEmpty) return;
    final prev = (state.currentVocabIndex - 1 + state.allVocabItems.length) %
        state.allVocabItems.length;
    state = state.copyWith(
        currentVocabIndex: prev, result: state.allVocabItems[prev]);
  }

  // ── Capture / pick ─────────────────────────────────────

  Future<void> captureFromCamera(String targetLanguage) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final File? imageFile = await ImageUtils.pickFromCamera();
      if (imageFile == null) {
        state = SnapState(selectedLanguage: state.selectedLanguage);
        return;
      }
      if (!await ImageUtils.validateFileSize(
          imageFile, AppConstants.maxImageSizeBytes)) {
        state = state.copyWith(
            isLoading: false,
            error: 'Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 5MB.');
        return;
      }
      state = state.copyWith(capturedImage: imageFile);
      await _detectFile(imageFile);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Lỗi khi chụp ảnh: ${e.toString()}');
    }
  }

  Future<void> analyzeFile(File imageFile, String targetLanguage) async {
    final language = state.selectedLanguage;
    state = SnapState(
      isLoading: true,
      capturedImage: imageFile,
      selectedLanguage: language,
    );
    try {
      if (!await ImageUtils.validateFileSize(
          imageFile, AppConstants.maxImageSizeBytes)) {
        state = state.copyWith(
            isLoading: false,
            error: 'Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 5MB.');
        return;
      }
      await _detectFile(imageFile);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Lỗi khi chụp ảnh: ${e.toString()}');
    }
  }

  Future<void> pickFromGallery(String targetLanguage) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final xFile = await ImageUtils.pickImageAsXFile();
      if (xFile == null) {
        state = SnapState(selectedLanguage: state.selectedLanguage);
        return;
      }
      final imageBytes = await ImageUtils.xFileToBytes(xFile);
      if (imageBytes.length > AppConstants.maxImageSizeBytes) {
        state = state.copyWith(
            isLoading: false,
            error: 'Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 5MB.');
        return;
      }
      final file = File(xFile.path);
      if (kIsWeb) {
        state = state.copyWith(capturedImageBytes: imageBytes);
      } else {
        state = state.copyWith(capturedImage: file);
      }
      await _detectFile(file);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Lỗi khi chọn ảnh: ${e.toString()}');
    }
  }

  // ── Core analysis ──────────────────────────────────────

  Future<void> _detectFile(File file) async {
    try {
      final detectionResponse = await _api.detectSnap(file);
      final detectedObjects =
          detectionResponse.objects.map(_detectedObjectToResult).toList();

      if (detectedObjects.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Không nhận ra đối tượng nào. Vui lòng thử ảnh khác.',
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        detectedObjects: detectedObjects,
        currentDetectedIndex: 0,
        allVocabItems: const [],
        currentVocabIndex: 0,
        coinsAwarded: 0,
        showVocabulary: false,
        error: null,
      );
    } on MilingoApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Lỗi phân tích ảnh: ${e.toString()}');
    }
  }

  Future<void> confirmDetectionAndAnalyze() async {
    if (state.detectedObjects.isEmpty || state.isLoading) return;

    final detectedObjects = state.detectedObjects;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final snapResponse = await _api.analyzeDetectedSnap(
        detectedObjects.map(_resultToDetectedObject).toList(),
      );
      final allResults =
          snapResponse.vocabItems.map(_vocabItemToMilingoResult).toList();

      if (snapResponse.coinsAwarded > 0) {
        _ref
            .read(userStatsProvider.notifier)
            .addCoinsOptimistic(snapResponse.coinsAwarded);
      }

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
        showVocabulary: true,
        error: null,
      );

      // Upload cropped object images to Firebase Storage in background
      _uploadCroppedImages(allResults);
    } on MilingoApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Lỗi tách vật thể: ${e.toString()}');
    }
  }

  /// Uploads each cropped object image to Firebase Storage in background.
  /// Updates the MilingoResult.objectImageUrl with the download URL.
  Future<void> _uploadCroppedImages(List<MilingoResult> results) async {
    final storage = _ref.read(storageServiceProvider);

    for (int i = 0; i < results.length; i++) {
      final item = results[i];
      if (item.objectImageBase64 == null) continue;

      try {
        final url = await storage.uploadCroppedObjectImage(
          base64Image: item.objectImageBase64!,
          keyword: item.keyword,
        );

        if (url != null) {
          item.objectImageUrl = url;

          // Update state only if this analysis is still current.
          if (state.allVocabItems.length > i &&
              identical(state.allVocabItems[i], item) &&
              state.currentVocabIndex == i) {
            state = state.copyWith(result: item);
          }
        }
      } catch (_) {
        // Non-fatal: image display still works from base64
      }
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
  return SnapController(api, ref);
});
