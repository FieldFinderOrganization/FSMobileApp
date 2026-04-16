import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/login/presentation/bloc/auth_cubit.dart';
import '../../../auth/login/presentation/bloc/auth_state.dart';
import '../../../auth/shared/auth_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  final UserEntity user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone == 'N/A' ? '' : widget.user.phone);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1000,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể chọn ảnh. Vui lòng thử lại.')),
      );
    }
  }

  void _saveChanges() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên của bạn.')),
      );
      return;
    }

    if (phone.isNotEmpty && phone != 'N/A') {
      if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Số điện thoại phải bao gồm đúng 10 chữ số.')),
        );
        return;
      }
    }

    context.read<AuthCubit>().updateProfile(
      name: name,
      phone: phone.isEmpty ? 'N/A' : phone,
      imagePath: _selectedImage?.path,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thông tin thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  _buildAvatarSection(),
                  const SizedBox(height: 40),
                  _buildForm(isLoading),
                  const SizedBox(height: 48),
                  AuthPrimaryButton(
                    label: 'LƯU THAY ĐỔI',
                    isLoading: isLoading,
                    enabled: !isLoading,
                    onTap: _saveChanges,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Chỉnh sửa hồ sơ',
        style: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
        ),
      ),
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryRed, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : widget.user.imageUrl != null && widget.user.imageUrl!.isNotEmpty
                      ? Image.network(
                          widget.user.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildInitialsPlaceholder(),
                        )
                      : _buildInitialsPlaceholder(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsPlaceholder() {
    final initials = widget.user.name.isNotEmpty
        ? widget.user.name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';
    return Container(
      color: AppColors.primaryRed,
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.playfairDisplay(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel('Họ và tên'),
        AuthTextField(
          controller: _nameController,
          hintText: 'Nhập họ và tên',
          icon: Icons.person_outline_rounded,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Số điện thoại'),
        AuthTextField(
          controller: _phoneController,
          hintText: 'Nhập số điện thoại',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Email (Không thể thay đổi)'),
        AuthTextField(
          controller: _emailController,
          hintText: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          enabled: false,
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey,
        ),
      ),
    );
  }
}
