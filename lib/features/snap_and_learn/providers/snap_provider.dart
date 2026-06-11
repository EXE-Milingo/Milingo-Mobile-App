import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/features/snap_and_learn/models/milingo_result.dart';
import 'package:milingo/shared/utils/image_utils.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/features/gamification/providers/user_stats_provider.dart';
import 'package:milingo/features/profile/providers/profile_provider.dart';
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
    this.paywallRequired = false,
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
  final bool paywallRequired;

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
    bool? paywallRequired,
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
      paywallRequired: paywallRequired ?? this.paywallRequired,
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
    relatedWords: item.relatedWords
        .map(
          (word) => RelatedWord(
            english: word.keyword,
            translation: word.translation,
            pronunciation: word.pronunciation,
          ),
        )
        .toList(),
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
  SnapController(
    this._api,
    this._ref, {
    String initialLanguage = 'en',
  }) : super(SnapState(
          selectedLanguage: _normalizeLearningLanguage(initialLanguage),
        ));
  final MilingoApiService _api;
  final Ref _ref;

  void setLanguage(String languageCode) {
    state = state.copyWith(
      selectedLanguage: _normalizeLearningLanguage(languageCode),
    );
  }

  void setProfileLanguageIfIdle(String languageCode) {
    if (state.selectedLanguage != 'en' ||
        state.isLoading ||
        state.capturedImage != null ||
        state.capturedImageBytes != null ||
        state.detectedObjects.isNotEmpty ||
        state.showVocabulary) {
      return;
    }
    setLanguage(languageCode);
  }

  void showVocab() => state = state.copyWith(showVocabulary: true);
  void hideVocab() => state = state.copyWith(showVocabulary: false);

  Future<bool> ensureCanScan() async {
    try {
      final quota = await _api.getSnapQuotaStatus();
      if (quota.isLimitReached) {
        state = state.copyWith(
          isLoading: false,
          error: null,
          paywallRequired: true,
        );
        return false;
      }
      return true;
    } on MilingoApiException catch (e) {
      if (_isQuotaExceeded(e)) {
        state = state.copyWith(
          isLoading: false,
          error: null,
          paywallRequired: true,
        );
        return false;
      }
      return true;
    }
  }

  void clearPaywallRequired() {
    if (!state.paywallRequired) return;
    state = state.copyWith(paywallRequired: false);
  }

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

  bool _isQuotaExceeded(MilingoApiException e) => e.statusCode == 402;

  // ── Capture / pick ─────────────────────────────────────

  Future<void> captureFromCamera(String targetLanguage) async {
    final language = _normalizeLearningLanguage(targetLanguage);
    state = state.copyWith(error: null, selectedLanguage: language);
    if (!await ensureCanScan()) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedLanguage: language,
    );
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

  Future<void> analyzeFile(
    File imageFile,
    String targetLanguage, {
    bool skipQuotaCheck = false,
  }) async {
    final language = _normalizeLearningLanguage(targetLanguage);
    state = state.copyWith(error: null, selectedLanguage: language);
    if (!skipQuotaCheck && !await ensureCanScan()) return;

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
    final language = _normalizeLearningLanguage(targetLanguage);
    state = state.copyWith(error: null, selectedLanguage: language);
    if (!await ensureCanScan()) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedLanguage: language,
    );
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
      if (_isQuotaExceeded(e)) {
        state = state.copyWith(
          isLoading: false,
          error: null,
          paywallRequired: true,
        );
        return;
      }
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
        targetLanguage: state.selectedLanguage,
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
    } on MilingoApiException catch (e) {
      if (_isQuotaExceeded(e)) {
        state = state.copyWith(
          isLoading: false,
          error: null,
          paywallRequired: true,
        );
        return;
      }
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Lỗi tách vật thể: ${e.toString()}');
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
  final controller = SnapController(
    api,
    ref,
    initialLanguage:
        ref.read(userProfileProvider).valueOrNull?.targetLanguage ?? 'en',
  );

  ref.listen(userProfileProvider, (_, next) {
    final language = next.valueOrNull?.targetLanguage;
    if (language != null) {
      controller.setProfileLanguageIfIdle(language);
    }
  });

  return controller;
});

String _normalizeLearningLanguage(String? language) {
  final value = language?.trim();
  if (value == null || value.isEmpty) return 'en';

  final code = value.toLowerCase().split('-').first;
  const nameToCode = {
    'english': 'en',
    'japanese': 'ja',
    'chinese': 'zh',
    'korean': 'ko',
    'french': 'fr',
    'german': 'de',
    'spanish': 'es',
    'italian': 'it',
    'thai': 'th',
    'vietnamese': 'vi',
  };

  return nameToCode[code] ?? code;
}
