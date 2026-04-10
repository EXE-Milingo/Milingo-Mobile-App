import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _Category {
  final String nameVi;
  final int wordCount;
  final IconData icon;
  // Unsplash photo (no-API-key required format)
  final String imageUrl;

  const _Category({
    required this.nameVi,
    required this.wordCount,
    required this.icon,
    required this.imageUrl,
  });
}

const _kCategories = [
  _Category(
    nameVi: 'Nhà bếp',
    wordCount: 42,
    icon: Icons.soup_kitchen_rounded,
    imageUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&q=80',
  ),
  _Category(
    nameVi: 'Thiên nhiên',
    wordCount: 128,
    icon: Icons.nature_rounded,
    imageUrl: 'https://images.unsplash.com/photo-1501854140801-50d01698950b?w=400&q=80',
  ),
  _Category(
    nameVi: 'Thành phố',
    wordCount: 85,
    icon: Icons.location_city_rounded,
    imageUrl: 'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=400&q=80',
  ),
  _Category(
    nameVi: 'Quán cà phê',
    wordCount: 36,
    icon: Icons.coffee_rounded,
    imageUrl: 'https://images.unsplash.com/photo-1453614512568-c4024d13c247?w=400&q=80',
  ),
  _Category(
    nameVi: 'Văn phòng',
    wordCount: 54,
    icon: Icons.business_center_rounded,
    imageUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=400&q=80',
  ),
  _Category(
    nameVi: 'Phòng ngủ',
    wordCount: 28,
    icon: Icons.bed_rounded,
    imageUrl: 'https://images.unsplash.com/photo-1540518614846-7eded433c457?w=400&q=80',
  ),
  _Category(
    nameVi: 'Sân vườn',
    wordCount: 63,
    icon: Icons.yard_rounded,
    imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400&q=80',
  ),
  _Category(
    nameVi: 'Đường phố',
    wordCount: 47,
    icon: Icons.directions_car_rounded,
    imageUrl: 'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=400&q=80',
  ),
  _Category(
    nameVi: 'Trường học',
    wordCount: 91,
    icon: Icons.school_rounded,
    imageUrl: 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?w=400&q=80',
  ),
  _Category(
    nameVi: 'Du lịch',
    wordCount: 76,
    icon: Icons.sailing_rounded,
    imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&q=80',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  String _query = '';

  List<_Category> get _filtered => _kCategories
      .where((c) => c.nameVi.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Tất cả danh mục',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Search bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm danh mục...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 8),
                        child: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Grid ──
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.875,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) => _CategoryCard(category: _filtered[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category card
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});
  final _Category category;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background photo ──
            Image.network(
              category.imageUrl,
              fit: BoxFit.cover,
              // Fallback placeholder while loading
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: const Color(0xFFD8D8D8),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                    ),
                  ),
                );
              },
              errorBuilder: (ctx, _, __) => Container(
                color: const Color(0xFFCCCCCC),
                child: const Icon(Icons.image_not_supported_rounded,
                    color: Colors.white54, size: 40),
              ),
            ),

            // ── Dark overlay tint ──
            Container(
              decoration: const BoxDecoration(
                color: Color(0x33000000),
              ),
            ),

            // ── Bottom gradient for text legibility ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 90,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
              ),
            ),

            // ── Centered icon chip ──
            Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: Icon(category.icon, color: Colors.white, size: 22),
              ),
            ),

            // ── Text labels (bottom-left) ──
            Positioned(
              left: 12,
              right: 12,
              bottom: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.nameVi,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(blurRadius: 6, color: Colors.black54),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${category.wordCount} từ',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
