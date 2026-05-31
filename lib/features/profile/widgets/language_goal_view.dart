import 'package:flutter/material.dart';

class LanguageGoalData {
  const LanguageGoalData({
    required this.activeLanguageName,
    required this.activeLanguageFlag,
    required this.vocabularyCountLabel,
    required this.languages,
    required this.goals,
  });

  final String activeLanguageName;
  final String activeLanguageFlag;
  final String vocabularyCountLabel;
  final List<LanguageGoalOption> languages;
  final List<WeeklyLanguageGoal> goals;
}

class LanguageGoalOption {
  const LanguageGoalOption({
    required this.code,
    required this.label,
    required this.flag,
    this.selected = false,
  });

  final String code;
  final String label;
  final String flag;
  final bool selected;
}

class WeeklyLanguageGoal {
  const WeeklyLanguageGoal({
    required this.title,
    required this.progressLabel,
    required this.progress,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.completed = false,
  });

  final String title;
  final String progressLabel;
  final double progress;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final bool completed;
}

class LanguageGoalView extends StatelessWidget {
  const LanguageGoalView({
    required this.data,
    this.onBack,
    super.key,
  });

  final LanguageGoalData data;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LanguageGoalColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _LanguageGoalHeader(
              onBack: onBack ?? () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ngôn ngữ muốn học',
                      style: TextStyle(
                        color: _LanguageGoalColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Thay đổi ngôn ngữ khác',
                      style: TextStyle(
                        color: _LanguageGoalColors.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _ActiveLanguageCard(data: data),
                    const SizedBox(height: 26),
                    _GoalLanguageSelector(languages: data.languages),
                    const SizedBox(height: 30),
                    const Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Text(
                        'Mục tiêu tuần này',
                        style: TextStyle(
                          color: _LanguageGoalColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final goal in data.goals) ...[
                      _WeeklyGoalCard(goal: goal),
                      const SizedBox(height: 14),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 108,
                        height: 39,
                        child: FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: _LanguageGoalColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: const Text('Lưu thay đổi'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageGoalHeader extends StatelessWidget {
  const _LanguageGoalHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.fromLTRB(10, 16, 10, 0),
      color: Colors.white.withValues(alpha: 0.6),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: _LanguageGoalColors.primaryDark,
            iconSize: 21,
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
            color: _LanguageGoalColors.primaryDark,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

class _ActiveLanguageCard extends StatelessWidget {
  const _ActiveLanguageCard({required this.data});

  final LanguageGoalData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 262,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12B46B50),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: -18,
            child: Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: Color(0x2BFFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -18,
            bottom: 18,
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0x21FFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              Text(
                data.activeLanguageName,
                style: const TextStyle(
                  color: _LanguageGoalColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 26),
              Container(
                width: 124,
                height: 124,
                decoration: const BoxDecoration(
                  color: _LanguageGoalColors.primary,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: ClipOval(
                  child: Image.asset(
                    data.activeLanguageFlag,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.vocabularyCountLabel,
                      style: const TextStyle(
                        color: _LanguageGoalColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Từ vựng',
                      style: TextStyle(
                        color: _LanguageGoalColors.mutedText,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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
}

class _GoalLanguageSelector extends StatelessWidget {
  const _GoalLanguageSelector({required this.languages});

  final List<LanguageGoalOption> languages;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Ngôn ngữ mục tiêu',
                style: TextStyle(
                  color: _LanguageGoalColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: _LanguageGoalColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(64, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: const Text('THÊM MỚI'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final option in languages)
              _LanguageOptionPill(option: option),
            const _AddLanguagePill(),
          ],
        ),
      ],
    );
  }
}

class _LanguageOptionPill extends StatelessWidget {
  const _LanguageOptionPill({required this.option});

  final LanguageGoalOption option;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: option.selected
                    ? _LanguageGoalColors.primary
                    : const Color(0xFFE9BFB1),
                width: option.selected ? 2 : 1,
              ),
              color: const Color(0xFFFFF1EC),
            ),
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: Image.asset(option.flag, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            option.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: option.selected
                  ? _LanguageGoalColors.primary
                  : _LanguageGoalColors.text,
              fontSize: 8,
              fontWeight: option.selected ? FontWeight.w900 : FontWeight.w700,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddLanguagePill extends StatelessWidget {
  const _AddLanguagePill();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD6A89A),
                width: 1,
                style: BorderStyle.solid,
              ),
              color: const Color(0xFFFFF4EF),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Color(0xFF9E756B),
              size: 20,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Thêm',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _LanguageGoalColors.mutedText,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyGoalCard extends StatelessWidget {
  const _WeeklyGoalCard({required this.goal});

  final WeeklyLanguageGoal goal;

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress.clamp(0.0, 1.0);

    return Container(
      height: 68,
      padding: const EdgeInsets.fromLTRB(13, 12, 12, 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D9D604A),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: goal.iconBackground,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(goal.icon, color: goal.iconColor, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _LanguageGoalColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  goal.progressLabel,
                  style: const TextStyle(
                    color: _LanguageGoalColors.mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFFFDCD4),
                    color: goal.iconColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _GoalToggle(done: goal.completed),
        ],
      ),
    );
  }
}

class _GoalToggle extends StatelessWidget {
  const _GoalToggle({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 16,
      alignment: done ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: done ? const Color(0xFF2E73FF) : const Color(0xFFFFDAD2),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: done
            ? const Icon(
                Icons.check_rounded,
                color: Color(0xFF2E73FF),
                size: 9,
              )
            : null,
      ),
    );
  }
}

class _LanguageGoalColors {
  static const background = Color(0xFFFFF1EC);
  static const primary = Color(0xFFF25F36);
  static const primaryDark = Color(0xFFC94A24);
  static const text = Color(0xFF2A1D19);
  static const mutedText = Color(0xFF8D6F67);
}
