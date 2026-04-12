import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/forgot_password_cubit.dart';
import '../bloc/forgot_password_state.dart';
import '../../../login/presentation/pages/login_screen.dart';
import '../../../shared/auth_widgets.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;

  const NewPasswordScreen({super.key, required this.email});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  String? _passwordError;
  String? _confirmError;

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
    _floatAnim = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _validatePassword(String v) {
    setState(() {
      if (v.isEmpty) {
        _passwordError = 'Vui lòng nhập mật khẩu';
      } else if (v.length < 6) {
        _passwordError = 'Mật khẩu phải từ 6 ký tự';
      } else {
        _passwordError = null;
      }
    });
  }

  void _validateConfirm(String v) {
    setState(() {
      if (v.isEmpty) {
        _confirmError = 'Vui lòng xác nhận mật khẩu';
      } else if (v != _passwordController.text) {
        _confirmError = 'Mật khẩu xác nhận không khớp';
      } else {
        _confirmError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listener: (context, state) {
          if (state is PasswordResetSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Đặt lại mật khẩu thành công! Vui lòng đăng nhập.'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          } else if (state is ForgotPasswordFailure) {
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
          final isLoading = state is ForgotPasswordLoading;

          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                AuthBackground.standard(floatAnim: _floatAnim, size: size),
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 8),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.07),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              _buildHeader(),
                              const SizedBox(height: 36),
                              AuthTextField(
                                controller: _passwordController,
                                hintText: 'Mật khẩu mới',
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                                isVisible: _isPasswordVisible,
                                errorText: _passwordError,
                                onChanged: _validatePassword,
                                onToggleVisibility: () => setState(() =>
                                    _isPasswordVisible = !_isPasswordVisible),
                              ),
                              const SizedBox(height: 12),
                              AuthTextField(
                                controller: _confirmController,
                                hintText: 'Xác nhận mật khẩu',
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                                isVisible: _isConfirmVisible,
                                errorText: _confirmError,
                                onChanged: _validateConfirm,
                                onToggleVisibility: () => setState(() =>
                                    _isConfirmVisible = !_isConfirmVisible),
                              ),
                              const SizedBox(height: 32),
                              AuthPrimaryButton(
                                label: 'CẬP NHẬT MẬT KHẨU',
                                isLoading: isLoading,
                                enabled: !isLoading,
                                onTap: () {
                                  _validatePassword(_passwordController.text);
                                  _validateConfirm(_confirmController.text);
                                  if (_passwordError != null ||
                                      _confirmError != null) return;
                                  context
                                      .read<ForgotPasswordCubit>()
                                      .resetPassword(
                                        widget.email,
                                        _passwordController.text,
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.6),
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: _primaryRed, strokeWidth: 2.5),
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
        const AuthLogoBadge(icon: Icons.key_rounded),
        const SizedBox(height: 24),
        Text(
          'Mật khẩu\nmới',
          style: GoogleFonts.playfairDisplay(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1A1A1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF888888), height: 1.5),
            children: [
              const TextSpan(text: 'Đặt lại mật khẩu cho\n'),
              TextSpan(
                text: widget.email,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF444444)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
