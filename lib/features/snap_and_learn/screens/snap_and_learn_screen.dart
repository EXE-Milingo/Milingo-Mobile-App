import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:milingo/features/snap_and_learn/providers/snap_provider.dart';
import 'package:milingo/features/snap_and_learn/widgets/vocab_bubble.dart';
import 'package:milingo/features/snap_and_learn/widgets/bottom_capture_bar.dart';
import 'package:milingo/features/snap_and_learn/widgets/save_flashcard_sheet.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';

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

  /// Take a picture from the embedded camera preview and analyze it.
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
      // When result arrives → stop scan and immediately show vocabulary
      if (prev?.result == null && next.result != null) {
        _scanCtrl.stop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(snapControllerProvider.notifier).showVocab();
        });
      }
      // When vocabulary view opens → trigger bubble animation
      if (!(prev?.showVocabulary ?? false) && next.showVocabulary) {
        _bubbleCtrl.forward(from: 0);
      }
    });

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
                child: Image.file(
                  File(snap.capturedImage!.path),
                  fit: BoxFit.cover,
                ),
              ),
            if (snap.result?.boundingBox != null && snap.capturedImage != null)
              Positioned.fill(
                child: _DetectedObjectOverlay(
                  imageFile: File(snap.capturedImage!.path),
                  boundingBox: snap.result!.boundingBox!,
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
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CAMERA LAYER
  // ═══════════════════════════════════════════════════════════════

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
    final showVocab = snap.showVocabulary;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ── Top Bar ──
          _buildTopBar(hasResult, ctrl),

          // ── "Hoàn thành" chip (shown after capture) ──
          if (hasImage)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: _HoanThanhChip(done: hasResult && !isAnalyzing),
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

          // ── Bottom Capture Bar (always visible when not in vocab mode) ──
          if (!showVocab)
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
              final snap = ref.read(snapControllerProvider);
              if (snap.showVocabulary) {
                ctrl.hideVocab();
              } else if (snap.result != null || snap.isLoading) {
                ctrl.reset();
              } else {
                Navigator.of(context).pop();
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

class _DetectedObjectOverlay extends StatefulWidget {
  const _DetectedObjectOverlay({
    required this.imageFile,
    required this.boundingBox,
  });

  final File imageFile;
  final ObjectBoundingBox boundingBox;

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
    required this.boundingBox,
  });

  final Size imageSize;
  final ObjectBoundingBox boundingBox;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width <= 0 || imageSize.height <= 0 || !boundingBox.isValid) {
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

    final rect = Rect.fromLTWH(
      dx + boundingBox.x * scale,
      dy + boundingBox.y * scale,
      boundingBox.width * scale,
      boundingBox.height * scale,
    ).intersect(Offset.zero & size);

    if (rect.isEmpty) return;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = Colors.black.withValues(alpha: 0.45);
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = _kAccent;
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = _kAccent.withValues(alpha: 0.18);

    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, shadowPaint);
    canvas.drawRRect(rrect, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _DetectedObjectPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.boundingBox != boundingBox;
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
