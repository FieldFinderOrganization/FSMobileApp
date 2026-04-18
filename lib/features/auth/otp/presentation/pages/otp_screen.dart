import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/auth_token_entity.dart';
import '../../../login/presentation/bloc/auth_cubit.dart';
import '../../../login/presentation/bloc/auth_state.dart';
import '../../../../home/presentation/pages/main_shell.dart';
import '../../../../admin/presentation/pages/admin_shell.dart';
import '../../../shared/auth_widgets.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final AuthTokenEntity pendingToken;

  const OtpScreen({
    super.key,
    required this.email,
    required this.pendingToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
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
    _otpController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpVerified) {
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
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red[700],
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AuthInitial) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mã OTP đã được gửi lại!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

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
                              const SizedBox(height: 40),
                              _buildOtpField(isLoading),
                              const SizedBox(height: 32),
                              AuthPrimaryButton(
                                label: 'XÁC NHẬN',
                                isLoading: isLoading,
                                enabled: !isLoading,
                                onTap: () {
                                  final code = _otpController.text.trim();
                                  if (code.length != 6) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Vui lòng nhập đủ 6 chữ số OTP.'),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }
                                  context.read<AuthCubit>().verifyOtp(
                                        email: widget.email,
                                        code: code,
                                        pendingToken: widget.pendingToken,
                                      );
                                },
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: GestureDetector(
                                  onTap: isLoading
                                      ? null
                                      : () => context
                                          .read<AuthCubit>()
                                          .resendOtp(widget.email),
                                  child: RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.grey.shade500),
                                      children: [
                                        const TextSpan(
                                            text: 'Không nhận được mã? '),
                                        TextSpan(
                                          text: 'Gửi lại',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              color: _primaryRed),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
        const AuthLogoBadge(icon: Icons.verified_user_outlined),
        const SizedBox(height: 24),
        Text(
          'Xác thực\nemail',
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
              const TextSpan(text: 'Mã OTP đã được gửi đến\n'),
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

  Widget _buildOtpField(bool isLoading) {
    return Container(
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
          hintStyle: GoogleFonts.inter(
              fontSize: 22, color: Colors.grey.shade300, letterSpacing: 10),
          counterText: '',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
