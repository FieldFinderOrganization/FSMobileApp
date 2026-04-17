import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../register/presentation/pages/register_screen.dart';
import '../../../otp/presentation/pages/otp_screen.dart';
import '../../../forgot_password/presentation/pages/forgot_password_screen.dart';
import '../../../../home/presentation/pages/main_shell.dart';
import '../../../../admin/presentation/pages/admin_shell.dart';
import '../../../shared/auth_widgets.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LoginScreenBody();
  }
}

class _LoginScreenBody extends StatefulWidget {
  const _LoginScreenBody();

  @override
  State<_LoginScreenBody> createState() => _LoginScreenBodyState();
}

class _LoginScreenBodyState extends State<_LoginScreenBody>
    with SingleTickerProviderStateMixin {
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  static const _primaryRed = Color(0xFF7B0323);

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    final emailRegex = RegExp(r'^[\w\-\.+]+@([\w\-]+\.)+[\w\-]{2,}$');
    setState(() {
      if (value.trim().isEmpty) {
        _emailError = 'Vui lòng nhập email';
      } else if (!emailRegex.hasMatch(value.trim())) {
        _emailError = 'Định dạng email không hợp lệ';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      _passwordError = value.isEmpty ? 'Vui lòng nhập mật khẩu' : null;
    });
  }

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
    if (state.authToken.user.role == 'ADMIN') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AdminShell(user: state.authToken.user),
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainShell(user: state.authToken.user),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: BlocConsumer<AuthCubit, AuthState>(
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
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final bool canSubmit = _isFormValid && !isLoading;

          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                AuthBackground.standard(floatAnim: _floatAnim, size: size),
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: size.width * 0.07),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: size.height * 0.07),
                          _buildHeader(),
                          SizedBox(height: size.height * 0.05),
                          _buildForm(context, isLoading, canSubmit),
                          SizedBox(height: size.height * 0.04),
                          _buildSocialSection(context, isLoading),
                          SizedBox(height: size.height * 0.04),
                          _buildSignUpRow(context),
                          SizedBox(height: size.height * 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.6),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: _primaryRed,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AuthLogoBadge(icon: Icons.sports_soccer_rounded),
        const SizedBox(height: 28),
        Text(
          'Chào mừng\ntrở lại!',
          style: GoogleFonts.playfairDisplay(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1A1A1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Đăng nhập để tiếp tục trải nghiệm',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF888888),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading, bool canSubmit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: _emailController,
          hintText: 'Email',
          icon: Icons.email_outlined,
          errorText: _emailError,
          onChanged: _validateEmail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        AuthTextField(
          controller: _passwordController,
          hintText: 'Mật khẩu',
          icon: Icons.lock_outline_rounded,
          errorText: _passwordError,
          onChanged: _validatePassword,
          isPassword: true,
          isVisible: _isPasswordVisible,
          onToggleVisibility: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const ForgotPasswordScreen()),
            ),
            child: Text(
              'Quên mật khẩu?',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _primaryRed,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        AuthPrimaryButton(
          label: 'ĐĂNG NHẬP',
          isLoading: isLoading,
          enabled: canSubmit,
          onTap: () => context.read<AuthCubit>().signInWithEmail(
                _emailController.text.trim(),
                _passwordController.text,
              ),
        ),
      ],
    );
  }

  Widget _buildSocialSection(BuildContext context, bool isLoading) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade200)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'hoặc tiếp tục với',
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.grey.shade400),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade200)),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AuthSocialButton(
              icon: FontAwesomeIcons.google,
              color: const Color(0xFFDB4437),
              isLoading: isLoading,
              onTap: () => context.read<AuthCubit>().signInWithGoogle(),
            ),
            const SizedBox(width: 16),
            AuthSocialButton(
              icon: FontAwesomeIcons.facebookF,
              color: const Color(0xFF1877F2),
              isLoading: isLoading,
              onTap: () => context.read<AuthCubit>().signInWithFacebook(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignUpRow(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
          children: [
            const TextSpan(text: 'Chưa có tài khoản? '),
            TextSpan(
              text: 'Đăng ký',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, color: _primaryRed),
            ),
          ],
        ),
      ),
    );
  }
}
