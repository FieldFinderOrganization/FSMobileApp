import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../login/presentation/bloc/auth_cubit.dart';
import '../../../login/presentation/bloc/auth_state.dart';

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

class _RegisterScreenBodyState extends State<_RegisterScreenBody> {
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

  void _validateName(String value) {
    setState(() {
      _nameError = value.trim().isEmpty ? 'Vui lòng nhập họ tên' : null;
    });
  }

  void _validateEmail(String value) {
    final emailRegex = RegExp(r'^[\w\-\.+]+@([\w\-]+\.)+[\w\-]{2,}$');
    setState(() {
      if (value.trim().isEmpty) {
        _emailError = 'Vui lòng nhập email';
      } else if (!emailRegex.hasMatch(value.trim())) {
        _emailError = 'Email không đúng định dạng';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePhone(String value) {
    final phoneRegex = RegExp(r'^\d{10}$');
    setState(() {
      if (value.trim().isEmpty) {
        _phoneError = 'Vui lòng nhập số điện thoại';
      } else if (!phoneRegex.hasMatch(value.trim())) {
        _phoneError = 'Số điện thoại phải có 10 chữ số';
      } else {
        _phoneError = null;
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = 'Vui lòng nhập mật khẩu';
      } else if (value.length < 6) {
        _passwordError = 'Mật khẩu phải từ 6 ký tự';
      } else {
        _passwordError = null;
      }
    });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _confirmPasswordError = 'Vui lòng xác nhận mật khẩu';
      } else if (value != _passwordController.text) {
        _confirmPasswordError = 'Mật khẩu xác nhận không khớp';
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  final Color primaryRed = const Color(0xFF7B0323);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister(BuildContext context) {
    // Kích hoạt kiểm tra tất cả các trường
    _validateName(_nameController.text);
    _validateEmail(_emailController.text);
    _validatePhone(_phoneController.text);
    _validatePassword(_passwordController.text);
    _validateConfirmPassword(_confirmPasswordController.text);

    // Kiểm tra nếu có bất kỳ lỗi nào hiện hữu
    if (_nameError != null ||
        _emailError != null ||
        _phoneError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      return;
    }

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
    final double horizontalPadding = size.width * 0.08;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthRegisterSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công! Vui lòng kiểm tra email.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
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
                          'CREATE ACCOUNT',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 3.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Join our community for exclusive rewards',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        _buildTextField(
                          controller: _nameController,
                          hintText: 'Enter your full name',
                          icon: Icons.person_rounded,
                          errorText: _nameError, // Truyền biến lỗi
                          onChanged: _validateName,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          hintText: 'Enter your email address',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                          onChanged: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneController,
                          hintText: 'Enter your phone number',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          errorText: _phoneError,
                          onChanged: _validatePhone,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.lock_rounded,
                          errorText: _passwordError,
                          onChanged: _validatePassword,
                          isPassword: true,
                          isVisible: _isPasswordVisible,
                          onToggleVisibility: () {
                            setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          errorText: _confirmPasswordError,
                          onChanged: _validateConfirmPassword,
                          isVisible: _isConfirmPasswordVisible,
                          onToggleVisibility: () {
                            setState(
                              () => _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                            children: [
                              const TextSpan(text: 'By clicking the '),
                              TextSpan(
                                text: 'Register',
                                style: GoogleFonts.inter(
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFE57373),
                                ),
                              ),
                              const TextSpan(
                                text:
                                    ' button, you agree to our privacy policy',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () => _onRegister(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            disabledBackgroundColor: primaryRed.withOpacity(
                              0.6,
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
                                  'REGISTER',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 3.0,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'I Already Have An Account ',
                                ),
                                TextSpan(
                                  text: 'Login',
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
    String? errorText, // Thêm dòng này
    Function(String)? onChanged, // Thêm để validate khi đang gõ
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            // Đổi màu viền nếu có lỗi
            border: errorText != null
                ? Border.all(color: Colors.redAccent, width: 1.5)
                : null,
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !isVisible,
            keyboardType: keyboardType,
            onChanged: onChanged, // Gọi hàm validate khi gõ
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
                        isVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[700],
                        size: 20,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
              // Chúng ta không dùng errorText của InputDecoration mặc định
              // vì nó làm vỡ layout Container tròn, ta tự build Text bên dưới.
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
