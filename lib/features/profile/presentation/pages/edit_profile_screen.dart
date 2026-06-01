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
import '../../../../core/location/map_picker_screen.dart';

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
  late TextEditingController _addressController;
  late TextEditingController _provinceController;
  late TextEditingController _districtController;
  late TextEditingController _occupationController;

  String? _gender;             // MALE/FEMALE/OTHER
  DateTime? _dateOfBirth;
  String? _preferredPitchType; // FIVE_A_SIDE/SEVEN_A_SIDE/ELEVEN_A_SIDE
  String? _preferredPlayTime;  // MORNING/AFTERNOON/EVENING/NIGHT
  double? _pickedLat;
  double? _pickedLng;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone == 'N/A' ? '' : widget.user.phone);
    _emailController = TextEditingController(text: widget.user.email);
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _provinceController = TextEditingController(text: widget.user.province ?? '');
    _districtController = TextEditingController(text: widget.user.district ?? '');
    _occupationController = TextEditingController(text: widget.user.occupation ?? '');
    _pickedLat = widget.user.latitude;
    _pickedLng = widget.user.longitude;

    _gender = widget.user.gender;
    _dateOfBirth = widget.user.dateOfBirth;
    _preferredPitchType = widget.user.preferredPitchType;
    _preferredPlayTime = widget.user.preferredPlayTime;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _occupationController.dispose();
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

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = _dateOfBirth ?? DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
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
      gender: _gender,
      dateOfBirth: _dateOfBirth,
      address: _addressController.text.trim(),
      province: _provinceController.text.trim(),
      district: _districtController.text.trim(),
      occupation: _occupationController.text.trim(),
      preferredPitchType: _preferredPitchType,
      preferredPlayTime: _preferredPlayTime,
      latitude: _pickedLat,
      longitude: _pickedLng,
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
        _buildSectionLabel('Thông tin cơ bản'),
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

        const SizedBox(height: 28),
        _buildSectionLabel('Thông tin cá nhân'),
        _buildFieldLabel('Giới tính'),
        _buildDropdown<String>(
          icon: Icons.wc_rounded,
          value: _gender,
          hint: 'Chọn giới tính',
          items: const [
            DropdownMenuItem(value: 'MALE', child: Text('Nam')),
            DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
            DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
          ],
          onChanged: (v) => setState(() => _gender = v),
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Ngày sinh'),
        InkWell(
          onTap: _pickDateOfBirth,
          child: _buildReadOnlyField(
            icon: Icons.cake_outlined,
            text: _dateOfBirth == null
                ? 'Chọn ngày sinh'
                : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}',
            isPlaceholder: _dateOfBirth == null,
          ),
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Địa chỉ'),
        AuthTextField(
          controller: _addressController,
          hintText: 'Số nhà, tên đường',
          icon: Icons.location_on_outlined,
          keyboardType: TextInputType.streetAddress,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.map_outlined, size: 18),
          label: Text(
            _pickedLat != null
                ? 'Đã ghim vị trí trên bản đồ'
                : 'Ghim vị trí trên bản đồ (chính xác hơn)',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                _pickedLat != null ? Colors.green[700] : AppColors.primaryRed,
            minimumSize: const Size.fromHeight(46),
          ),
          onPressed: () async {
            final result = await Navigator.of(context).push<MapPickResult>(
              MaterialPageRoute(
                builder: (_) => MapPickerScreen(
                  initialLat: _pickedLat,
                  initialLng: _pickedLng,
                  title: 'Ghim vị trí của bạn',
                ),
              ),
            );
            if (result != null) {
              setState(() {
                _pickedLat = result.latLng.latitude;
                _pickedLng = result.latLng.longitude;
                if (result.address != null) {
                  _addressController.text = result.address!;
                }
                if (result.district != null) {
                  _districtController.text = result.district!;
                }
                if (result.province != null) {
                  _provinceController.text = result.province!;
                }
              });
            }
          },
        ),
        if (_pickedLat != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              '${_pickedLat!.toStringAsFixed(5)}, ${_pickedLng!.toStringAsFixed(5)}',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey),
            ),
          ),
        const SizedBox(height: 20),
        _buildFieldLabel('Quận / Huyện'),
        AuthTextField(
          controller: _districtController,
          hintText: 'Nhập quận/huyện',
          icon: Icons.map_outlined,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Tỉnh / Thành phố'),
        AuthTextField(
          controller: _provinceController,
          hintText: 'Nhập tỉnh/thành phố',
          icon: Icons.location_city_outlined,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Nghề nghiệp'),
        AuthTextField(
          controller: _occupationController,
          hintText: 'Nhập nghề nghiệp',
          icon: Icons.work_outline_rounded,
          keyboardType: TextInputType.text,
        ),

        const SizedBox(height: 28),
        _buildSectionLabel('Sở thích chơi bóng'),
        _buildFieldLabel('Loại sân yêu thích'),
        _buildDropdown<String>(
          icon: Icons.sports_soccer_rounded,
          value: _preferredPitchType,
          hint: 'Chọn loại sân',
          items: const [
            DropdownMenuItem(value: 'FIVE_A_SIDE', child: Text('Sân 5')),
            DropdownMenuItem(value: 'SEVEN_A_SIDE', child: Text('Sân 7')),
            DropdownMenuItem(value: 'ELEVEN_A_SIDE', child: Text('Sân 11')),
          ],
          onChanged: (v) => setState(() => _preferredPitchType = v),
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Khung giờ chơi'),
        _buildDropdown<String>(
          icon: Icons.access_time_rounded,
          value: _preferredPlayTime,
          hint: 'Chọn khung giờ',
          items: const [
            DropdownMenuItem(value: 'MORNING',   child: Text('Sáng')),
            DropdownMenuItem(value: 'AFTERNOON', child: Text('Chiều')),
            DropdownMenuItem(value: 'EVENING',   child: Text('Tối')),
            DropdownMenuItem(value: 'NIGHT',     child: Text('Đêm')),
          ],
          onChanged: (v) => setState(() => _preferredPlayTime = v),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      ),
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

  Widget _buildDropdown<T>({
    required IconData icon,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textGrey, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isExpanded: true,
                value: value,
                hint: Text(
                  hint,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
                items: items,
                onChanged: onChanged,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required IconData icon,
    required String text,
    bool isPlaceholder = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textGrey, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isPlaceholder ? AppColors.textGrey : AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textGrey),
        ],
      ),
    );
  }
}
