import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../login/presentation/bloc/auth_cubit.dart';
import '../../../login/presentation/bloc/auth_state.dart';
import '../../../shared/auth_widgets.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = TokenStorage();
    final dioClient = DioClient(tokenStorage);
    final datasource = AuthRemoteDatasource(dioClient.dio);
    final repository = AuthRepositoryImpl(datasource);

    return BlocProvider(
      create: (_) =>
          AuthCubit(authRepository: repository, tokenStorage: tokenStorage),
      child: const _RegisterScreenBody(),
    );
  }
}

class _RegisterScreenBody extends StatefulWidget {
  const _RegisterScreenBody();

  @override
  State<_RegisterScreenBody> createState() => _RegisterScreenBodyState();
}

class _RegisterScreenBodyState extends State<_RegisterScreenBody>
    with SingleTickerProviderStateMixin {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  static const _primaryRed = Color(0xFF7B0323);

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: 14).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _validateName(String v) => setState(
      () => _nameError = v.trim().isEmpty ? 'Vui lòng nhập họ tên' : null);

  void _validateEmail(String v) {
    final regex = RegExp(r'^[\w\-\.+]+@([\w\-]+\.)+[\w\-]{2,}$');
    setState(() {
      if (v.trim().isEmpty) {
        _emailError = 'Vui lòng nhập email';
      } else if (!regex.hasMatch(v.trim())) {
        _emailError = 'Email không đúng định dạng';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePhone(String v) {
    setState(() {
      if (v.trim().isEmpty) {
        _phoneError = 'Vui lòng nhập số điện thoại';
      } else if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) {
        _phoneError = 'Số điện thoại phải có 10 chữ số';
      } else {
        _phoneError = null;
      }
    });
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

  void _validateConfirmPassword(String v) {
    setState(() {
      if (v.isEmpty) {
        _confirmPasswordError = 'Vui lòng xác nhận mật khẩu';
      } else if (v != _passwordController.text) {
        _confirmPasswordError = 'Mật khẩu xác nhận không khớp';
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  void _onRegister(BuildContext context) {
    _validateName(_nameController.text);
    _validateEmail(_emailController.text);
    _validatePhone(_phoneController.text);
    _validatePassword(_passwordController.text);
    _validateConfirmPassword(_confirmPasswordController.text);

    if (_nameError != null ||
        _emailError != null ||
        _phoneError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) return;

    context.read<AuthCubit>().registerUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthRegisterSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đăng ký thành công! Vui lòng kiểm tra email.'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop();
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

          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                AuthBackground.standard(floatAnim: _floatAnim, size: size),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 8, right: 16, top: 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
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
                              const SizedBox(height: 8),
                              _buildHeader(),
                              const SizedBox(height: 32),
                              AuthTextField(
                                controller: _nameController,
                                hintText: 'Họ và tên',
                                icon: Icons.person_outline_rounded,
                                errorText: _nameError,
                                onChanged: _validateName,
                              ),
                              const SizedBox(height: 12),
                              AuthTextField(
                                controller: _emailController,
                                hintText: 'Email',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                errorText: _emailError,
                                onChanged: _validateEmail,
                              ),
                              const SizedBox(height: 12),
                              AuthTextField(
                                controller: _phoneController,
                                hintText: 'Số điện thoại',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                errorText: _phoneError,
                                onChanged: _validatePhone,
                              ),
                              const SizedBox(height: 12),
                              AuthTextField(
                                controller: _passwordController,
                                hintText: 'Mật khẩu',
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
                                controller: _confirmPasswordController,
                                hintText: 'Xác nhận mật khẩu',
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                                isVisible: _isConfirmPasswordVisible,
                                errorText: _confirmPasswordError,
                                onChanged: _validateConfirmPassword,
                                onToggleVisibility: () => setState(() =>
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible),
                              ),
                              const SizedBox(height: 20),
                              _buildTerms(),
                              const SizedBox(height: 24),
                              AuthPrimaryButton(
                                label: 'ĐĂNG KÝ',
                                isLoading: isLoading,
                                enabled: !isLoading,
                                onTap: () => _onRegister(context),
                              ),
                              const SizedBox(height: 24),
                              _buildLoginRow(context),
                              const SizedBox(height: 32),
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
        const AuthLogoBadge(icon: Icons.sports_soccer_rounded),
        const SizedBox(height: 24),
        Text(
          'Tạo tài khoản\nmới',
          style: GoogleFonts.playfairDisplay(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1A1A1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tham gia cộng đồng để nhận ưu đãi độc quyền',
          style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF888888)),
        ),
      ],
    );
  }

  Widget _buildTerms() {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
        children: [
          const TextSpan(text: 'Bấm '),
          TextSpan(
            text: 'Đăng ký',
            style: GoogleFonts.inter(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: _primaryRed),
          ),
          const TextSpan(
              text:
                  ' đồng nghĩa bạn đồng ý với chính sách bảo mật của chúng tôi'),
        ],
      ),
    );
  }

  Widget _buildLoginRow(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
          children: [
            const TextSpan(text: 'Đã có tài khoản? '),
            TextSpan(
              text: 'Đăng nhập',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, color: _primaryRed),
            ),
          ],
        ),
      ),
    );
  }
}
