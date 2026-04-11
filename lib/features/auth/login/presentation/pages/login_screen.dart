import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../register/presentation/pages/register_screen.dart';
import '../../../otp/presentation/pages/otp_screen.dart';
import '../../../forgot_password/presentation/pages/forgot_password_screen.dart';
import '../../../../home/presentation/pages/main_shell.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = TokenStorage();
    final dioClient = DioClient(tokenStorage);
    final datasource = AuthRemoteDatasource(dioClient.dio);
    final repository = AuthRepositoryImpl(datasource);

    return BlocProvider(
      create: (_) =>
          AuthCubit(authRepository: repository, tokenStorage: tokenStorage),
      child: const _LoginScreenBody(),
    );
  }
}

class _LoginScreenBody extends StatefulWidget {
  const _LoginScreenBody();

  @override
  State<_LoginScreenBody> createState() => _LoginScreenBodyState();
}

class _LoginScreenBodyState extends State<_LoginScreenBody> {
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Biến lưu trạng thái lỗi
  String? _emailError;
  String? _passwordError;

  final Color primaryRed = const Color(0xFF7B0323);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Kiểm tra email hợp lệ
  void _validateEmail(String value) {
    final email = value.trim();
    final emailRegex = RegExp(r'^[\w\-\.+]+@([\w\-]+\.)+[\w\-]{2,}$');

    setState(() {
      if (email.isEmpty) {
        _emailError = 'Vui lòng nhập email';
      } else if (!emailRegex.hasMatch(email)) {
        _emailError = 'Định dạng email không hợp lệ';
      } else {
        _emailError = null;
      }
    });
  }

  // Kiểm tra mật khẩu hợp lệ
  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = 'Vui lòng nhập mật khẩu';
      } else {
        _passwordError = null;
      }
    });
  }

  // Kiểm tra xem nút Login có được bật hay không
  bool get _isFormValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailRegex = RegExp(r'^[\w\-\.+]+@([\w\-]+\.)+[\w\-]{2,}$');

    return email.isNotEmpty &&
        password.isNotEmpty &&
        emailRegex.hasMatch(email) &&
        _emailError == null &&
        _passwordError == null;
  }

  void _navigateToHome(BuildContext context, AuthSuccess state) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainShell(user: state.authToken.user),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double horizontalPadding = size.width * 0.08;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          _navigateToHome(context, state);
        } else if (state is AuthOtpSent) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AuthCubit>(),
                child: OtpScreen(
                  email: state.email,
                  pendingToken: state.pendingToken,
                ),
              ),
            ),
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final bool canSubmit = _isFormValid && !isLoading;

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/mainbg.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: size.height * 0.05),
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
                        _buildTextField(
                          controller: _emailController,
                          hintText: 'Enter your email address',
                          icon: Icons.email_rounded,
                          errorText: _emailError,
                          onChanged: _validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.lock_rounded,
                          isPassword: true,
                          errorText: _passwordError,
                          onChanged: _validatePassword,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
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
                        ElevatedButton(
                          onPressed: canSubmit
                              ? () {
                                  context.read<AuthCubit>().signInWithEmail(
                                    _emailController.text.trim(),
                                    _passwordController.text,
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            disabledBackgroundColor: Colors.grey.withOpacity(
                              0.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'LOGIN',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: canSubmit
                                        ? Colors.white
                                        : Colors.white60,
                                    letterSpacing: 3.0,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 40),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(
                              icon: FontAwesomeIcons.google,
                              color: const Color(0xFFDB4437),
                              isLoading: isLoading,
                              onTap: () =>
                                  context.read<AuthCubit>().signInWithGoogle(),
                            ),
                            const SizedBox(width: 24),
                            _buildSocialButton(
                              icon: FontAwesomeIcons.facebookF,
                              color: const Color(0xFF1877F2),
                              isLoading: isLoading,
                              onTap: () => context
                                  .read<AuthCubit>()
                                  .signInWithFacebook(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
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
              if (isLoading)
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.1)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    String? errorText,
    Function(String)? onChanged,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: errorText != null
                ? Border.all(color: Colors.redAccent, width: 1.5)
                : null,
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !_isPasswordVisible,
            onChanged: onChanged,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                color: Colors.grey[600],
                fontSize: 15,
              ),
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
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 6),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(isLoading ? 0.5 : 1.0),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}
