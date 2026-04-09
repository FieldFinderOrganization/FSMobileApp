import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Import AppColors từ thư mục core của bạn
import '../../../../../core/constants/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Giả lập AppColors (bạn có thể xóa đoạn này nếu đã import file app_colors.dart)
  final Color primaryRed = const Color(0xFF7B0323);

  // --- CÁC HÀM GỌI SDK LOGIC ---
  Future<void> _handleGoogleSignIn() async {
    // TODO: Triển khai Google Sign-In SDK tại đây
    // Ví dụ:
    // final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    // ... gọi tới AuthRepository
    print("Gọi Google SDK");
  }

  Future<void> _handleFacebookSignIn() async {
    // TODO: Triển khai Facebook Auth SDK tại đây
    // Ví dụ:
    // final LoginResult result = await FacebookAuth.instance.login();
    // ... gọi tới AuthRepository
    print("Gọi Facebook SDK");
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double horizontalPadding = size.width * 0.08;

    return Scaffold(
      // Dùng Stack để ảnh nền nằm dưới cùng, nội dung cuộn lên trên
      body: Stack(
        children: [
          // 1. Ảnh nền (Background)
          Positioned.fill(
            child: Image.asset(
              'assets/images/mainbg.jpg', // Đảm bảo bạn có đuôi file đúng (.jpg hoặc .png)
              fit: BoxFit.cover,
            ),
          ),

          // Thêm một lớp màu đen mờ phủ lên ảnh nền để chữ trắng dễ đọc hơn (Tùy chọn)
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          // 2. Nội dung chính
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: size.height * 0.05),

                    // --- Tiêu đề ---
                    Text(
                      'WELCOME BACK!',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 3.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // --- Phụ đề (Dùng RichText để in nghiêng chữ FS) ---
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                        children: const [
                          TextSpan(text: 'Log in to '),
                          TextSpan(
                            text: 'FS',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                          TextSpan(text: ' to continue to '),
                          TextSpan(
                            text: 'FS',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // --- Ô nhập Email ---
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'Enter your email address',
                      icon: Icons.email_rounded,
                    ),

                    const SizedBox(height: 20),

                    // --- Ô nhập Mật khẩu ---
                    _buildTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      icon: Icons.lock_rounded,
                      isPassword: true,
                    ),

                    const SizedBox(height: 12),

                    // --- Quên mật khẩu ---
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Chuyển sang màn hình Quên mật khẩu
                        },
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- Nút LOGIN ---
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Gọi logic đăng nhập Email/Password
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'LOGIN',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- Dòng chữ OR ---
                    Text(
                      '- OR Continue with -',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // --- Nút Đăng nhập MXH (Google / Facebook) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton(
                          icon: FontAwesomeIcons.google,
                          color: const Color(
                            0xFFDB4437,
                          ), // Màu đỏ chuẩn của Google
                          onTap: _handleGoogleSignIn,
                        ),
                        const SizedBox(width: 24),
                        _buildSocialButton(
                          icon: FontAwesomeIcons.facebookF,
                          color: const Color(
                            0xFF1877F2,
                          ), // Màu xanh chuẩn của Facebook
                          onTap: _handleFacebookSignIn,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // --- Nút Đăng ký ---
                    GestureDetector(
                      onTap: () {
                        // TODO: Chuyển sang màn hình Đăng ký
                      },
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          children: [
                            const TextSpan(text: 'Create An Account '),
                            TextSpan(
                              text: 'Sign Up',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.05),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget tạo Ô nhập liệu (Tái sử dụng)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
          0.85,
        ), // Hiệu ứng kính mờ (kết hợp với ảnh nền)
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 15),
          prefixIcon: Icon(icon, color: Colors.grey[700], size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey[700],
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  // Widget tạo nút MXH hình tròn (Tái sử dụng)
  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white, // Nút nền trắng
        ),
        child: Icon(
          icon,
          color: color, // Màu icon của MXH
          size: 26,
        ),
      ),
    );
  }
}
