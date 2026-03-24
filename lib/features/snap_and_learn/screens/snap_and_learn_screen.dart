import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:milingo/features/snap_and_learn/controllers/snap_controller.dart';
import 'package:milingo/core/network/gemini_api_service.dart';

// ─────────────────────────────────────────────────────────
// Design Tokens (warm orange accent like mockup)
// ─────────────────────────────────────────────────────────

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
  'en': 'en-US', 'ja': 'ja-JP', 'ko': 'ko-KR', 'zh': 'zh-CN',
  'es': 'es-ES', 'fr': 'fr-FR', 'de': 'de-DE', 'th': 'th-TH',
};

// ─────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────

class SnapAndLearnScreen extends ConsumerStatefulWidget {
  const SnapAndLearnScreen({super.key});

  @override
  ConsumerState<SnapAndLearnScreen> createState() => _SnapAndLearnScreenState();
}

class _SnapAndLearnScreenState extends ConsumerState<SnapAndLearnScreen>
    with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();

  // Bubble pop-in animation
  late final AnimationController _bubbleCtrl;
  // Scanning dots animation
  late final AnimationController _scanCtrl;
  // Marker pulse animation
  late final AnimationController _markerPulseCtrl;

  @override
  void initState() {
    super.initState();
    _initTts();

    _bubbleCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    );
    _scanCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500),
    );
    _markerPulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Auto-open camera immediately when screen loads so the user
    // never sees the empty placeholder step.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final snap = ref.read(snapControllerProvider);
      // Only auto-launch if we don't already have an image/result
      if (snap.capturedImage == null && snap.result == null && !snap.isLoading) {
        ref.read(snapControllerProvider.notifier)
            .captureFromCamera(snap.selectedLanguage);
      }
    });
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
  }

  Future<void> _speak(String text, String langCode) async {
    await _tts.setLanguage(_kTtsLocales[langCode] ?? 'en-US');
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _tts.stop();
    _bubbleCtrl.dispose();
    _scanCtrl.dispose();
    _markerPulseCtrl.dispose();
    super.dispose();
  }

  _Lang _lang(String code) =>
      _kLanguages.firstWhere((l) => l.code == code, orElse: () => _kLanguages.first);

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
      // When result arrives → stop scan, trigger marker pulse
      if (prev?.result == null && next.result != null) {
        _scanCtrl.stop();
      }
      // When vocabulary view opens → trigger bubble animation
      if (!(prev?.showVocabulary ?? false) && next.showVocabulary) {
        _bubbleCtrl.forward(from: 0);
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: _buildBody(snap, ctrl),
      ),
    );
  }

  Widget _buildBody(SnapState snap, SnapController ctrl) {
    // Error state
    if (snap.error != null) {
      return _buildErrorView(snap.error!, ctrl);
    }

    // Determine which phase we're in
    final hasImage = snap.capturedImage != null;
    final isAnalyzing = snap.isLoading;
    final hasResult = snap.result != null;
    final showVocab = snap.showVocabulary;

    return Column(
      children: [
        // ── Top Bar (changes label based on phase) ──
        SafeArea(
          bottom: false,
          child: _buildTopBar(hasResult, ctrl),
        ),

        // ── "Hoàn thành" chip (shown after capture) ──
        if (hasImage)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: _HoanThanhChip(done: hasResult && !isAnalyzing),
          ),

        // ── Main Content Area ──
        Expanded(
          child: hasImage
              ? _buildImageView(snap, ctrl)
              : _buildCameraPlaceholder(),
        ),

        // ── "Chọn ngôn ngữ khác" button (vocab phase only) ──
        if (showVocab)
          GestureDetector(
            onTap: () => _showLanguagePicker(ctrl, snap.selectedLanguage),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kAccent, Color(0xFFf5a97a)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text('Chọn ngôn ngữ khác',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ),

        // ── Bottom Vocab Card (vocab phase only) ──
        if (showVocab && hasResult)
          _buildBottomVocabCard(snap.result!, snap.selectedLanguage),

        // ── Bottom Capture Bar (always visible) ──
        if (!showVocab)
          _BottomCaptureBar(
            onGallery: () => ctrl.pickFromGallery(snap.selectedLanguage),
            onCapture: () => ctrl.captureFromCamera(snap.selectedLanguage),
          ),

        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════

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
                color: Colors.black.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
            ),
          ),
          const Spacer(),

          // Title
          if (hasResult || ref.read(snapControllerProvider).isLoading)
            const Text('BÓC TÁCH VẬT THỂ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                    color: Colors.black87, letterSpacing: 1)),

          const Spacer(),

          // Language / Add button
          GestureDetector(
            onTap: () => _showLanguagePicker(ctrl, ref.read(snapControllerProvider).selectedLanguage),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 20, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Hình 1: CAMERA PLACEHOLDER
  // ═══════════════════════════════════════════════════════

  Widget _buildCameraPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chụp vật thể',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Hình 2-4: IMAGE VIEW (analyzing / detected / vocab)
  // ═══════════════════════════════════════════════════════

  Widget _buildImageView(SnapState snap, SnapController ctrl) {
    final isAnalyzing = snap.isLoading;
    final hasResult = snap.result != null;
    final showVocab = snap.showVocabulary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image ──
            if (snap.capturedImage != null)
              Image.file(
                File(snap.capturedImage!.path),
                fit: BoxFit.cover,
              ),

            // ── Semi-transparent overlay when analyzing ──
            if (isAnalyzing)
              Container(color: Colors.white.withOpacity(0.3)),

            // ── Hình 2: Scanning dots animation ──
            if (isAnalyzing)
              ..._buildScanningDots(),

            // ── Hình 3: Object markers (after analysis, before vocab) ──
            if (hasResult && !showVocab)
              ..._buildObjectMarkers(snap.result!, ctrl),

            // ── Hình 3: Glow effect on main object ──
            if (hasResult && !showVocab)
              _buildGlowOverlay(),

            // ── Hình 4: Vocabulary bubbles (when user tapped marker) ──
            if (showVocab && hasResult)
              ..._buildVocabBubbles(snap.result!, snap.selectedLanguage),
          ],
        ),
      ),
    );
  }

  // ─── Hình 2: Scanning orange dots ──────────────────────

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
          final opacity = (math.sin(phase * math.pi * 2) * 0.5 + 0.5).clamp(0.0, 1.0);
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

  // ─── Hình 3: Object markers (small dots) ───────────────

  List<Widget> _buildObjectMarkers(MilingoResult result, SnapController ctrl) {
    // Place markers at interesting positions
    const markerPositions = [
      Alignment(0.0, 0.2),    // center-ish (main object)
      Alignment(0.5, 0.7),     // bottom-right area
    ];

    final markers = <Widget>[];
    for (var i = 0; i < markerPositions.length && i < result.relatedWords.length + 1; i++) {
      markers.add(
        AnimatedBuilder(
          animation: _markerPulseCtrl,
          builder: (_, __) {
            final pulse = 1.0 + _markerPulseCtrl.value * 0.15;
            return Align(
              alignment: markerPositions[i],
              child: GestureDetector(
                onTap: () => ctrl.showVocab(),
                child: Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: _kAccent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: _kAccent.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return markers;
  }

  // ─── Hình 3: Glow overlay on detected object ──────────

  Widget _buildGlowOverlay() {
    return Align(
      alignment: const Alignment(0.0, 0.15),
      child: Container(
        width: 180,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.25),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hình 4: Vocabulary Bubbles ────────────────────────

  List<Widget> _buildVocabBubbles(MilingoResult result, String langCode) {
    if (result.relatedWords.isEmpty) return [];

    const positions = [
      Alignment(0.0, -0.88),    // top-center
      Alignment(-0.9, -0.6),   // top-left
      Alignment(0.9, -0.65),    // top-right
      Alignment(0.85, -0.1),   // middle-right
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
          child: _VocabBubble(
            english: word.english,
            translation: word.translation,
            pronunciation: word.pronunciation,
            onSpeak: () => _speak(word.translation, langCode),
          ),
        ),
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════
  // BOTTOM VOCAB CARD (Hình 4 bottom)
  // ═══════════════════════════════════════════════════════

  Widget _buildBottomVocabCard(MilingoResult r, String langCode) {
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
      child: Row(
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
                        Clipboard.setData(ClipboardData(text: '${r.keyword} - ${r.translation}'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Đã copy! 📋'),
                            backgroundColor: _kAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  ],
                ),
                const SizedBox(height: 10),

                // Keyword (English)
                Text(r.keyword,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF222222))),
                const SizedBox(height: 2),

                // Pronunciation
                Text('/${r.pronunciation}/',
                    style: TextStyle(fontSize: 15, color: Colors.grey[500], fontStyle: FontStyle.italic)),
                const SizedBox(height: 6),

                // Part of speech
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(r.partOfSpeech,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600])),
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
    );
  }

  // ═══════════════════════════════════════════════════════
  // ERROR VIEW
  // ═══════════════════════════════════════════════════════

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
                child: const Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFFFF6B6B)),
              ),
              const SizedBox(height: 24),
              const Text('Có lỗi xảy ra',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(error,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5)),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: ctrl.reset,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: _kAccent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Thử lại', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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

  // ─── Language Picker ────────────────────────────────────

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
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Chọn ngôn ngữ học',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('AI sẽ dịch vật thể sang ngôn ngữ bạn chọn',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
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
                  onTap: () { ctrl.setLanguage(lang.code); Navigator.pop(context); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: selected ? const LinearGradient(colors: [_kAccent, Color(0xFFf5a97a)]) : null,
                      color: selected ? null : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? Colors.transparent : Colors.white.withOpacity(0.1)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Text(lang.flag, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(lang.name,
                            style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: Colors.white),
                            overflow: TextOverflow.ellipsis)),
                        if (selected) const Icon(Icons.check_circle, color: Colors.white, size: 18),
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

// ═════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═════════════════════════════════════════════════════════

/// "Hoàn thành" status chip
class _HoanThanhChip extends StatelessWidget {
  const _HoanThanhChip({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: done ? _kAccentLight : Colors.grey[200],
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

/// Bottom capture bar (matches all mockups: gallery + capture + effect)
class _BottomCaptureBar extends StatelessWidget {
  const _BottomCaptureBar({required this.onGallery, required this.onCapture});
  final VoidCallback onGallery;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(48, 12, 48, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery
          GestureDetector(
            onTap: onGallery,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.photo_library_rounded, color: Colors.grey[600], size: 22),
            ),
          ),

          // Capture (orange ring)
          GestureDetector(
            onTap: onCapture,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _kAccent, width: 3.5),
              ),
              child: Center(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[100],
                  ),
                ),
              ),
            ),
          ),

          // Effect
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.auto_fix_high_rounded, color: Colors.grey[600], size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vocabulary bubble (floating on image in Hình 4)
class _VocabBubble extends StatelessWidget {
  const _VocabBubble({
    required this.english,
    required this.translation,
    required this.pronunciation,
    required this.onSpeak,
  });
  final String english, translation, pronunciation;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSpeak,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(english,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _kAccent, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(translation,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF222222))),
                const SizedBox(width: 4),
                Icon(Icons.volume_up_rounded, color: _kAccent, size: 13),
              ],
            ),
            Text(pronunciation,
                style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

/// Small icon button (for copy, speak in bottom card)
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
