import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/snap_and_learn/providers/snap_provider.dart';
import 'package:milingo/features/snap_and_learn/widgets/vocab_bubble.dart';
import 'package:milingo/features/snap_and_learn/widgets/bottom_capture_bar.dart';
import 'package:milingo/features/snap_and_learn/widgets/save_flashcard_sheet.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens (warm orange accent like mockup)
// ─────────────────────────────────────────────────────────────────────────────

const _kAccent = Color(0xFFF25F36);
const _kAccentLight = Color(0xFFFFF0EB);
const _kBg = Color(0xFFFAF8F5);

class _Lang {
  const _Lang(this.code, this.flag, this.name);
  final String code, flag, name;
}

const _kLanguages = [
  _Lang('en', '🇺🇸', 'English'),
  _Lang('ja', '🇯🇵', '日本語'),
  _Lang('ko', '🇰🇷', '한국어'),
  _Lang('zh', '🇨🇳', '中文'),
  _Lang('es', '🇪🇸', 'Español'),
  _Lang('fr', '🇫🇷', 'Français'),
  _Lang('de', '🇩🇪', 'Deutsch'),
  _Lang('th', '🇹🇭', 'ไทย'),
];

const _kTtsLocales = {
  'en': 'en-US',
  'ja': 'ja-JP',
  'ko': 'ko-KR',
  'zh': 'zh-CN',
  'es': 'es-ES',
  'fr': 'fr-FR',
  'de': 'de-DE',
  'th': 'th-TH',
};

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class SnapAndLearnScreen extends ConsumerStatefulWidget {
  const SnapAndLearnScreen({super.key});

  @override
  ConsumerState<SnapAndLearnScreen> createState() => _SnapAndLearnScreenState();
}

class _SnapAndLearnScreenState extends ConsumerState<SnapAndLearnScreen>
    with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();

  // Camera
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  String _cameraErrorMsg = '';

  // Bubble pop-in animation
  late final AnimationController _bubbleCtrl;
  // Scanning dots animation
  late final AnimationController _scanCtrl;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initCamera();

    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _isCameraError = true;
          _cameraErrorMsg = 'Không tìm thấy camera trên thiết bị.';
        });
        return;
      }

      // Prefer back camera
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraError = true;
          _cameraErrorMsg = 'Lỗi khởi tạo camera: $e';
        });
      }
    }
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
  }

  Future<void> _speak(String text, String langCode) async {
    await _tts.setLanguage(_kTtsLocales[langCode] ?? 'en-US');
    await _tts.speak(text);
  }

  void _showSaveToFlashcard(BuildContext context, FlashcardEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SaveFlashcardSheet(entry: entry),
    );
  }

  /// Take a picture from the embedded camera preview and detect it.
  Future<void> _captureFromEmbeddedCamera() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final xFile = await _cameraController!.takePicture();
      final file = File(xFile.path);
      final ctrl = ref.read(snapControllerProvider.notifier);
      final snap = ref.read(snapControllerProvider);
      await ctrl.analyzeFile(file, snap.selectedLanguage);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chụp ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cropCapturedImageAndAnalyze(
    SnapState snap,
    SnapController ctrl,
  ) async {
    final image = snap.capturedImage;
    if (image == null || snap.isLoading) return;

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 92,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Can chinh vat the',
            toolbarColor: _kAccent,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: _kAccent,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: const [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Can chinh vat the',
            doneButtonTitle: 'Xong',
            cancelButtonTitle: 'Huy',
            aspectRatioPresets: const [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 520, height: 520),
          ),
        ],
      );

      if (croppedFile == null || !mounted) return;
      await ctrl.analyzeFile(File(croppedFile.path), snap.selectedLanguage);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loi cat anh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _cameraController?.dispose();
    _bubbleCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  _Lang _lang(String code) => _kLanguages.firstWhere((l) => l.code == code,
      orElse: () => _kLanguages.first);

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(snapControllerProvider);
    final ctrl = ref.read(snapControllerProvider.notifier);

    // Listen for state transitions
    ref.listen<SnapState>(snapControllerProvider, (prev, next) {
      // When loading starts → run scan animation
      if (next.isLoading && !(prev?.isLoading ?? false)) {
        _scanCtrl.repeat();
      }
      // When result arrives, stop at review so user can approve/crop/retake.
      if (prev?.result == null && next.result != null) {
        _scanCtrl.stop();
      }
      // When vocabulary view opens → trigger bubble animation
      if (!(prev?.showVocabulary ?? false) && next.showVocabulary) {
        _bubbleCtrl.forward(from: 0);
      }
    });

    if (snap.showVocabulary && snap.result != null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: _buildResultScreen(snap, ctrl),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Layer 0: Live Camera Preview (full screen background) ──
            _buildCameraLayer(snap),

            // ── Layer 1: Dark overlay when analyzing/vocab ──
            if (snap.capturedImage != null)
              Container(color: Colors.black.withOpacity(0.15)),

            // ── Layer 2: Captured image overlay (after snap) ──
            if (snap.capturedImage != null)
              Positioned.fill(
                child: snap.currentDetectedObject == null
                    ? Image.file(
                        File(snap.capturedImage!.path),
                        fit: BoxFit.cover,
                      )
                    : _FocusedObjectPreview(
                        imageFile: File(snap.capturedImage!.path),
                        boundingBox: snap.currentDetectedObject!.boundingBox,
                        segmentation: snap.currentDetectedObject!.segmentation,
                      ),
              ),
            if (snap.currentDetectedObject != null &&
                snap.capturedImage != null)
              Positioned.fill(
                child: _DetectedObjectOverlay(
                  imageFile: File(snap.capturedImage!.path),
                  boundingBox: snap.currentDetectedObject!.boundingBox,
                  segmentation: snap.currentDetectedObject!.segmentation,
                ),
              ),

            // ── Layer 3: Semi-transparent overlay when analyzing ──
            if (snap.isLoading)
              Container(color: Colors.white.withOpacity(0.25)),

            // ── Layer 4: Scanning dots animation ──
            if (snap.isLoading) ..._buildScanningDots(),

            // ── Layer 5: Vocabulary bubbles ──
            if (snap.showVocabulary && snap.result != null)
              Positioned.fill(
                child: Stack(
                  children:
                      _buildVocabBubbles(snap.result!, snap.selectedLanguage),
                ),
              ),

            // ── Layer 6: UI overlay ──
            if (snap.error == null) _buildUIOverlay(snap, ctrl),

            // ── Error overlay (full screen) ──
            if (snap.error != null)
              Positioned.fill(
                child: _buildErrorView(snap.error!, ctrl),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CAMERA LAYER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildResultScreen(SnapState snap, SnapController ctrl) {
    final result = snap.result!;
    final objectBytes = result.objectImageBase64 == null
        ? null
        : base64Decode(result.objectImageBase64!);
    final compact = MediaQuery.sizeOf(context).height < 760;
    final objectHeight = compact ? 230.0 : 300.0;
    final wordFontSize = compact ? 34.0 : 44.0;
    final pronunciationFontSize = compact ? 22.0 : 28.0;
    final translationFontSize = compact ? 26.0 : 32.0;
    final actionSize = compact ? 70.0 : 82.0;
    final confirmSize = compact ? 112.0 : 132.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(
          children: [
            Spacer(flex: compact ? 1 : 2),
            SizedBox(
              height: objectHeight,
              child: _buildResultObjectPreview(
                snap: snap,
                result: result,
                objectBytes: objectBytes,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      result.keyword,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: wordFontSize,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        height: 0.95,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _speak(result.keyword, 'en'),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      color: AppTheme.primaryColor,
                      size: 25,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              result.pronunciation.isEmpty ? '' : '/${result.pronunciation}/',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: pronunciationFontSize,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              result.translation,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: translationFontSize,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => _showExampleSentence(result),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: compact ? 15 : 19),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.26),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 14),
                    Text(
                      'Xem c\u00e2u v\u00ed d\u1ee5',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 20 : 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Spacer(flex: compact ? 1 : 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ReviewRoundButton(
                  icon: Icons.photo_camera_outlined,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF9C9C9C),
                  size: actionSize,
                  iconSize: compact ? 30 : 34,
                  onTap: ctrl.reset,
                ),
                _ReviewRoundButton(
                  icon: Icons.check_rounded,
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  size: confirmSize,
                  iconSize: compact ? 72 : 86,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.24),
                  onTap: () => _showSaveToFlashcard(
                    context,
                    FlashcardEntry(
                      id: '${result.keyword}_${snap.selectedLanguage}',
                      english: result.keyword,
                      translation: result.translation,
                      pronunciation: result.pronunciation,
                      partOfSpeech: result.partOfSpeech,
                      langCode: snap.selectedLanguage,
                    ),
                  ),
                ),
                _ReviewRoundButton(
                  icon: Icons.close_rounded,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF9C9C9C),
                  size: actionSize,
                  iconSize: compact ? 34 : 40,
                  onTap: ctrl.reset,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultObjectPreview({
    required SnapState snap,
    required MilingoResult result,
    required Uint8List? objectBytes,
  }) {
    final capturedImage = snap.capturedImage;
    final boundingBox =
        result.boundingBox ?? snap.currentDetectedObject?.boundingBox;
    final segmentation =
        result.segmentation ?? snap.currentDetectedObject?.segmentation;

    Widget child;
    if (capturedImage != null && boundingBox != null && boundingBox.isValid) {
      child = _ObjectCutoutPreview(
        imageFile: capturedImage,
        boundingBox: boundingBox,
        segmentation: segmentation,
      );
    } else if (objectBytes != null) {
      child = Padding(
        padding: const EdgeInsets.all(10),
        child: Image.memory(objectBytes, fit: BoxFit.contain),
      );
    } else {
      child = const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          size: 96,
          color: Colors.black26,
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  void _showExampleSentence(MilingoResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          22,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              result.sentence.isEmpty
                  ? 'Ch\u01b0a c\u00f3 c\u00e2u v\u00ed d\u1ee5.'
                  : result.sentence,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF2A2A2A),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.28,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => _speak(result.sentence, 'en'),
              child: const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFF4EA5AC),
                size: 34,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraLayer(SnapState snap) {
    // If we have a captured image, camera isn't visible anyway
    if (snap.capturedImage != null) return const SizedBox.shrink();

    if (_isCameraError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_rounded, size: 48, color: Colors.white38),
              const SizedBox(height: 12),
              Text(
                _cameraErrorMsg,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'Đang khởi tạo camera...',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Full-screen camera preview
    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // UI OVERLAY (top bar + bottom bar + status chips)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildUIOverlay(SnapState snap, SnapController ctrl) {
    final hasImage = snap.capturedImage != null;
    final isAnalyzing = snap.isLoading;
    final hasResult = snap.result != null;
    final hasDetection = snap.currentDetectedObject != null;
    final showVocab = snap.showVocabulary;
    final showReview = hasDetection && !isAnalyzing && !showVocab;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ── Top Bar ──
          _buildTopBar(hasResult || hasDetection, ctrl),

          // ── "Hoàn thành" chip (shown after capture) ──
          if (hasImage)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: _HoanThanhChip(done: hasDetection && !isAnalyzing),
            ),

          const Spacer(),

          // ── "Chọn ngôn ngữ khác" button (vocab phase only) ──
          if (showVocab)
            GestureDetector(
              onTap: () => _showLanguagePicker(ctrl, snap.selectedLanguage),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 6),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kAccent, Color(0xFFf5a97a)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text('Chọn ngôn ngữ khác',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
            ),

          // ── Bottom Vocab Card (vocab phase only) ──
          if (showVocab && hasResult)
            _buildBottomVocabCard(snap.result!, snap.selectedLanguage),

          // ── Review actions or fresh capture controls ──
          if (showReview)
            _buildReviewActionBar(snap, ctrl)
          else if (!showVocab && !hasImage)
            BottomCaptureBar(
              onGallery: () => ctrl.pickFromGallery(snap.selectedLanguage),
              onCapture: _captureFromEmbeddedCamera,
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  Widget _buildReviewActionBar(SnapState snap, SnapController ctrl) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      padding: const EdgeInsets.fromLTRB(34, 18, 34, 30),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.10),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ReviewRoundButton(
            icon: Icons.close_rounded,
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.textSecondary,
            borderColor: AppTheme.primaryColor.withValues(alpha: 0.12),
            size: 66,
            iconSize: 34,
            onTap: ctrl.reset,
          ),
          _ReviewRoundButton(
            icon: Icons.check_rounded,
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shadowColor: AppTheme.primaryColor.withValues(alpha: 0.38),
            size: 106,
            iconSize: 72,
            onTap: ctrl.confirmDetectionAndAnalyze,
          ),
          _ReviewRoundButton(
            icon: Icons.crop_rounded,
            backgroundColor: const Color(0xFFFFEFE8),
            foregroundColor: AppTheme.primaryColor,
            borderColor: AppTheme.primaryColor.withValues(alpha: 0.16),
            size: 66,
            iconSize: 34,
            onTap: () => _cropCapturedImageAndAnalyze(snap, ctrl),
          ),
        ],
      ),
    );
  }

  // TOP BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopBar(bool hasResult, SnapController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              ctrl.reset();
              context.go(AppConstants.homeRoute);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: Colors.white),
            ),
          ),
          const Spacer(),

          // Title
          if (hasResult || ref.read(snapControllerProvider).isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('BÓC TÁCH VẬT THỂ',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1)),
            ),

          const Spacer(),

          // Right spacer balances the back button.
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ─── Scanning orange dots ────────────────────────────────────────

  List<Widget> _buildScanningDots() {
    // 6 orange dots at various positions (like mockup)
    const dotPositions = [
      Alignment(-0.2, -0.1),
      Alignment(0.1, 0.2),
      Alignment(-0.3, 0.4),
      Alignment(0.3, -0.3),
      Alignment(0.0, 0.5),
      Alignment(-0.1, 0.1),
      Alignment(0.25, 0.0),
    ];

    return dotPositions.asMap().entries.map((entry) {
      final i = entry.key;
      final pos = entry.value;
      return AnimatedBuilder(
        animation: _scanCtrl,
        builder: (_, __) {
          // Staggered opacity pulse
          final phase = (_scanCtrl.value + i * 0.12) % 1.0;
          final opacity =
              (math.sin(phase * math.pi * 2) * 0.5 + 0.5).clamp(0.0, 1.0);
          final scale = 0.6 + opacity * 0.6;

          return Align(
            alignment: pos,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 32 + i * 4.0,
                height: 32 + i * 4.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kAccent.withOpacity(opacity * 0.8),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  // ─── Vocabulary Bubbles ──────────────────────────────────────────

  List<Widget> _buildVocabBubbles(MilingoResult result, String langCode) {
    if (result.relatedWords.isEmpty) return [];

    const positions = [
      Alignment(0.0, -0.88), // top-center
      Alignment(-0.9, -0.6), // top-left
      Alignment(0.9, -0.65), // top-right
      Alignment(0.85, -0.1), // middle-right
    ];

    return result.relatedWords.asMap().entries.map((entry) {
      final i = entry.key;
      if (i >= positions.length) return const SizedBox.shrink();
      final word = entry.value;
      final pos = positions[i];

      return AnimatedBuilder(
        animation: _bubbleCtrl,
        builder: (_, child) {
          final t = CurvedAnimation(
            parent: _bubbleCtrl,
            curve: Interval(i * 0.12, 0.5 + i * 0.12, curve: Curves.elasticOut),
          ).value.clamp(0.0, 1.0);
          return Opacity(
            opacity: t,
            child: Transform.scale(scale: t, child: child),
          );
        },
        child: Align(
          alignment: pos,
          child: VocabBubble(
            english: word.english,
            translation: word.translation,
            pronunciation: word.pronunciation,
            onSpeak: () => _speak(word.translation, langCode),
            onSave: () => _showSaveToFlashcard(
              context,
              FlashcardEntry(
                id: '${word.english}_$langCode',
                english: word.english,
                translation: word.translation,
                pronunciation: word.pronunciation,
                langCode: langCode,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // BOTTOM VOCAB CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBottomVocabCard(MilingoResult r, String langCode) {
    final snap = ref.watch(snapControllerProvider);
    final ctrl = ref.read(snapControllerProvider.notifier);
    final hasMultipleItems = snap.allVocabItems.length > 1;
    final currentIndex = snap.currentVocabIndex;
    final totalItems = snap.allVocabItems.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Object image with white border (if available) ──
          if (r.objectImageBase64 != null) _buildObjectImageCard(r),

          // ── Multi-object navigation ──
          if (hasMultipleItems)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: ctrl.prevVocabItem,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _kAccentLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: _kAccent, size: 20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${currentIndex + 1} / $totalItems',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: ctrl.nextVocabItem,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _kAccentLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: _kAccent, size: 20),
                    ),
                  ),
                ],
              ),
            ),

          // ── Vocabulary info row ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column: icon buttons + keyword + pronunciation + POS
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action icons
                    Row(
                      children: [
                        _SmallIconBtn(
                          icon: Icons.copy_rounded,
                          onTap: () {
                            Clipboard.setData(ClipboardData(
                                text: '${r.keyword} - ${r.translation}'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Đã copy! 📋'),
                                backgroundColor: _kAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _SmallIconBtn(
                          icon: Icons.volume_up_rounded,
                          onTap: () => _speak(r.translation, langCode),
                        ),
                        const SizedBox(width: 8),
                        _SmallIconBtn(
                          icon: Icons.bookmark_add_rounded,
                          onTap: () => _showSaveToFlashcard(
                            context,
                            FlashcardEntry(
                              id: '${r.keyword}_$langCode',
                              english: r.keyword,
                              translation: r.translation,
                              pronunciation: r.pronunciation,
                              partOfSpeech: r.partOfSpeech,
                              langCode: langCode,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Keyword (English)
                    Text(r.keyword,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF222222))),
                    const SizedBox(height: 2),

                    // Pronunciation
                    Text('/${r.pronunciation}/',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 6),

                    // Part of speech
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(r.partOfSpeech,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600])),
                    ),
                  ],
                ),
              ),

              // Right column: Translation large + romanized label
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => _speak(r.translation, langCode),
                      child: Text(
                        r.translation,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF333333),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.pronunciation.toUpperCase(),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[400],
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the cropped object image card with a white border and
  /// elegant drop shadow, giving the image a "polaroid" feel.
  Widget _buildObjectImageCard(MilingoResult r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: _kAccent.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            base64Decode(r.objectImageBase64!),
            height: 140,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              height: 100,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image_rounded,
                    color: Colors.grey, size: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ERROR VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildErrorView(String error, SnapController ctrl) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                ),
                child: const Icon(Icons.error_outline_rounded,
                    size: 56, color: Color(0xFFFF6B6B)),
              ),
              const SizedBox(height: 24),
              const Text('Có lỗi xảy ra',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 12),
              Text(error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: Colors.white60, height: 1.5)),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: ctrl.reset,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: _kAccent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Thử lại',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Language Picker ──────────────────────────────────────────────────────

  void _showLanguagePicker(SnapController ctrl, String currentCode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Chọn ngôn ngữ học',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('AI sẽ dịch vật thể sang ngôn ngữ bạn chọn',
                style: TextStyle(
                    fontSize: 14, color: Colors.white.withOpacity(0.6))),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.8,
              children: _kLanguages.map((lang) {
                final selected = lang.code == currentCode;
                return GestureDetector(
                  onTap: () {
                    ctrl.setLanguage(lang.code);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                              colors: [_kAccent, Color(0xFFf5a97a)])
                          : null,
                      color: selected ? null : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.1)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Text(lang.flag, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(lang.name,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: Colors.white),
                                overflow: TextOverflow.ellipsis)),
                        if (selected)
                          const Icon(Icons.check_circle,
                              color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _ReviewRoundButton extends StatelessWidget {
  const _ReviewRoundButton({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.size,
    required this.iconSize,
    required this.onTap,
    this.borderColor,
    this.shadowColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;
  final double iconSize;
  final VoidCallback onTap;
  final Color? borderColor;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: shadowColor ?? Colors.black.withValues(alpha: 0.08),
                blurRadius: shadowColor == null ? 14 : 22,
                offset: Offset(0, shadowColor == null ? 6 : 10),
              ),
            ],
          ),
          child: Icon(icon, color: foregroundColor, size: iconSize),
        ),
      ),
    );
  }
}

/// "Hoàn thành" status chip
class _HoanThanhChip extends StatelessWidget {
  const _HoanThanhChip({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: done ? _kAccentLight : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.auto_awesome : Icons.hourglass_top_rounded,
            color: done ? _kAccent : Colors.grey[500],
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            done ? 'Hoàn thành' : 'Đang phân tích...',
            style: TextStyle(
              color: done ? _kAccent : Colors.grey[600],
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets below are now in snap_and_learn/widgets/ ────────────────────────
// BottomCaptureBar  → widgets/bottom_capture_bar.dart
// VocabBubble       → widgets/vocab_bubble.dart
// SaveFlashcardSheet→ widgets/save_flashcard_sheet.dart

class _ObjectCutoutPreview extends StatefulWidget {
  const _ObjectCutoutPreview({
    required this.imageFile,
    required this.boundingBox,
    this.segmentation,
  });

  final File imageFile;
  final ObjectBoundingBox boundingBox;
  final ObjectSegmentation? segmentation;

  @override
  State<_ObjectCutoutPreview> createState() => _ObjectCutoutPreviewState();
}

class _ObjectCutoutPreviewState extends State<_ObjectCutoutPreview> {
  ui.Image? _image;
  Object? _loadToken;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant _ObjectCutoutPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageFile.path != widget.imageFile.path) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final token = Object();
    _loadToken = token;
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted || _loadToken != token) {
      frame.image.dispose();
      return;
    }
    final previous = _image;
    setState(() => _image = frame.image);
    previous?.dispose();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return const SizedBox.expand();
    }

    return CustomPaint(
      painter: _ObjectCutoutPainter(
        image: image,
        boundingBox: widget.boundingBox,
        segmentation: widget.segmentation,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ObjectCutoutPainter extends CustomPainter {
  const _ObjectCutoutPainter({
    required this.image,
    required this.boundingBox,
    this.segmentation,
  });

  final ui.Image image;
  final ObjectBoundingBox boundingBox;
  final ObjectSegmentation? segmentation;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || image.width <= 0 || image.height <= 0) return;

    final imageRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final sourceBounds = _sourceBounds().intersect(imageRect);
    if (sourceBounds.isEmpty) return;

    final padding = math.max(sourceBounds.width, sourceBounds.height) * 0.18;
    final cropRect = Rect.fromLTRB(
      (sourceBounds.left - padding).clamp(0.0, imageRect.right),
      (sourceBounds.top - padding).clamp(0.0, imageRect.bottom),
      (sourceBounds.right + padding).clamp(0.0, imageRect.right),
      (sourceBounds.bottom + padding).clamp(0.0, imageRect.bottom),
    );
    if (cropRect.isEmpty) return;

    final availableWidth = size.width * 0.86;
    final availableHeight = size.height * 0.86;
    final scale = math.min(
      availableWidth / cropRect.width,
      availableHeight / cropRect.height,
    );
    final drawSize = Size(cropRect.width * scale, cropRect.height * scale);
    final drawRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: drawSize.width,
      height: drawSize.height,
    );

    Offset mapPoint(ObjectSegmentationPoint point) {
      return Offset(
        drawRect.left + (point.x - cropRect.left) * scale,
        drawRect.top + (point.y - cropRect.top) * scale,
      );
    }

    final path = _cutoutPath(drawRect, mapPoint);

    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withValues(alpha: 0.16)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);
    final stickerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    final imagePaint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, stickerPaint);
    canvas.save();
    canvas.clipPath(path);
    canvas.drawImageRect(image, cropRect, drawRect, imagePaint);
    canvas.restore();
    canvas.drawPath(path, outlinePaint);
  }

  Rect _sourceBounds() {
    final contour = segmentation;
    if (contour != null && contour.isValid) {
      var left = contour.points.first.x;
      var top = contour.points.first.y;
      var right = contour.points.first.x;
      var bottom = contour.points.first.y;

      for (final point in contour.points.skip(1)) {
        left = math.min(left, point.x);
        top = math.min(top, point.y);
        right = math.max(right, point.x);
        bottom = math.max(bottom, point.y);
      }

      return Rect.fromLTRB(left, top, right, bottom);
    }

    return Rect.fromLTWH(
      boundingBox.x,
      boundingBox.y,
      boundingBox.width,
      boundingBox.height,
    );
  }

  Path _cutoutPath(
    Rect drawRect,
    Offset Function(ObjectSegmentationPoint point) mapPoint,
  ) {
    final contour = segmentation;
    if (contour != null && contour.isValid) {
      final path = Path();
      path.moveTo(
        mapPoint(contour.points.first).dx,
        mapPoint(contour.points.first).dy,
      );
      for (final point in contour.points.skip(1)) {
        path.lineTo(mapPoint(point).dx, mapPoint(point).dy);
      }
      path.close();
      return path;
    }

    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(drawRect, const Radius.circular(22)),
      );
  }

  @override
  bool shouldRepaint(covariant _ObjectCutoutPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.boundingBox != boundingBox ||
        oldDelegate.segmentation != segmentation;
  }
}

class _FocusedObjectPreview extends StatefulWidget {
  const _FocusedObjectPreview({
    required this.imageFile,
    required this.boundingBox,
    this.segmentation,
  });

  final File imageFile;
  final ObjectBoundingBox boundingBox;
  final ObjectSegmentation? segmentation;

  @override
  State<_FocusedObjectPreview> createState() => _FocusedObjectPreviewState();
}

class _FocusedObjectPreviewState extends State<_FocusedObjectPreview> {
  late Future<Size> _imageSizeFuture;

  @override
  void initState() {
    super.initState();
    _imageSizeFuture = _loadImageSize(widget.imageFile);
  }

  @override
  void didUpdateWidget(covariant _FocusedObjectPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageFile.path != widget.imageFile.path) {
      _imageSizeFuture = _loadImageSize(widget.imageFile);
    }
  }

  Future<Size> _loadImageSize(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    return size;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Size>(
      future: _imageSizeFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Image.file(widget.imageFile, fit: BoxFit.cover);
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Image.file(widget.imageFile, fit: BoxFit.cover),
            ),
            Container(color: Colors.black.withValues(alpha: 0.08)),
            ClipPath(
              clipper: _DetectedObjectClipper(
                imageSize: snapshot.data!,
                boundingBox: widget.boundingBox,
                segmentation: widget.segmentation,
              ),
              child: Image.file(widget.imageFile, fit: BoxFit.cover),
            ),
          ],
        );
      },
    );
  }
}

class _DetectedObjectClipper extends CustomClipper<Path> {
  const _DetectedObjectClipper({
    required this.imageSize,
    required this.boundingBox,
    this.segmentation,
  });

  final Size imageSize;
  final ObjectBoundingBox boundingBox;
  final ObjectSegmentation? segmentation;

  @override
  Path getClip(Size size) {
    final scale = math.max(
      size.width / imageSize.width,
      size.height / imageSize.height,
    );
    final displayedWidth = imageSize.width * scale;
    final displayedHeight = imageSize.height * scale;
    final dx = (size.width - displayedWidth) / 2;
    final dy = (size.height - displayedHeight) / 2;

    final contour = segmentation;
    if (contour != null && contour.isValid) {
      final path = Path();
      final first = contour.points.first;
      path.moveTo(dx + first.x * scale, dy + first.y * scale);
      for (final point in contour.points.skip(1)) {
        path.lineTo(dx + point.x * scale, dy + point.y * scale);
      }
      path.close();
      return path;
    }

    final rect = Rect.fromLTWH(
      dx + boundingBox.x * scale,
      dy + boundingBox.y * scale,
      boundingBox.width * scale,
      boundingBox.height * scale,
    ).intersect(Offset.zero & size);

    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18)));
  }

  @override
  bool shouldReclip(covariant _DetectedObjectClipper oldClipper) {
    return oldClipper.imageSize != imageSize ||
        oldClipper.boundingBox != boundingBox ||
        oldClipper.segmentation != segmentation;
  }
}

class _DetectedObjectOverlay extends StatefulWidget {
  const _DetectedObjectOverlay({
    required this.imageFile,
    this.boundingBox,
    this.segmentation,
  });

  final File imageFile;
  final ObjectBoundingBox? boundingBox;
  final ObjectSegmentation? segmentation;

  @override
  State<_DetectedObjectOverlay> createState() => _DetectedObjectOverlayState();
}

class _DetectedObjectOverlayState extends State<_DetectedObjectOverlay> {
  late Future<Size> _imageSizeFuture;

  @override
  void initState() {
    super.initState();
    _imageSizeFuture = _loadImageSize(widget.imageFile);
  }

  @override
  void didUpdateWidget(covariant _DetectedObjectOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageFile.path != widget.imageFile.path) {
      _imageSizeFuture = _loadImageSize(widget.imageFile);
    }
  }

  Future<Size> _loadImageSize(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    return size;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Size>(
      future: _imageSizeFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return IgnorePointer(
          child: CustomPaint(
            painter: _DetectedObjectPainter(
              imageSize: snapshot.data!,
              boundingBox: widget.boundingBox,
              segmentation: widget.segmentation,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _DetectedObjectPainter extends CustomPainter {
  const _DetectedObjectPainter({
    required this.imageSize,
    this.boundingBox,
    this.segmentation,
  });

  final Size imageSize;
  final ObjectBoundingBox? boundingBox;
  final ObjectSegmentation? segmentation;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      return;
    }

    final scale = math.max(
      size.width / imageSize.width,
      size.height / imageSize.height,
    );
    final displayedWidth = imageSize.width * scale;
    final displayedHeight = imageSize.height * scale;
    final dx = (size.width - displayedWidth) / 2;
    final dy = (size.height - displayedHeight) / 2;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.32);
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withValues(alpha: 0.34);
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;

    final contour = segmentation;
    if (contour != null && contour.isValid) {
      final path = Path();
      final first = contour.points.first;
      path.moveTo(dx + first.x * scale, dy + first.y * scale);
      for (final point in contour.points.skip(1)) {
        path.lineTo(dx + point.x * scale, dy + point.y * scale);
      }
      path.close();

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: 0.04);

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, outlinePaint);
      return;
    }

    final box = boundingBox;
    if (box == null || !box.isValid) return;

    final rect = Rect.fromLTWH(
      dx + box.x * scale,
      dy + box.y * scale,
      box.width * scale,
      box.height * scale,
    ).intersect(Offset.zero & size);

    if (rect.isEmpty) return;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, shadowPaint);
    canvas.drawRRect(rrect, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _DetectedObjectPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.boundingBox != boundingBox ||
        oldDelegate.segmentation != segmentation;
  }
}

/// Small icon button (for copy, speak, bookmark in bottom card)
class _SmallIconBtn extends StatelessWidget {
  const _SmallIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _kAccentLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _kAccent, size: 18),
      ),
    );
  }
}
