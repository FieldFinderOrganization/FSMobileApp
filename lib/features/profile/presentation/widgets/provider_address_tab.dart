import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/domain/entities/user_entity.dart';
import '../cubit/provider_cubit.dart';
import '../../domain/entities/provider_address_entity.dart';

class ProviderAddressTab extends StatelessWidget {
  final UserEntity user;

  const ProviderAddressTab({super.key, required this.user});

  void _showAddressDialog(BuildContext context, {ProviderAddressEntity? address}) {
    final controller = TextEditingController(text: address?.address ?? '');
    final providerCubit = context.read<ProviderCubit>();
    final state = providerCubit.state;

    if (state is! ProviderLoaded) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          address == null ? 'Thêm khu vực' : 'Sửa khu vực',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhập địa chỉ khu vực',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              if (address == null) {
                providerCubit.addAddress(state.provider.providerId, controller.text.trim());
              } else {
                providerCubit.updateAddress(address.providerAddressId, controller.text.trim());
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ProviderAddressEntity address) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Xác nhận xóa', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc chắn muốn xóa khu vực "${address.address}"? Hành động này không thể hoàn tác.', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textGrey)),
          ),
          TextButton(
            onPressed: () {
              context.read<ProviderCubit>().deleteAddress(address.providerAddressId);
              Navigator.pop(dialogContext);
            },
            child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProviderCubit, ProviderState>(
      listener: (context, state) {
        if (state is ProviderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
          );
        } else if (state is ProviderLoaded && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!), backgroundColor: Colors.green),
          );
          context.read<ProviderCubit>().clearMessage();
        }
      },
      child: BlocBuilder<ProviderCubit, ProviderState>(
        builder: (context, state) {
          if (state is ProviderLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
        }

        if (state is ProviderLoaded) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quản lý khu vực',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryRed),
                      onPressed: () => _showAddressDialog(context),
                    ),
                  ],
                ),
                Text(
                  'Mỗi khu vực có thể chứa nhiều sân bãi khác nhau.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
                ),
                if (user.role != 'ADMIN')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '* Để xóa khu vực, vui lòng liên hệ Admin.',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.primaryRed.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 20),
                Expanded(
                  child: state.addresses.isEmpty
                      ? Center(
                          child: Text(
                            'Chưa có khu vực nào.\nNhấn nút (+) để thêm.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: AppColors.textGrey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: state.addresses.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final addr = state.addresses[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFEEEEEE)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: AppColors.primaryRed),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      addr.address,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textGrey),
                                    onPressed: () => _showAddressDialog(context, address: addr),
                                  ),
                                  if (user.role == 'ADMIN')
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                      onPressed: () => _showDeleteDialog(context, addr),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        }

          if (state is ProviderError && state.message.contains('Không thể tải danh sách')) {
            return const Center(child: Text('Không thể tải danh sách khu vực'));
          }

          return const SizedBox();
        },
      ),
    );
  }
}
