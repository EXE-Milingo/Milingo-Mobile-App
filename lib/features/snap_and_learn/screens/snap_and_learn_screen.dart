import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:milingo/shared/utils/tts_locale.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens (warm orange accent like mockup)
// ─────────────────────────────────────────────────────────────────────────────

const _kAccent = Color(0xFFF25F36);
const _kAccentLight = Color(0xFFFFF0EB);
const _kHaloBubbleWidth = 92.0;
const _kHaloBubbleHeight = 70.0;

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
  final ScrollController _resultScrollController = ScrollController();
  bool _showResultExample = false;

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
    final spokenText = text.trim();
    if (spokenText.isEmpty) return;
    await _tts.setLanguage(ttsLocaleForLanguageCode(langCode));
    await _tts.stop();
    await _tts.speak(spokenText);
  }

  Future<void> _speakResultTerm(MilingoResult result, String langCode) {
    return _speak(_speechTextForResult(result, langCode), langCode);
  }

  String _speechTextForResult(MilingoResult result, String langCode) {
    return targetSpeechTextForLanguage(
      langCode: langCode,
      englishText: result.keyword,
      translatedText: result.translation,
    );
  }

  String _speechTextForRelatedWord(RelatedWord word, String langCode) {
    return targetSpeechTextForLanguage(
      langCode: langCode,
      englishText: word.english,
      translatedText: word.translation,
    );
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
      final ctrl = ref.read(snapControllerProvider.notifier);
      final snap = ref.read(snapControllerProvider);
      if (!await ctrl.ensureCanScan()) return;

      final xFile = await _cameraController!.takePicture();
      final file = File(xFile.path);
      await ctrl.analyzeFile(
        file,
        snap.selectedLanguage,
        skipQuotaCheck: true,
      );
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
    _resultScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(snapControllerProvider);
    final ctrl = ref.read(snapControllerProvider.notifier);

    // Listen for state transitions
    ref.listen<SnapState>(snapControllerProvider, (prev, next) {
      if (!(prev?.paywallRequired ?? false) && next.paywallRequired) {
        _scanCtrl.stop();
        ctrl.clearPaywallRequired();
        if (mounted) {
          context.push(AppConstants.premiumRoute);
        }
      }
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
      if (prev?.result != null && next.result == null) {
        setState(() {
          _showResultExample = false;
        });
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
    final objectHeight = compact ? 260.0 : 320.0;
    final langCode = snap.selectedLanguage;

    return SafeArea(
      child: Container(
        color: const Color(0xFFFBF7F2),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  _SoftCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      setState(() {
                        _showResultExample = false;
                      });
                      ctrl.reset();
                    },
                  ),
                  Expanded(
                    child: Column(
                      children: const [
                        Text(
                          'BÓC TÁCH VẬT THỂ',
                          style: TextStyle(
                            color: Color(0xFF1D1814),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 5),
                        _HoanThanhChip(done: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _resultScrollController,
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    SizedBox(
                      height: objectHeight + 100,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ..._buildObjectHaloBubbles(snap, result, objectHeight),
                          SizedBox(
                            height: objectHeight,
                            width: double.infinity,
                            child: _buildResultObjectPreview(
                              snap: snap,
                              result: result,
                              objectBytes: objectBytes,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildWordCard(result),
                    const SizedBox(height: 20),
                    _buildActionsRow(result, langCode),
                    if (_showResultExample) ...[
                      const SizedBox(height: 32),
                      _buildAiSuggestedSentencesSection(result, langCode),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCard(MilingoResult result) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F221914),
            blurRadius: 44,
            offset: Offset(0, 20),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdaptiveResultText(
                  text: result.keyword,
                  maxLines: 2,
                  minFontSize: 16,
                  style: const TextStyle(
                    color: Color(0xFF1D1814),
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                if (result.pronunciation.isNotEmpty) ...[
                  _AdaptiveResultText(
                    text: '/${result.pronunciation}/',
                    maxLines: 2,
                    minFontSize: 12,
                    style: const TextStyle(
                      color: Color(0xFF77716B),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEADF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    result.partOfSpeech.trim().isEmpty
                        ? 'Noun'
                        : result.partOfSpeech,
                    style: const TextStyle(
                      color: Color(0xFFFF6A00),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NGHĨA',
                  style: TextStyle(
                    color: Color(0xFFFF8A1F),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                _AdaptiveResultText(
                  text: result.translation,
                  textAlign: TextAlign.left,
                  maxLines: 3,
                  minFontSize: 16,
                  style: const TextStyle(
                    color: Color(0xFF1D1814),
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow(MilingoResult result, String langCode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButtonItem(
            label: 'Lưu lại',
            iconPath: 'assets/svg/return-result-new/save-icon.svg',
            isGradient: false,
            onTap: () => _saveResultToFlashcard(result, langCode),
          ),
          _buildActionButtonItem(
            label: 'Phát âm',
            iconPath: 'assets/svg/return-result-new/pronunciation.svg',
            isGradient: true,
            onTap: () => _speakResultTerm(result, langCode),
          ),
          _buildActionButtonItem(
            label: 'Ví dụ',
            iconPath: 'assets/svg/return-result-new/example-sentence-icon.svg',
            isGradient: false,
            onTap: () {
              setState(() {
                _showResultExample = true;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_resultScrollController.hasClients) {
                  _resultScrollController.animateTo(
                    _resultScrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonItem({
    required String label,
    required String iconPath,
    required bool isGradient,
    required VoidCallback onTap,
  }) {
    final labelColor = isGradient ? const Color(0xFFFF6A00) : const Color(0xFF9A8E84);
    final isLargeSvg = iconPath.contains('save-icon') || iconPath.contains('example-sentence-icon');
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 56,
            height: 56,
            child: isLargeSvg
                ? OverflowBox(
                    minWidth: 96,
                    maxWidth: 96,
                    minHeight: 96,
                    maxHeight: 96,
                    child: SvgPicture.asset(iconPath),
                  )
                : SvgPicture.asset(iconPath),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildAiSuggestedSentencesSection(MilingoResult result, String langCode) {
    final example = _examplePairForResult(result);
    if (example.original.isEmpty && example.translation.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Gợi ý từ AI',
              style: TextStyle(
                color: Color(0xFFFF3F00),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0x66FFFFFF),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0x66FFFFFF), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A1D1814),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        example.original,
                        style: const TextStyle(
                          color: Color(0xFF1D1814),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.24,
                        ),
                      ),
                      if (example.translation.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          example.translation,
                          style: const TextStyle(
                            color: Color(0xCC59413A),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            height: 1.28,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _speak(example.original, langCode),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0x0D1D1814),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.volume_up_rounded,
                      color: Color(0xFF1D1814),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildObjectHaloBubbles(
    SnapState snap,
    MilingoResult result,
    double objectHeight,
  ) {
    final haloItems = <({String label, String translation})>[
      for (final word in result.relatedWords.take(4))
        (label: word.english, translation: word.translation),
    ];

    if (haloItems.isEmpty) {
      for (final item in snap.allVocabItems) {
        if (item.keyword == result.keyword) continue;
        haloItems.add((label: item.keyword, translation: item.translation));
        if (haloItems.length == 4) break;
      }
    }

    if (haloItems.isEmpty) return const [];

    return [
      Positioned.fill(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!constraints.hasBoundedWidth ||
                !constraints.hasBoundedHeight ||
                constraints.maxWidth <= 0 ||
                constraints.maxHeight <= 0) {
              return const SizedBox.shrink();
            }

            final areaSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final previewHeight = math.min(objectHeight, areaSize.height);
            final previewTop = (areaSize.height - previewHeight) / 2;
            final objectRect = _estimatedResultObjectRect(
              snap: snap,
              result: result,
              previewSize: Size(areaSize.width, previewHeight),
            )
                .translate(0, previewTop)
                .inflate(12)
                .intersect(Offset.zero & areaSize);
            final offsets = _haloOffsetsForObject(
              size: areaSize,
              objectRect: objectRect,
              count: haloItems.length,
            );

            return Stack(
              children: [
                for (var i = 0; i < haloItems.length && i < offsets.length; i++)
                  Positioned(
                    left: offsets[i].dx,
                    top: offsets[i].dy,
                    child: _HaloWordBubble(
                      label: haloItems[i].label,
                      translation: haloItems[i].translation,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ];
  }

  Rect _estimatedResultObjectRect({
    required SnapState snap,
    required MilingoResult result,
    required Size previewSize,
  }) {
    Rect fallback() {
      return Rect.fromCenter(
        center: previewSize.center(Offset.zero),
        width: previewSize.width * 0.64,
        height: previewSize.height * 0.58,
      );
    }

    final boundingBox =
        result.boundingBox ?? snap.currentDetectedObject?.boundingBox;
    final segmentation =
        result.segmentation ?? snap.currentDetectedObject?.segmentation;
    if (boundingBox == null || !boundingBox.isValid) return fallback();

    final sourceBounds = _objectSourceBounds(
      boundingBox: boundingBox,
      segmentation: segmentation,
    );
    if (sourceBounds.isEmpty) return fallback();

    final padding = math.max(sourceBounds.width, sourceBounds.height) * 0.18;
    final cropWidth = math.max(1.0, sourceBounds.width + padding * 2);
    final cropHeight = math.max(1.0, sourceBounds.height + padding * 2);
    final scale = math.min(
      previewSize.width * 0.86 / cropWidth,
      previewSize.height * 0.86 / cropHeight,
    );

    return Rect.fromCenter(
      center: previewSize.center(Offset.zero),
      width: cropWidth * scale,
      height: cropHeight * scale,
    ).inflate(24);
  }

  List<Offset> _haloOffsetsForObject({
    required Size size,
    required Rect objectRect,
    required int count,
  }) {
    const edge = 18.0;
    const gap = 12.0;
    final maxLeft = math.max(edge, size.width - _kHaloBubbleWidth - edge);
    final maxTop = math.max(edge, size.height - _kHaloBubbleHeight - edge);
    final chosen = <Rect>[];

    bool addCandidate(double left, double top, {bool avoidObject = true}) {
      final x = left.clamp(edge, maxLeft).toDouble();
      final y = top.clamp(edge, maxTop).toDouble();
      final rect = Rect.fromLTWH(
        x,
        y,
        _kHaloBubbleWidth,
        _kHaloBubbleHeight,
      );
      if (avoidObject && rect.overlaps(objectRect)) return false;
      if (chosen.any((used) => used.inflate(6).overlaps(rect))) return false;
      chosen.add(rect);
      return chosen.length >= count;
    }

    final left = edge;
    final right = size.width - _kHaloBubbleWidth - edge;
    final centerX = (size.width - _kHaloBubbleWidth) / 2;
    final above = objectRect.top - _kHaloBubbleHeight - gap;
    final middle = objectRect.center.dy - _kHaloBubbleHeight / 2;
    final below = objectRect.bottom + gap;

    for (final candidate in <Offset>[
      Offset(left, above),
      Offset(right, above),
      Offset(left, middle),
      Offset(right, middle),
      Offset(left, below),
      Offset(right, below),
      Offset(centerX, above),
      Offset(centerX, below),
    ]) {
      if (addCandidate(candidate.dx, candidate.dy)) break;
    }

    if (chosen.length < count) {
      for (final candidate in <Offset>[
        Offset(left, edge),
        Offset(right, edge),
        Offset(left, maxTop),
        Offset(right, maxTop),
        Offset(centerX, edge),
        Offset(centerX, maxTop),
      ]) {
        if (addCandidate(
          candidate.dx,
          candidate.dy,
          avoidObject: false,
        )) {
          break;
        }
      }
    }

    return [
      for (final rect in chosen.take(count)) rect.topLeft,
    ];
  }

  Future<void> _saveResultToFlashcard(
    MilingoResult result,
    String langCode,
  ) async {
    final snap = ref.read(snapControllerProvider);
    final objectImageBase64 =
        await _buildSoftObjectImageBase64(snap: snap, result: result) ??
            result.objectImageBase64;
    if (!mounted) return;

    _showSaveToFlashcard(
      context,
      FlashcardEntry(
        id: '${result.keyword}_$langCode',
        english: result.keyword,
        translation: result.translation,
        pronunciation: result.pronunciation,
        partOfSpeech: result.partOfSpeech,
        langCode: langCode,
        imageUrl: result.objectImageUrl,
        objectImageBase64: objectImageBase64,
      ),
    );
  }

  Future<String?> _buildSoftObjectImageBase64({
    required SnapState snap,
    required MilingoResult result,
  }) async {
    final capturedImage = snap.capturedImage;
    final boundingBox =
        result.boundingBox ?? snap.currentDetectedObject?.boundingBox;
    final segmentation =
        result.segmentation ?? snap.currentDetectedObject?.segmentation;

    if (capturedImage == null || boundingBox == null || !boundingBox.isValid) {
      return null;
    }

    try {
      return await _renderSoftObjectStickerBase64(
        imageFile: capturedImage,
        boundingBox: boundingBox,
        segmentation: segmentation,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _renderSoftObjectStickerBase64({
    required File imageFile,
    required ObjectBoundingBox boundingBox,
    required ObjectSegmentation? segmentation,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    try {
      const outputSide = 768.0;
      final imageRect = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final sourceBounds = _objectSourceBounds(
        boundingBox: boundingBox,
        segmentation: segmentation,
      ).intersect(imageRect);
      if (sourceBounds.isEmpty) return null;

      final padding = math.max(sourceBounds.width, sourceBounds.height) * 0.22;
      final cropRect = Rect.fromLTRB(
        (sourceBounds.left - padding).clamp(0.0, imageRect.right),
        (sourceBounds.top - padding).clamp(0.0, imageRect.bottom),
        (sourceBounds.right + padding).clamp(0.0, imageRect.right),
        (sourceBounds.bottom + padding).clamp(0.0, imageRect.bottom),
      );
      if (cropRect.isEmpty) return null;

      const available = outputSide * 0.72;
      final scale =
          math.min(available / cropRect.width, available / cropRect.height);
      final drawSize = Size(cropRect.width * scale, cropRect.height * scale);
      final drawRect = Rect.fromCenter(
        center: const Offset(outputSide / 2, outputSide / 2),
        width: drawSize.width,
        height: drawSize.height,
      );

      Offset mapPoint(ObjectSegmentationPoint point) {
        return Offset(
          drawRect.left + (point.x - cropRect.left) * scale,
          drawRect.top + (point.y - cropRect.top) * scale,
        );
      }

      final path = _objectStickerPath(drawRect, segmentation, mapPoint);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        const Rect.fromLTWH(0, 0, outputSide, outputSide),
      );

      canvas.drawRect(
        const Rect.fromLTWH(0, 0, outputSide, outputSide),
        Paint()..color = const Color(0xFFFFF9F5),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(28, 28, outputSide - 56, outputSide - 56),
          const Radius.circular(64),
        ),
        Paint()..color = const Color(0xFFFFF1EA),
      );

      final shadowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 34
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = Colors.black.withValues(alpha: 0.10)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 16);
      final softBorderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 44
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.86)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 13);
      final stickerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.98);
      final edgePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = Colors.white;
      final imagePaint = Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true;

      canvas.save();
      canvas.translate(0, 14);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
      canvas.drawPath(path, softBorderPaint);
      canvas.drawPath(path, stickerPaint);
      canvas.save();
      canvas.clipPath(path, doAntiAlias: true);
      canvas.drawImageRect(image, cropRect, drawRect, imagePaint);
      canvas.restore();
      canvas.drawPath(path, edgePaint);

      final picture = recorder.endRecording();
      final outputImage = await picture.toImage(
        outputSide.toInt(),
        outputSide.toInt(),
      );
      final byteData = await outputImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      picture.dispose();
      outputImage.dispose();
      if (byteData == null) return null;
      return base64Encode(byteData.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  }

  Rect _objectSourceBounds({
    required ObjectBoundingBox boundingBox,
    required ObjectSegmentation? segmentation,
  }) {
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

  Path _objectStickerPath(
    Rect drawRect,
    ObjectSegmentation? segmentation,
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
        RRect.fromRectAndRadius(drawRect, const Radius.circular(42)),
      );
  }

  ExampleSentencePair _examplePairForResult(
    MilingoResult result,
  ) {
    return exampleSentencePairFor(
      sentence: result.sentence,
      sentenceTranslation: result.sentenceTranslation,
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
    final example = _examplePairForResult(result);
    final langCode = ref.read(snapControllerProvider).selectedLanguage;
    final speakText = example.original;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFFFEFDA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(
            18,
            22,
            18,
            MediaQuery.of(context).padding.bottom + 18,
          ),
          itemCount: 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          example.original,
                          style: const TextStyle(
                            color: Color(0xFF30302F),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            height: 1.24,
                          ),
                        ),
                        if (example.translation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            example.translation,
                            style: const TextStyle(
                              color: Color(0xFF746A62),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.28,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _MiniActionButton(
                    icon: Icons.volume_up_rounded,
                    onTap: () => _speak(speakText, langCode),
                  ),
                ],
              ),
            );
          },
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
          _buildTopBar(hasResult || hasDetection, ctrl, snap),

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

  Widget _buildTopBar(bool hasResult, SnapController ctrl, SnapState snap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              final hasImage = snap.capturedImage != null;
              ctrl.reset();
              if (!hasImage) {
                context.go(AppConstants.homeRoute);
              }
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
            onSpeak: () =>
                _speak(_speechTextForRelatedWord(word, langCode), langCode),
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
                          onTap: () => _speakResultTerm(r, langCode),
                        ),
                        const SizedBox(width: 8),
                        _SmallIconBtn(
                          icon: Icons.bookmark_add_rounded,
                          onTap: () {
                            _saveResultToFlashcard(r, langCode);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Keyword (English)
                    _AdaptiveResultText(
                      text: r.keyword,
                      maxLines: 3,
                      minFontSize: 16,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF222222),
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Pronunciation
                    _AdaptiveResultText(
                      text: '/${r.pronunciation}/',
                      maxLines: 2,
                      minFontSize: 10,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
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

              // Right column: translation only.
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => _speakResultTerm(r, langCode),
                      child: _AdaptiveResultText(
                        text: r.translation,
                        textAlign: TextAlign.right,
                        maxLines: 3,
                        minFontSize: 17,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF333333),
                          height: 1.2,
                        ),
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

class _AdaptiveResultText extends StatelessWidget {
  const _AdaptiveResultText({
    required this.text,
    required this.style,
    this.textAlign = TextAlign.start,
    this.maxLines = 2,
    this.minFontSize = 12,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final int maxLines;
  final double minFontSize;

  @override
  Widget build(BuildContext context) {
    final displayText = _insertSoftBreaks(text);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
        final baseFontSize = style.fontSize ??
            DefaultTextStyle.of(context).style.fontSize ??
            14.0;
        final direction = Directionality.of(context);

        bool fits(double fontSize, int? lineLimit) {
          final painter = TextPainter(
            text: TextSpan(
              text: displayText,
              style: style.copyWith(fontSize: fontSize),
            ),
            textAlign: textAlign,
            textDirection: direction,
            maxLines: lineLimit,
          )..layout(maxWidth: maxWidth);
          return !painter.didExceedMaxLines && painter.width <= maxWidth + 0.1;
        }

        var fontSize = baseFontSize;
        int? lineLimit = maxLines;

        if (!fits(fontSize, lineLimit)) {
          var low = math.min(minFontSize, baseFontSize);
          var high = baseFontSize;

          for (var i = 0; i < 8; i++) {
            final mid = (low + high) / 2;
            if (fits(mid, lineLimit)) {
              low = mid;
            } else {
              high = mid;
            }
          }

          fontSize = low;
          if (!fits(fontSize, lineLimit)) {
            lineLimit = null;
          }
        }

        return Text(
          displayText,
          textAlign: textAlign,
          softWrap: true,
          maxLines: lineLimit,
          overflow: TextOverflow.visible,
          style: style.copyWith(fontSize: fontSize),
        );
      },
    );
  }

  static String _insertSoftBreaks(String value) {
    final softBreak = String.fromCharCode(0x200B);

    return value.splitMapJoin(
      RegExp(r'\S+'),
      onMatch: (match) {
        final token = match.group(0)!;
        if (token.runes.length < 14) return token;

        final buffer = StringBuffer();
        var count = 0;
        for (final rune in token.runes) {
          if (count > 0 && count % 8 == 0) {
            buffer.write(softBreak);
          }
          buffer.writeCharCode(rune);
          count++;
        }
        return buffer.toString();
      },
      onNonMatch: (part) => part,
    );
  }
}

class _SoftCircleButton extends StatelessWidget {
  const _SoftCircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.76),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF5E554C), size: 21),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _OrangePillButton extends StatelessWidget {
  const _OrangePillButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 32, maxWidth: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: _kAccent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExampleAssetButton extends StatelessWidget {
  const _ExampleAssetButton({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _kAccent.withValues(alpha: 0.42)),
          ),
          child: Icon(icon, color: _kAccent, size: 17),
        ),
      ),
    );
  }
}

class _HaloWordBubble extends StatelessWidget {
  const _HaloWordBubble({
    required this.label,
    required this.translation,
  });

  final String label;
  final String translation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kHaloBubbleWidth,
      height: _kHaloBubbleHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _kAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.volume_up_rounded, color: _kAccent, size: 10),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            translation,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF605851),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
        ],
      ),
    );
  }
}

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
