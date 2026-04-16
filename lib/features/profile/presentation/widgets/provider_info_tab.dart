import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/domain/entities/user_entity.dart';
import '../cubit/provider_cubit.dart';

class ProviderInfoTab extends StatefulWidget {
  final UserEntity user;

  const ProviderInfoTab({super.key, required this.user});

  @override
  State<ProviderInfoTab> createState() => _ProviderInfoTabState();
}

class _ProviderInfoTabState extends State<ProviderInfoTab> {
  final _cardNumberController = TextEditingController();
  final _bankController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProviderCubit, ProviderState>(
      listener: (context, state) {
        if (state is ProviderLoaded) {
          _cardNumberController.text = state.provider.cardNumber ?? '';
          _bankController.text = state.provider.bank ?? '';
        }
        if (state is ProviderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is ProviderLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
        }

        if (state is ProviderLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin ngân hàng',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cung cấp thông tin tài khoản để nhận thanh toán từ hệ thống.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  label: 'Số tài khoản',
                  controller: _cardNumberController,
                  icon: Icons.credit_card_rounded,
                  hint: 'Nhập số tài khoản ngân hàng',
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Tên ngân hàng',
                  controller: _bankController,
                  icon: Icons.account_balance_rounded,
                  hint: 'Ví dụ: Vietcombank, MB Bank...',
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<ProviderCubit>().updateProviderInfo(
                            state.provider.providerId,
                            _cardNumberController.text,
                            _bankController.text,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cập nhật thông tin thành công'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Lưu thay đổi',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const Center(child: Text('Không thể tải thông tin đối tác'));
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primaryRed, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFF9F9F9),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
