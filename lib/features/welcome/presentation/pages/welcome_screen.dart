import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fsmobileapp/features/auth/login/presentation/pages/login_screen.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/dot_indicator.dart';
import '../widgets/welcome_page_item.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Dữ liệu hiển thị (Sau này có thể tách ra domain/entities hoặc data/models)
  final List<Map<String, String>> onboardingData = [
    {
      "title": "The Elite Collection",
      "subtitle":
          "Nâng tầm phong độ, khẳng định bản lĩnh của bạn qua những sản phẩm cao cấp nhất!",
      "image": "assets/images/welcome-1.png",
    },
    {
      "title": "The Arena Await",
      "subtitle":
          "Sẵn sàng để dẫn dắt trận đấu? Biến đấu trường thành sàn diễn của chính bạn!",
      "image": "assets/images/welcome-2.png",
    },
    {
      "title": "Exclusively Yours",
      "subtitle":
          "Tận hưởng dịch vụ Trợ lý cá nhân, đặc quyền VIP và những bộ sưu tập giới hạn phục vụ riêng cho bạn!",
      "image": "assets/images/welcome-3.png",
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double horizontalPadding = (size.width * 0.06).clamp(20.0, 60.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(horizontalPadding),
            SizedBox(height: (size.height * 0.03).clamp(10.0, 30.0)),

            // Nội dung chính
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  final data = onboardingData[index];
                  return WelcomePageItem(
                    title: data['title']!,
                    subtitle: data['subtitle']!,
                    imagePath: data['image']!,
                    horizontalPadding: horizontalPadding,
                  );
                },
              ),
            ),

            _buildBottomBar(horizontalPadding),
          ],
        ),
      ),
    );
  }

  // Tách hàm để build Top Bar
  Widget _buildTopBar(double padding) {
    return Padding(
      padding: EdgeInsets.only(top: 16, left: padding, right: padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              children: [
                TextSpan(
                  text: '${_currentIndex + 1}',
                  style: const TextStyle(color: AppColors.textDark),
                ),
                TextSpan(
                  text: '/${onboardingData.length}',
                  style: const TextStyle(color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: Text(
              'Skip',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: AppColors.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tách hàm để build Bottom Bar
  Widget _buildBottomBar(double padding) {
    return Padding(
      padding: EdgeInsets.only(bottom: 32, left: padding, right: padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút PREV
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _currentIndex > 0
                  ? GestureDetector(
                      onTap: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        'PREV',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textGrey,
                          letterSpacing: 1.5,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              onboardingData.length,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: DotIndicator(
                  isActive: _currentIndex == index,
                  activeColor: AppColors.primaryRed,
                  inactiveColor: AppColors.inactiveDot,
                ),
              ),
            ),
          ),

          // Nút NEXT / START
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  if (_currentIndex < onboardingData.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }
                },
                child: Text(
                  _currentIndex == onboardingData.length - 1 ? 'START' : 'NEXT',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryRed,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
