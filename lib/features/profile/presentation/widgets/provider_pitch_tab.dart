import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/domain/entities/user_entity.dart';
import '../../../../features/auth/domain/repositories/auth_repository.dart';
import '../../../../features/pitch/domain/entities/pitch_entity.dart';
import '../../../../features/pitch/domain/repositories/pitch_repository.dart';
import '../cubit/provider_cubit.dart';
import '../cubit/pitch_management_cubit.dart';
import '../../domain/entities/provider_address_entity.dart';
import 'pitch_reviews_sheet.dart';

class ProviderPitchTab extends StatefulWidget {
  final UserEntity user;

  const ProviderPitchTab({super.key, required this.user});

  @override
  State<ProviderPitchTab> createState() => _ProviderPitchTabState();
}

class _ProviderPitchTabState extends State<ProviderPitchTab> {
  ProviderAddressEntity? _selectedAddress;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(_selectedAddress?.providerAddressId ?? 'none'),
      create: (context) {
        final cubit = PitchManagementCubit(
          repository: context.read<PitchRepository>(),
        );
        if (_selectedAddress != null) {
          cubit.loadPitches(_selectedAddress!.providerAddressId);
        }
        return cubit;
      },
      child: BlocBuilder<ProviderCubit, ProviderState>(
        builder: (context, providerState) {
          if (providerState is! ProviderLoaded) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
          }

          final addresses = providerState.addresses;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn khu vực',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textGrey),
                ),
                const SizedBox(height: 8),
                _buildAddressDropdown(addresses),
                const SizedBox(height: 24),
                if (_selectedAddress != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Danh sách sân',
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          ),
                          if (widget.user.role != 'ADMIN')
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '* Liên hệ Admin để xóa sân bãi.',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.primaryRed.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryRed),
                        onPressed: () => _showPitchDialog(context, _selectedAddress!.providerAddressId),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: BlocListener<PitchManagementCubit, PitchManagementState>(
                      listener: (context, state) {
                        if (state is PitchManagementError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
                          );
                        } else if (state is PitchManagementLoaded && state.message != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message!), backgroundColor: Colors.green),
                          );
                          context.read<PitchManagementCubit>().clearMessage();
                        }
                      },
                      child: BlocBuilder<PitchManagementCubit, PitchManagementState>(
                        builder: (context, pitchState) {
                          if (pitchState is PitchManagementLoading || pitchState is PitchManagementInitial) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
                          }
                        if (pitchState is PitchManagementLoaded) {
                          if (pitchState.pitches.isEmpty) {
                            return Center(
                              child: Text('Chưa có sân nào trong khu vực này.', style: GoogleFonts.inter(color: AppColors.textGrey)),
                            );
                          }
                          return ListView.separated(
                            itemCount: pitchState.pitches.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final pitch = pitchState.pitches[index];
                              return _buildPitchCard(context, pitch);
                            },
                          );
                        }
                        return const Center(child: Text('Lỗi tải danh sách sân'));
                      },
                    ),
                  ),
                ),
              ] else
                Expanded(
                    child: Center(
                      child: Text(
                        'Vui lòng chọn hoặc thêm khu vực\ntại tab "Khu vực" trước.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppColors.textGrey),
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

  Widget _buildAddressDropdown(List<ProviderAddressEntity> addresses) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProviderAddressEntity>(
          value: _selectedAddress,
          isExpanded: true,
          hint: Text('Chọn khu vực để quản lý sân', style: GoogleFonts.inter(fontSize: 14)),
          items: addresses.map((addr) {
            return DropdownMenuItem(
              value: addr,
              child: Text(addr.address, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedAddress = val;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPitchCard(BuildContext context, PitchEntity pitch) {
    final cubit = context.read<PitchManagementCubit>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: pitch.imageUrls.isNotEmpty
                ? Image.network(pitch.imageUrls.first, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildPlaceholder())
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pitch.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text('${pitch.displayType} • ${pitch.price.toStringAsFixed(0)}đ', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey)),
                const SizedBox(height: 4),
                Text(pitch.environment == 'OUTDOOR' ? 'Ngoài trời' : 'Trong nhà', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primaryRed, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.star_outline_rounded, size: 20, color: Color(0xFFFFC107)),
                tooltip: 'Xem đánh giá',
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => PitchReviewsSheet(
                    pitchId: pitch.pitchId,
                    pitchName: pitch.name,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textGrey),
                onPressed: () => _showPitchDialog(context, _selectedAddress!.providerAddressId, pitch: pitch),
              ),
              if (widget.user.role == 'ADMIN')
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                  onPressed: () => _showDeletePitchDialog(context, pitch, _selectedAddress!.providerAddressId),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80, height: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }

  void _showPitchDialog(BuildContext context, String addressId, {PitchEntity? pitch}) {
    final nameController = TextEditingController(text: pitch?.name ?? '');
    final priceController = TextEditingController(text: pitch?.price.toStringAsFixed(0) ?? '');
    final descController = TextEditingController(text: pitch?.description ?? '');
    String type = pitch?.type ?? 'FIVE_A_SIDE';
    String environment = pitch?.environment ?? 'OUTDOOR';
    
    List<String> existingUrls = List.from(pitch?.imageUrls ?? []);
    List<File> selectedFiles = [];
    bool isUploading = false;

    final cubit = context.read<PitchManagementCubit>();
    final authRepo = context.read<AuthRepository>();
    final picker = ImagePicker();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(pitch == null ? 'Thêm sân mới' : 'Cập nhật sân', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên sân')),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Loại sân'),
                  items: const [
                    DropdownMenuItem(value: 'FIVE_A_SIDE', child: Text('Sân 5')),
                    DropdownMenuItem(value: 'SEVEN_A_SIDE', child: Text('Sân 7')),
                    DropdownMenuItem(value: 'ELEVEN_A_SIDE', child: Text('Sân 11')),
                  ],
                  onChanged: (v) => setDialogState(() => type = v!),
                ),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Giá (VNĐ)'), keyboardType: TextInputType.number),
                DropdownButtonFormField<String>(
                  initialValue: environment,
                  decoration: const InputDecoration(labelText: 'Môi trường'),
                  items: const [
                    DropdownMenuItem(value: 'OUTDOOR', child: Text('Ngoài trời')),
                    DropdownMenuItem(value: 'INDOOR', child: Text('Trong nhà')),
                  ],
                  onChanged: (v) => setDialogState(() => environment = v!),
                ),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Mô tả'), maxLines: 3),
                const SizedBox(height: 20),
                Text('Ảnh sân bãi', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textGrey)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Nút thêm ảnh
                      GestureDetector(
                        onTap: isUploading ? null : () async {
                          final images = await picker.pickMultiImage(imageQuality: 80);
                          if (images.isNotEmpty) {
                            setDialogState(() {
                              selectedFiles.addAll(images.map((e) => File(e.path)));
                            });
                          }
                        },
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primaryRed.withOpacity(0.3), width: 1.5, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryRed, size: 28),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Hiển thị ảnh cũ (remote)
                      ...existingUrls.map((url) => _buildImageThumbnail(
                        url: url,
                        onRemove: () => setDialogState(() => existingUrls.remove(url)),
                      )),
                      // Hiển thị ảnh mới chọn (local)
                      ...selectedFiles.map((file) => _buildImageThumbnail(
                        file: file,
                        onRemove: () => setDialogState(() => selectedFiles.remove(file)),
                      )),
                    ],
                  ),
                ),
                if (isUploading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(color: AppColors.primaryRed, backgroundColor: Color(0xFFEEEEEE)),
                  const SizedBox(height: 4),
                  Center(child: Text('Đang tải ảnh lên...', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey))),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isUploading ? null : () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên sân')));
                  return;
                }

                setDialogState(() => isUploading = true);
                
                try {
                  List<String> finalUrls = List.from(existingUrls);
                  if (selectedFiles.isNotEmpty) {
                    final newUrls = await authRepo.uploadMultipleImages(selectedFiles.map((e) => e.path).toList());
                    finalUrls.addAll(newUrls);
                  }

                  final data = {
                    'providerAddressId': addressId,
                    'name': nameController.text,
                    'type': type,
                    'price': double.tryParse(priceController.text) ?? 0,
                    'description': descController.text,
                    'environment': environment,
                    'imageUrls': finalUrls,
                  };

                  if (pitch == null) {
                    await cubit.createPitch(data, addressId);
                  } else {
                    await cubit.updatePitch(pitch.pitchId, data, addressId);
                  }
                  
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  setDialogState(() => isUploading = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeletePitchDialog(BuildContext context, PitchEntity pitch, String addressId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Xác nhận xóa', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc chắn muốn xóa sân bãi "${pitch.name}"? Hành động này không thể hoàn tác.', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textGrey)),
          ),
          TextButton(
            onPressed: () {
              context.read<PitchManagementCubit>().deletePitch(pitch.pitchId, addressId);
              Navigator.pop(dialogContext);
            },
            child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail({String? url, File? file, required VoidCallback onRemove}) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 80, height: 80,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: url != null 
              ? Image.network(url, width: 80, height: 80, fit: BoxFit.cover)
              : Image.file(file!, width: 80, height: 80, fit: BoxFit.cover),
          ),
          Positioned(
            top: 2, right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
