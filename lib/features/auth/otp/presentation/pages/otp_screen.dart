import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/auth_token_entity.dart';
import '../../../login/presentation/bloc/auth_cubit.dart';
import '../../../login/presentation/bloc/auth_state.dart';
import '../../../../home/presentation/pages/main_shell.dart';

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

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final Color primaryRed = const Color(0xFF7B0323);

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double horizontalPadding = size.width * 0.08;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpVerified) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => MainShell(user: state.authToken.user),
            ),
            (route) => false,
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red[700],
            ),
          );
        } else if (state is AuthInitial) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mã OTP đã được gửi lại!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

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
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: size.height * 0.05),
                        Text(
                          'XÁC THỰC EMAIL',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Mã OTP đã được gửi đến\n${widget.email}',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 12,
                            ),
                            decoration: InputDecoration(
                              hintText: '------',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 28,
                                color: Colors.grey[500],
                                letterSpacing: 12,
                              ),
                              counterText: '',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  final code = _otpController.text.trim();
                                  if (code.length != 6) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Vui lòng nhập đủ 6 chữ số OTP.'),
                                        backgroundColor: Colors.red,
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            disabledBackgroundColor: primaryRed.withOpacity(0.6),
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
                                  'XÁC NHẬN',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.read<AuthCubit>().resendOtp(widget.email),
                          child: Text(
                            'Gửi lại mã OTP',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
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
}
