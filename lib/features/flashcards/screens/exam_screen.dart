import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:milingo/core/theme/app_theme.dart';

// ── Question model ────────────────────────────────────────

class _Question {
  const _Question({
    required this.wordVi,
    required this.emoji,
    required this.correctAnswer,
    required this.options,
    required this.langCode,
  });
  final String wordVi;
  final String emoji;
  final String correctAnswer;
  final List<String> options;
  final String langCode;
}

// ── Question bank (keyed by target-language code) ────────
// Each entry: (Vietnamese word, emoji, correct answer, wrong answers x3)

const _kRawQuestions = <(String, String, Map<String, String>, Map<String, List<String>>)>[
  ('Cà phê', '☕', {'en': 'Coffee', 'ja': 'コーヒー', 'ko': '커피', 'zh': '咖啡', 'fr': 'Café', 'es': 'Café', 'de': 'Kaffee'},
      {'en': ['Tea', 'Water', 'Milk'], 'ja': ['お茶', '水', '牛乳'], 'ko': ['차', '물', '우유'], 'zh': ['茶', '水', '牛奶'], 'fr': ['Thé', 'Eau', 'Lait'], 'es': ['Té', 'Agua', 'Leche'], 'de': ['Tee', 'Wasser', 'Milch']}),
  ('Sách', '📖', {'en': 'Book', 'ja': '本', 'ko': '책', 'zh': '书', 'fr': 'Livre', 'es': 'Libro', 'de': 'Buch'},
      {'en': ['Pen', 'Table', 'Chair'], 'ja': ['ペン', 'テーブル', '椅子'], 'ko': ['펜', '테이블', '의자'], 'zh': ['笔', '桌子', '椅子'], 'fr': ['Stylo', 'Table', 'Chaise'], 'es': ['Bolígrafo', 'Mesa', 'Silla'], 'de': ['Stift', 'Tisch', 'Stuhl']}),
  ('Mèo', '🐱', {'en': 'Cat', 'ja': '猫', 'ko': '고양이', 'zh': '猫', 'fr': 'Chat', 'es': 'Gato', 'de': 'Katze'},
      {'en': ['Dog', 'Bird', 'Fish'], 'ja': ['犬', '鳥', '魚'], 'ko': ['개', '새', '물고기'], 'zh': ['狗', '鸟', '鱼'], 'fr': ['Chien', 'Oiseau', 'Poisson'], 'es': ['Perro', 'Pájaro', 'Pez'], 'de': ['Hund', 'Vogel', 'Fisch']}),
  ('Nhà', '🏠', {'en': 'House', 'ja': '家', 'ko': '집', 'zh': '房子', 'fr': 'Maison', 'es': 'Casa', 'de': 'Haus'},
      {'en': ['School', 'Park', 'Shop'], 'ja': ['学校', '公園', '店'], 'ko': ['학교', '공원', '가게'], 'zh': ['学校', '公园', '商店'], 'fr': ['École', 'Parc', 'Magasin'], 'es': ['Escuela', 'Parque', 'Tienda'], 'de': ['Schule', 'Park', 'Laden']}),
  ('Ô tô', '🚗', {'en': 'Car', 'ja': '車', 'ko': '자동차', 'zh': '汽车', 'fr': 'Voiture', 'es': 'Coche', 'de': 'Auto'},
      {'en': ['Bus', 'Bike', 'Train'], 'ja': ['バス', '自転車', '電車'], 'ko': ['버스', '자전거', '기차'], 'zh': ['公共汽车', '自行车', '火车'], 'fr': ['Bus', 'Vélo', 'Train'], 'es': ['Autobús', 'Bicicleta', 'Tren'], 'de': ['Bus', 'Fahrrad', 'Zug']}),
  ('Táo', '🍎', {'en': 'Apple', 'ja': 'りんご', 'ko': '사과', 'zh': '苹果', 'fr': 'Pomme', 'es': 'Manzana', 'de': 'Apfel'},
      {'en': ['Orange', 'Banana', 'Grape'], 'ja': ['オレンジ', 'バナナ', 'ぶどう'], 'ko': ['오렌지', '바나나', '포도'], 'zh': ['橙子', '香蕉', '葡萄'], 'fr': ['Orange', 'Banane', 'Raisin'], 'es': ['Naranja', 'Plátano', 'Uva'], 'de': ['Orange', 'Banane', 'Traube']}),
  ('Mặt trời', '☀️', {'en': 'Sun', 'ja': '太陽', 'ko': '태양', 'zh': '太阳', 'fr': 'Soleil', 'es': 'Sol', 'de': 'Sonne'},
      {'en': ['Moon', 'Star', 'Cloud'], 'ja': ['月', '星', '雲'], 'ko': ['달', '별', '구름'], 'zh': ['月亮', '星星', '云'], 'fr': ['Lune', 'Étoile', 'Nuage'], 'es': ['Luna', 'Estrella', 'Nube'], 'de': ['Mond', 'Stern', 'Wolke']}),
  ('Nước', '💧', {'en': 'Water', 'ja': '水', 'ko': '물', 'zh': '水', 'fr': 'Eau', 'es': 'Agua', 'de': 'Wasser'},
      {'en': ['Juice', 'Milk', 'Tea'], 'ja': ['ジュース', '牛乳', 'お茶'], 'ko': ['주스', '우유', '차'], 'zh': ['果汁', '牛奶', '茶'], 'fr': ['Jus', 'Lait', 'Thé'], 'es': ['Zumo', 'Leche', 'Té'], 'de': ['Saft', 'Milch', 'Tee']}),
  ('Máy tính', '💻', {'en': 'Laptop', 'ja': 'パソコン', 'ko': '노트북', 'zh': '电脑', 'fr': 'Ordinateur', 'es': 'Ordenador', 'de': 'Computer'},
      {'en': ['Phone', 'Tablet', 'Camera'], 'ja': ['スマホ', 'タブレット', 'カメラ'], 'ko': ['스마트폰', '태블릿', '카메라'], 'zh': ['手机', '平板', '相机'], 'fr': ['Téléphone', 'Tablette', 'Appareil photo'], 'es': ['Teléfono', 'Tableta', 'Cámara'], 'de': ['Telefon', 'Tablet', 'Kamera']}),
  ('Chó', '🐶', {'en': 'Dog', 'ja': '犬', 'ko': '개', 'zh': '狗', 'fr': 'Chien', 'es': 'Perro', 'de': 'Hund'},
      {'en': ['Cat', 'Rabbit', 'Horse'], 'ja': ['猫', 'うさぎ', '馬'], 'ko': ['고양이', '토끼', '말'], 'zh': ['猫', '兔子', '马'], 'fr': ['Chat', 'Lapin', 'Cheval'], 'es': ['Gato', 'Conejo', 'Caballo'], 'de': ['Katze', 'Hase', 'Pferd']}),
];

List<_Question> _buildQuestions(String langCode) {
  final rng = Random();
  final raw = List.of(_kRawQuestions)..shuffle(rng);
  return raw.take(10).map((q) {
    final correct = q.$3[langCode] ?? q.$3['en']!;
    final wrongs  = List<String>.from(q.$4[langCode] ?? q.$4['en']!);
    wrongs.shuffle(rng);
    final opts = [correct, ...wrongs.take(3)]..shuffle(rng);
    return _Question(
      wordVi: q.$1,
      emoji: q.$2,
      correctAnswer: correct,
      options: opts,
      langCode: langCode,
    );
  }).toList();
}

// ── TTS locale map ────────────────────────────────────────
const _kTtsLocales = {
  'en': 'en-US', 'ja': 'ja-JP', 'ko': 'ko-KR',
  'zh': 'zh-CN', 'fr': 'fr-FR', 'es': 'es-ES', 'de': 'de-DE',
};

// ── Screen ────────────────────────────────────────────────

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key, required this.langCode, required this.langName});
  final String langCode;
  final String langName;

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen>
    with SingleTickerProviderStateMixin {
  late final List<_Question> _questions;
  late final FlutterTts _tts;
  late final AnimationController _optionCtrl;

  int _current = 0;
  int? _selectedIndex;
  bool _answered = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions(widget.langCode);
    _tts = FlutterTts();
    _tts.setSpeechRate(0.45);
    _optionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _optionCtrl.dispose();
    super.dispose();
  }

  _Question get _q => _questions[_current];
  bool get _isLast => _current == _questions.length - 1;

  void _select(int i) {
    if (_answered) return;
    final correct = _q.options[i] == _q.correctAnswer;
    setState(() {
      _selectedIndex = i;
      _answered = true;
      if (correct) _score += 10;
    });
    _optionCtrl.forward(from: 0);
  }

  void _next() {
    if (_isLast) {
      _showResults();
      return;
    }
    setState(() {
      _current++;
      _selectedIndex = null;
      _answered = false;
    });
    _optionCtrl.reset();
  }

  Future<void> _speak() async {
    await _tts.setLanguage(
        _kTtsLocales[widget.langCode] ?? 'en-US');
    await _tts.speak(_q.correctAnswer);
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        score: _score,
        total: _questions.length * 10,
        correct: _score ~/ 10,
        total_q: _questions.length,
        onRetry: () {
          Navigator.of(context).pop();
          setState(() {
            _questions..clear()..addAll(_buildQuestions(widget.langCode));
            _current = 0;
            _selectedIndex = null;
            _answered = false;
            _score = 0;
          });
        },
        onExit: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageCard(),
                    const SizedBox(height: 20),
                    _buildQuestionText(),
                    const SizedBox(height: 16),
                    ..._buildOptions(),
                  ],
                ),
              ),
            ),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              children: const [
                Icon(Icons.close_rounded, size: 18, color: Color(0xFF757575)),
                SizedBox(width: 4),
                Text(
                  'Thoát',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Text(
              'BÀI KIỂM TRA',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF424242),
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF2C1A0C),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_score pts',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ─────────────────────────────────────────
  Widget _buildProgressBar() {
    final progress = (_current + 1) / _questions.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Câu hỏi ${_current + 1}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                ' / ${_questions.length}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: const Color(0xFFEEEEEE),
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Emoji image card ─────────────────────────────────────
  Widget _buildImageCard() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF2C1A0C),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(_q.emoji,
                style: const TextStyle(fontSize: 90)),
          ),
        ),
        // Listen button
        Positioned(
          bottom: 12,
          right: 14,
          child: GestureDetector(
            onTap: _speak,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up_rounded,
                      size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  const Text(
                    'NGHE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF424242),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Question text ────────────────────────────────────────
  Widget _buildQuestionText() {
    return Text(
      'Chọn bản dịch đúng cho từ "${_q.wordVi}"',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF424242),
        height: 1.4,
      ),
    );
  }

  // ── Answer options ────────────────────────────────────────
  List<Widget> _buildOptions() {
    return List.generate(_q.options.length, (i) {
      final opt = _q.options[i];
      final isCorrect = opt == _q.correctAnswer;
      final isSelected = _selectedIndex == i;

      Color bg = Colors.white;
      Color border = const Color(0xFFE8E8E8);
      Color textColor = const Color(0xFF1A1A1A);
      Widget? trailing;

      if (_answered) {
        if (isCorrect) {
          bg = AppTheme.primaryColor;
          border = AppTheme.primaryColor;
          textColor = Colors.white;
          trailing = const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 22);
        } else if (isSelected) {
          bg = const Color(0xFFFFEEEE);
          border = const Color(0xFFEF5350);
          textColor = const Color(0xFFEF5350);
          trailing = const Icon(Icons.cancel_rounded,
              color: Color(0xFFEF5350), size: 22);
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => _select(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: isCorrect && _answered
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
                if (trailing == null && !_answered)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFD0D0D0), width: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ── Next button ──────────────────────────────────────────
  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _answered ? 1.0 : 0.4,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _answered ? _next : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C1A0C),
              disabledBackgroundColor: const Color(0xFF2C1A0C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLast ? 'Xem kết quả' : 'Câu tiếp theo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('→',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Result dialog ─────────────────────────────────────────

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.score,
    required this.total,
    required this.correct,
    required this.total_q,
    required this.onRetry,
    required this.onExit,
  });
  final int score;
  final int total;
  final int correct;
  final int total_q;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  String get _emoji {
    final pct = score / total;
    if (pct >= 0.9) return '🏆';
    if (pct >= 0.7) return '🎉';
    if (pct >= 0.5) return '👍';
    return '💪';
  }

  String get _message {
    final pct = score / total;
    if (pct >= 0.9) return 'Xuất sắc!';
    if (pct >= 0.7) return 'Rất tốt!';
    if (pct >= 0.5) return 'Khá tốt!';
    return 'Cố gắng hơn nhé!';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              _message,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              '$correct / $total_q câu đúng',
              style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 16),
            // Score chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$score / $total pts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Progress arc indicator
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: score / total,
                    strokeWidth: 10,
                    backgroundColor: const Color(0xFFEEEEEE),
                    color: AppTheme.primaryColor,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      '${((score / total) * 100).round()}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onExit,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Thoát',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Thử lại',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
