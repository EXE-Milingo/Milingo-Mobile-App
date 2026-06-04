import 'package:flutter/material.dart';

class TermsOfServiceView extends StatelessWidget {
  const TermsOfServiceView({
    required this.onBack,
    super.key,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _TermsColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TermsTopBar(onBack: onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  32,
                  16,
                  MediaQuery.paddingOf(context).bottom + 32,
                ),
                child: const _TermsDocumentCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsColors {
  static const background = Color(0xFFFDF8F6);
  static const text = Color(0xFF271812);
  static const body = Color(0xFF5C4037);
  static const muted = Color(0xFFA33D19);
  static const orange = Color(0xFFE4502E);
  static const border = Color(0xFFE5BEB2);
  static const softBorder = Color(0x80E5BEB2);
  static const softSurface = Color(0xFFFFF8F6);
  static const ctaSurface = Color(0xFFFFF1EC);
}

class _TermsTopBar extends StatelessWidget {
  const _TermsTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: _TermsColors.background,
        border: Border(
          bottom: BorderSide(color: _TermsColors.border),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 10,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: _TermsColors.orange,
              tooltip: 'Quay lại',
            ),
          ),
          const Text(
            'Điều khoản dịch vụ',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _TermsColors.orange,
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsDocumentCard extends StatelessWidget {
  const _TermsDocumentCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 512),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _TermsColors.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF917065).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TermsIntro(),
              SizedBox(height: 32),
              _AcceptTermsSection(),
              SizedBox(height: 32),
              _UserContentSection(),
              SizedBox(height: 32),
              _PrivacySection(),
              SizedBox(height: 32),
              _SupportCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsIntro extends StatelessWidget {
  const _TermsIntro();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _TermsColors.border),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: 17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CẬP NHẬT LẦN CUỐI: 30/06/2026',
              style: TextStyle(
                color: _TermsColors.muted,
                fontSize: 12,
                height: 1,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Chào mừng bạn đến với nền tảng của chúng tôi',
              style: TextStyle(
                color: _TermsColors.text,
                fontSize: 24,
                height: 31.2 / 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Vui lòng đọc kỹ Điều khoản Dịch vụ này trước khi truy cập hoặc sử dụng dịch vụ của chúng tôi. Bằng cách sử dụng nền tảng của chúng tôi, bạn đồng ý bị ràng buộc bởi các điều khoản này, thiết lập một môi trường công nghệ tiên tiến, đáng tin cậy cho tất cả người dùng.',
              style: _termsBodyStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _AcceptTermsSection extends StatelessWidget {
  const _AcceptTermsSection();

  @override
  Widget build(BuildContext context) {
    return const _TermsSection(
      icon: Icons.verified_user_outlined,
      title: '1. Chấp nhận các điều khoản',
      child: _SoftTextBox(
        paragraphs: [
          'Bằng cách đăng ký và/hoặc sử dụng Dịch vụ theo bất kỳ cách nào, bao gồm nhưng không giới hạn ở việc truy cập hoặc duyệt Trang web, bạn đồng ý với các Điều khoản Dịch vụ này và tất cả các quy tắc, chính sách và thủ tục hoạt động khác mà chúng tôi có thể công bố theo thời gian trên Trang web.',
          'Các Điều khoản Dịch vụ này áp dụng cho tất cả người dùng Dịch vụ, bao gồm cả người dùng đồng thời là người đóng góp nội dung, thông tin và các tài liệu hoặc dịch vụ khác, dù đã đăng ký hay chưa.',
        ],
      ),
    );
  }
}

class _UserContentSection extends StatelessWidget {
  const _UserContentSection();

  @override
  Widget build(BuildContext context) {
    return const _TermsSection(
      icon: Icons.note_alt_outlined,
      title: '2. Nội dung người dùng',
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Color(0xFFFFDBD0), width: 2),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tất cả nội dung được người dùng thêm vào, tạo ra, tải lên, gửi đi, phân phối hoặc đăng tải lên Dịch vụ, cho dù được đăng công khai hay truyền tải riêng tư, đều thuộc trách nhiệm duy nhất của người đã tạo ra Nội dung Người dùng đó.',
                style: _termsBodyStyle,
              ),
              SizedBox(height: 24),
              Text(
                'Bạn vẫn giữ quyền sở hữu hoàn toàn đối với tài sản trí tuệ của mình.',
                style: _termsBodyStyle,
              ),
              SizedBox(height: 24),
              Text(
                'Chúng tôi yêu cầu giấy phép để lưu trữ và hiển thị nội dung của bạn một cách an toàn.',
                style: _termsBodyStyle,
              ),
              SizedBox(height: 24),
              Text(
                'Nội dung không được vi phạm bất kỳ quy định bảo vệ dữ liệu quốc tế nào.',
                style: _termsBodyStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context) {
    return const _TermsSection(
      icon: Icons.policy_outlined,
      title: '3. Chính sách bảo mật',
      child: Text.rich(
        TextSpan(
          style: _termsBodyStyle,
          children: [
            TextSpan(
              text:
                  'Để biết thông tin về cách chúng tôi thu thập, sử dụng và tiết lộ thông tin cá nhân của bạn, vui lòng xem lại ',
            ),
            TextSpan(
              text: 'Chính sách Bảo mật toàn diện ',
              style: TextStyle(
                color: Color(0xFFFF3E00),
                decoration: TextDecoration.underline,
              ),
            ),
            TextSpan(
              text:
                  'của chúng tôi. Việc bạn sử dụng Dịch vụ cho thấy bạn đồng ý với các hoạt động dữ liệu được nêu trong Chính sách Bảo mật.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _TermsColors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _TermsColors.text,
                  fontSize: 20,
                  height: 30 / 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _SoftTextBox extends StatelessWidget {
  const _SoftTextBox({required this.paragraphs});

  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _TermsColors.softSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _TermsColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final paragraph in paragraphs) ...[
            Text(paragraph, style: _termsBodyStyle),
            if (paragraph != paragraphs.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 25, 16, 16),
      decoration: const BoxDecoration(
        color: _TermsColors.ctaSurface,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: Border(
          top: BorderSide(color: _TermsColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Bạn cần hỗ trợ?',
              style: TextStyle(
                color: _TermsColors.text,
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Vui lòng liên hệ với đội ngũ pháp lý của chúng tôi để được làm rõ bất kỳ điều khoản nào.',
              style: TextStyle(
                color: _TermsColors.body,
                fontSize: 14,
                height: 21 / 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: _TermsColors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 12,
                height: 1,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            child: const Text('Liên hệ bộ phận hỗ trợ'),
          ),
        ],
      ),
    );
  }
}

const _termsBodyStyle = TextStyle(
  color: _TermsColors.body,
  fontSize: 16,
  height: 24 / 16,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
);
