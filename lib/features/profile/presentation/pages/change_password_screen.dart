import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/forgot_password/presentation/pages/forgot_password_screen.dart';
import '../../../auth/login/presentation/bloc/auth_cubit.dart';
import '../../../auth/login/presentation/bloc/auth_state.dart';
import '../../../auth/shared/auth_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 1; // 1: Old PW/Set PW Intro, 2: OTP, 3: New PW
  bool _hasCheckedPasswordStatus = false;
  bool _mustSetPasswordFirst = false;
  
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isOldVisible = false;
  bool _isNewVisible = false;
  bool _isConfirmVisible = false;

  String? _oldError;
  String? _newError;
  String? _confirmError;

  late AnimationController _floatController;
  late Animation<double> _floatAnim;

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
    _oldPasswordController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _validateNewPassword(String v) {
    setState(() {
      if (v.isEmpty) {
        _newError = 'Vui lòng nhập mật khẩu mới';
      } else if (v.length < 6) {
        _newError = 'Mật khẩu phải từ 6 ký tự';
      } else if (v == _oldPasswordController.text) {
        _newError = 'Mật khẩu mới không được trùng mật khẩu cũ';
      } else {
        _newError = null;
      }
    });
  }

  void _validateConfirmPassword(String v) {
    setState(() {
      if (v.isEmpty) {
        _confirmError = 'Vui lòng xác nhận mật khẩu';
      } else if (v != _newPasswordController.text) {
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
      child: BlocConsumer<AuthCubit, AuthState>(
        listenWhen: (prev, curr) => prev != curr,
        listener: (context, state) {
          if (state is AuthChangePasswordVerifySuccess) {
            setState(() => _currentStep = 2);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mật khẩu chính xác! Mã OTP đã được gửi.'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AuthChangePasswordOtpVerified) {
            setState(() => _currentStep = 3);
          } else if (state is AuthChangePasswordSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đổi mật khẩu thành công!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
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
          final user = state.currentUser;
          final userEmail = user?.email ?? '';

          if (user != null && !_hasCheckedPasswordStatus) {
            _hasCheckedPasswordStatus = true;
            _mustSetPasswordFirst = !user.hasPassword;
          }

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
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1A1A1A)),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: size.width * 0.07),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              _buildHeader(_currentStep, _mustSetPasswordFirst),
                              const SizedBox(height: 36),
                              if (_currentStep == 1) _buildStep1(isLoading, _mustSetPasswordFirst, state),
                              if (_currentStep == 2) _buildStep2(isLoading, userEmail),
                              if (_currentStep == 3) _buildStep3(isLoading, userEmail, state),
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
                        child: CircularProgressIndicator(color: AppColors.primaryRed, strokeWidth: 2.5),
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

  Widget _buildHeader(int step, bool mustSetPasswordFirst) {
    String title = '';
    String subtitle = '';
    IconData icon = Icons.lock_outline_rounded;

    if (step == 1) {
      if (mustSetPasswordFirst) {
        title = 'Thiết lập\nmật khẩu';
        subtitle = 'Bạn chưa có mật khẩu. Vui lòng xác thực email để thiết lập mật khẩu mới.';
        icon = Icons.add_moderator_rounded;
      } else {
        title = 'Xác thực\nmật khẩu';
        subtitle = 'Vui lòng nhập mật khẩu hiện tại của bạn để tiếp tục.';
        icon = Icons.security_rounded;
      }
    } else if (step == 2) {
      title = 'Xác nhận\nmã OTP';
      subtitle = 'Chúng tôi đã gửi mã xác thực đến email của bạn.';
      icon = Icons.mark_email_read_outlined;
    } else {
      title = mustSetPasswordFirst ? 'Mật khẩu\nmới' : 'Mật khẩu\nmới';
      subtitle = 'Thiết lập mật khẩu mới cho tài khoản của bạn.';
      icon = Icons.key_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthLogoBadge(icon: icon),
        const SizedBox(height: 24),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1A1A1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF888888), height: 1.5),
        ),
      ],
    );
  }

  Widget _buildStep1(bool isLoading, bool mustSetPasswordFirst, AuthState state) {
    if (mustSetPasswordFirst) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          AuthPrimaryButton(
            label: 'GỬI MÃ OTP QUA EMAIL',
            isLoading: isLoading,
            enabled: !isLoading,
            onTap: () {
              final user = state.currentUser;
              if (user != null) {
                // Trigger OTP right away for social users
                context.read<AuthCubit>().sendChangePasswordOtp(user.email);
                // After calling send, we automatically transition to step 2 via listener handle verifySuccess
                // Wait, verifyCurrentPassword handles OTP sending too. 
                // I should add a specific method for social OTP sending or just call verify with empty pw?
                // Let's use verifyCurrentPassword but backend should handle empty if user has no PW.
                // Actually, I'll use sendChangePasswordOtp.
                context.read<AuthCubit>().sendChangePasswordOtp(user.email);
                // Since I don't have a listener for sendOtpSuccess in AuthCubit yet, I'll add it or manually switch.
                setState(() => _currentStep = 2);
              }
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: _oldPasswordController,
          hintText: 'Mật khẩu hiện tại',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isVisible: _isOldVisible,
          errorText: _oldError,
          onToggleVisibility: () => setState(() => _isOldVisible = !_isOldVisible),
        ),
        const SizedBox(height: 32),
        AuthPrimaryButton(
          label: 'TIẾP TỤC',
          isLoading: isLoading,
          enabled: !isLoading,
          onTap: () {
            if (_oldPasswordController.text.isEmpty) {
              setState(() => _oldError = 'Vui lòng nhập mật khẩu cũ');
              return;
            }
            context.read<AuthCubit>().verifyCurrentPassword(_oldPasswordController.text);
          },
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
            },
            child: Text(
              'Quên mật khẩu?',
              style: GoogleFonts.inter(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(bool isLoading, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: TextField(
            controller: _otpController,
            enabled: !isLoading,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
              letterSpacing: 14,
            ),
            decoration: InputDecoration(
              hintText: '• • • • • •',
              hintStyle: GoogleFonts.inter(fontSize: 22, color: Colors.grey.shade300, letterSpacing: 10),
              counterText: '',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 32),
        AuthPrimaryButton(
          label: 'XÁC NHẬN MÃ',
          isLoading: isLoading,
          enabled: !isLoading,
          onTap: () {
            if (_otpController.text.length != 6) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số OTP'), backgroundColor: Colors.red),
              );
              return;
            }
            context.read<AuthCubit>().verifyChangePasswordOtp(email, _otpController.text);
          },
        ),
      ],
    );
  }

  Widget _buildStep3(bool isLoading, String email, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: _newPasswordController,
          hintText: 'Mật khẩu mới',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isVisible: _isNewVisible,
          errorText: _newError,
          onChanged: _validateNewPassword,
          onToggleVisibility: () => setState(() => _isNewVisible = !_isNewVisible),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _confirmPasswordController,
          hintText: 'Xác nhận mật khẩu mới',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isVisible: _isConfirmVisible,
          errorText: _confirmError,
          onChanged: _validateConfirmPassword,
          onToggleVisibility: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
        ),
        const SizedBox(height: 32),
        AuthPrimaryButton(
          label: 'ĐỔI MẬT KHẨU',
          isLoading: isLoading,
          enabled: !isLoading,
          onTap: () {
            _validateNewPassword(_newPasswordController.text);
            _validateConfirmPassword(_confirmPasswordController.text);
            if (_newError == null && _confirmError == null) {
              final user = state.currentUser;
              if (user != null) {
                context.read<AuthCubit>().changePassword(
                  user.email,
                  _newPasswordController.text,
                );
              }
            }
          },
        ),
      ],
    );
  }
}
