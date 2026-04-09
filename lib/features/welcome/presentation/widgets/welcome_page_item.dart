import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomePageItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final double horizontalPadding;

  const WelcomePageItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        // Hình ảnh
        Expanded(
          flex: 5,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: _buildImageError,
            ),
          ),
        ),

        SizedBox(height: (size.height * 0.04).clamp(15.0, 40.0)),

        // Tiêu đề & Mô tả
        Expanded(
          flex: 4,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 1.5),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: (size.width * 0.08).clamp(28.0, 48.0),
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: (size.height * 0.02).clamp(10.0, 20.0)),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: (size.width * 0.045).clamp(14.0, 20.0),
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF2D2D2D),
                      height: 1.6,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: const Center(
        child: Text('Lỗi tải ảnh', style: TextStyle(color: Colors.black38)),
      ),
    );
  }
}
