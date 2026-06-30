import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/features/profile/widgets/support_screen_components.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F2),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            const _SupportBackground(),
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  sliver: SliverList.list(
                    children: [
                      _SupportHeader(
                        onBack: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            context.pop();
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(title: '❓ CÂU HỎI THƯỜNG GẶP'),
                      const SizedBox(height: 8),
                      const FaqAccordionTile(
                        question: 'Làm sao để quét từ mới?',
                        answer:
                            'Nhấn vào nút Camera màu cam ở giữa thanh điều hướng phía dưới. Di chuyển camera hướng vào từ hoặc vật thể cần dịch, sau đó chụp ảnh để Milingo tự động nhận diện và dịch từ vựng. Bạn có thể bấm để xem chi tiết và lưu từ đó vào danh sách học tập (Flashcards).',
                      ),
                      const FaqAccordionTile(
                        question: 'Làm sao để giữ chuỗi ngày?',
                        answer:
                            'Chuỗi ngày học (Daily Streak) được tính theo múi giờ Việt Nam (UTC+7). Bạn chỉ cần thực hiện ít nhất một hoạt động học tập mỗi ngày để giữ streak: học/ôn tập một bộ thẻ Flashcards hoặc chụp/phân tích một vật thể mới qua tính năng Snap & Learn.',
                      ),
                      const FaqAccordionTile(
                        question: 'Premium có những gì?',
                        answer:
                            'Khi nâng cấp lên Premium, bạn sẽ nhận được các đặc quyền:\n• Trò chuyện với AI Tutor không giới hạn số lượng tin nhắn (bản miễn phí giới hạn 20 tin nhắn/ngày).\n• Quét vật thể và phân tích từ vựng bằng camera không giới hạn.\n• Trải nghiệm học tập mượt mà và hoàn toàn không có quảng cáo.',
                      ),
                      const FaqAccordionTile(
                        question: 'Làm sao để đổi ngôn ngữ học tập?',
                        answer:
                            'Trong tab Hồ sơ (Profile), chọn phần \'Ngôn ngữ\', tại đây bạn có thể cấu hình ngôn ngữ gốc (bản xứ) và ngôn ngữ mục tiêu mà bạn muốn học.',
                      ),
                      const FaqAccordionTile(
                        question: 'Làm sao để khôi phục gói Premium đã mua?',
                        answer:
                            'Nếu bạn đổi thiết bị hoặc cài đặt lại ứng dụng, hãy vào tab \'Hồ sơ\', nhấp vào \'Gói Premium\' hoặc \'Tài khoản\', và bấm nút \'Khôi phục gói mua\' (Restore Purchase) để đồng bộ lại trạng thái Premium từ kho ứng dụng.',
                      ),
                      const FaqAccordionTile(
                        question: 'Tôi có thể liên hệ hỗ trợ bằng cách nào?',
                        answer:
                            'Bạn có thể gửi email trực tiếp tới bộ phận hỗ trợ khách hàng tại support@milingo.vn hoặc chọn \'Liên hệ hỗ trợ\' ở phía dưới để được giải đáp.',
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(title: '📞 LIÊN HỆ'),
                      const SizedBox(height: 12),
                      const ContactOptionsCard(),
                    ],
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

class _SupportHeader extends StatelessWidget {
  const _SupportHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          // Circular premium back button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBack,
                child: const Center(
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFF1D1814),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title and subtitle column
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hỗ trợ',
                  style: TextStyle(
                    color: Color(0xFF1D1814),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Chúng tôi luôn sẵn sàng giúp bạn',
                  style: TextStyle(
                    color: Color(0x8C1D1814),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0x801D1814),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.05,
        ),
      ),
    );
  }
}

class _SupportBackground extends StatelessWidget {
  const _SupportBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          child: _Glow(size: 320, color: Color(0x38FF8A1F)),
        ),
        Positioned(
          top: 320,
          left: -96,
          child: _Glow(size: 256, color: Color(0x1AFF4D1A)),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 64,
            spreadRadius: 24,
          ),
        ],
      ),
    );
  }
}
