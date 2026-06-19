import 'package:flutter/material.dart';
import 'package:milingo/core/theme/app_theme.dart';

enum RestorePurchaseStatus {
  restorable,
  expired,
}

class RestorePurchasePackage {
  const RestorePurchasePackage({
    required this.name,
    required this.expiryLabel,
    required this.status,
    required this.storeLabel,
  });

  final String name;
  final String expiryLabel;
  final RestorePurchaseStatus status;
  final String storeLabel;
}

class RestorePurchaseFlow extends StatefulWidget {
  const RestorePurchaseFlow({
    required this.packages,
    required this.onBack,
    this.onManageAccount,
    super.key,
  });

  final List<RestorePurchasePackage> packages;
  final VoidCallback onBack;
  final VoidCallback? onManageAccount;

  @override
  State<RestorePurchaseFlow> createState() => _RestorePurchaseFlowState();
}

class _RestorePurchaseFlowState extends State<RestorePurchaseFlow> {
  _RestoreStep _step = _RestoreStep.selection;

  Future<void> _restorePackage(RestorePurchasePackage package) async {
    if (package.status != RestorePurchaseStatus.restorable) return;

    setState(() => _step = _RestoreStep.restoring);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _step = _RestoreStep.success);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: switch (_step) {
        _RestoreStep.selection => _RestoreSelectionView(
            key: const ValueKey('restore-selection'),
            packages: widget.packages,
            onBack: widget.onBack,
            onRestore: _restorePackage,
          ),
        _RestoreStep.restoring => const _RestoreLoadingView(
            key: ValueKey('restore-loading'),
          ),
        _RestoreStep.success => _RestoreSuccessView(
            key: const ValueKey('restore-success'),
            onManageAccount: widget.onManageAccount,
          ),
      },
    );
  }
}

enum _RestoreStep {
  selection,
  restoring,
  success,
}

class _RestoreSelectionView extends StatelessWidget {
  const _RestoreSelectionView({
    required this.packages,
    required this.onBack,
    required this.onRestore,
    super.key,
  });

  final List<RestorePurchasePackage> packages;
  final VoidCallback onBack;
  final ValueChanged<RestorePurchasePackage> onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height,
      color: _RestoreColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _RestoreTopBar(onBack: onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 48, 22, 34),
                child: Column(
                  children: [
                    const _RestoreIntro(),
                    const SizedBox(height: 44),
                    for (var index = 0; index < packages.length; index++) ...[
                      _RestorePackageCard(
                        package: packages[index],
                        onRestore: () => onRestore(packages[index]),
                      ),
                      if (index != packages.length - 1)
                        const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 34),
                    const _RestoreSupportLink(),
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

class _RestoreTopBar extends StatelessWidget {
  const _RestoreTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: _RestoreColors.primaryDark,
          iconSize: 25,
          splashRadius: 22,
        ),
      ),
    );
  }
}

class _RestoreIntro extends StatelessWidget {
  const _RestoreIntro();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Khôi phục gói',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _RestoreColors.text,
            fontSize: 31,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        SizedBox(height: 14),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Chúng tôi tìm thấy các gói đăng ký trước đó liên kết với tài khoản của bạn. Vui lòng chọn gói bạn muốn khôi phục.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _RestoreColors.mutedText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

class _RestorePackageCard extends StatelessWidget {
  const _RestorePackageCard({
    required this.package,
    required this.onRestore,
  });

  final RestorePurchasePackage package;
  final VoidCallback onRestore;

  bool get _isRestorable => package.status == RestorePurchaseStatus.restorable;

  @override
  Widget build(BuildContext context) {
    final statusLabel = _isRestorable ? 'CÓ THỂ KHÔI PHỤC' : 'ĐÃ HẾT HẠN';

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (_isRestorable ? _RestoreColors.primary : Colors.black)
                .withValues(alpha: _isRestorable ? 0.17 : 0.04),
            blurRadius: _isRestorable ? 28 : 14,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
        decoration: BoxDecoration(
          color: _isRestorable
              ? Colors.white.withValues(alpha: 0.92)
              : const Color(0xFFF5EEEB),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _isRestorable
                ? const Color(0xFFFFD5CA)
                : Colors.white.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RestorePlanIcon(active: _isRestorable),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              package.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _isRestorable
                                    ? _RestoreColors.text
                                    : _RestoreColors.disabledText,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _RestoreStatusPill(
                            label: statusLabel,
                            active: _isRestorable,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        package.expiryLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _isRestorable
                              ? _RestoreColors.mutedText
                              : _RestoreColors.disabledText,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_isRestorable) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Truy cập toàn bộ tính năng cao cấp',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _RestoreColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (_isRestorable) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                  onPressed: onRestore,
                  style: FilledButton.styleFrom(
                    backgroundColor: _RestoreColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Khôi phục ngay'),
                      SizedBox(width: 9),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RestorePlanIcon extends StatelessWidget {
  const _RestorePlanIcon({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFECE8) : const Color(0xFFF0EAE8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        active ? Icons.workspace_premium_rounded : Icons.star_border_rounded,
        color:
            active ? _RestoreColors.primaryDark : _RestoreColors.disabledIcon,
        size: 27,
      ),
    );
  }
}

class _RestoreStatusPill extends StatelessWidget {
  const _RestoreStatusPill({
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE9F7E9) : const Color(0xFFE8DEDA),
        borderRadius: BorderRadius.circular(99),
        border: active ? Border.all(color: const Color(0xFFB7DEB8)) : null,
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: active ? const Color(0xFF427C45) : _RestoreColors.disabledText,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _RestoreSupportLink extends StatelessWidget {
  const _RestoreSupportLink();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEBDDD8), width: 1),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.help_outline_rounded,
            color: _RestoreColors.mutedText,
            size: 28,
          ),
          SizedBox(height: 13),
          Text(
            'Không tìm thấy gói bạn đã mua?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _RestoreColors.mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Liên hệ bộ phận hỗ trợ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _RestoreColors.primaryDark,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestoreLoadingView extends StatelessWidget {
  const _RestoreLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height,
      alignment: Alignment.center,
      color: _RestoreColors.background,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.fromLTRB(28, 44, 28, 38),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(31),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24B96B58),
              blurRadius: 42,
              offset: Offset(0, 25),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RestoreSpinner(),
            SizedBox(height: 30),
            Text(
              'Đang khôi phục...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _RestoreColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Vui lòng chờ trong giây lát khi chúng tôi kiểm tra giao dịch của bạn với Google Play',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _RestoreColors.mutedText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestoreSpinner extends StatefulWidget {
  const _RestoreSpinner();

  @override
  State<_RestoreSpinner> createState() => _RestoreSpinnerState();
}

class _RestoreSpinnerState extends State<_RestoreSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E0DD), width: 4),
        ),
        child: const Center(
          child: Icon(
            Icons.sync_rounded,
            color: _RestoreColors.primary,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _RestoreSuccessView extends StatelessWidget {
  const _RestoreSuccessView({
    required this.onManageAccount,
    super.key,
  });

  final VoidCallback? onManageAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height,
      color: _RestoreColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 88, 18, 36),
          child: Column(
            children: [
              const _SuccessMedal(),
              const SizedBox(height: 38),
              const Text(
                'Khôi phục thành công!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _RestoreColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'Chào mừng bạn trở lại. Gói Milingo Premium của bạn đã được kích hoạt thành công',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _RestoreColors.mutedText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 74),
              const _PrimaryBenefitCard(),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(
                    child: _CompactBenefitCard(
                      icon: Icons.block_rounded,
                      label: 'Trải nghiệm\nkhông quảng cáo',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _CompactBenefitCard(
                      icon: Icons.download_rounded,
                      label: 'Học tập\nngoại tuyến',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _RestoreColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 12,
                    shadowColor: _RestoreColors.primary.withValues(alpha: 0.26),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: const Text('BẮT ĐẦU HỌC NGAY'),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onManageAccount,
                child: const Text(
                  'Quản lý tài khoản',
                  style: TextStyle(
                    color: _RestoreColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: _RestoreColors.mutedText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessMedal extends StatelessWidget {
  const _SuccessMedal();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 136,
          height: 136,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _RestoreColors.primary.withValues(alpha: 0.22),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: _RestoreColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: 1,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _RestoreColors.primary,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryBenefitCard extends StatelessWidget {
  const _PrimaryBenefitCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 22, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E4DF)),
      ),
      child: const Row(
        children: [
          _BenefitIcon(icon: Icons.workspace_premium_rounded),
          SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quyền truy cập không giới hạn',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _RestoreColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Mở khóa toàn bộ thư viện khóa học cao cấp và tài liệu độc quyền.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _RestoreColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactBenefitCard extends StatelessWidget {
  const _CompactBenefitCard({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E4DF)),
      ),
      child: Column(
        children: [
          _BenefitIcon(icon: icon),
          const Spacer(),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _RestoreColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.18,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitIcon extends StatelessWidget {
  const _BenefitIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: const BoxDecoration(
        color: Color(0xFFFFECE8),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: _RestoreColors.primary, size: 20),
    );
  }
}

class _RestoreColors {
  static const background = Color(0xFFFFF9F7);
  static const primary = AppTheme.primaryColor;
  static const primaryDark = Color(0xFFC6491F);
  static const text = Color(0xFF221914);
  static const mutedText = Color(0xFF7E625A);
  static const disabledText = Color(0xFF8F827D);
  static const disabledIcon = Color(0xFF6C6662);
}
