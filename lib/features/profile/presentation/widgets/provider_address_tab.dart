import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/domain/entities/user_entity.dart';
import '../cubit/provider_cubit.dart';
import '../../domain/entities/provider_address_entity.dart';
import '../../../../core/location/map_picker_screen.dart';

class ProviderAddressTab extends StatelessWidget {
  final UserEntity user;

  const ProviderAddressTab({super.key, required this.user});

  void _showAddressDialog(BuildContext context, {ProviderAddressEntity? address}) {
    final providerCubit = context.read<ProviderCubit>();
    final state = providerCubit.state;
    if (state is! ProviderLoaded) return;

    showDialog(
      context: context,
      builder: (dialogContext) => _AddressDialog(
        cubit: providerCubit,
        providerId: state.provider.providerId,
        address: address,
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

/// Dialog thêm/sửa khu vực: Autocomplete cho chọn khu vực CÓ SẴN (auto-gom cùng tên)
/// hoặc gõ khu vực mới. Toạ độ do BE geocode.
class _AddressDialog extends StatefulWidget {
  final ProviderCubit cubit;
  final String providerId;
  final ProviderAddressEntity? address;

  const _AddressDialog({
    required this.cubit,
    required this.providerId,
    this.address,
  });

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  List<String> _areas = [];
  bool _loading = true;
  TextEditingController? _fieldController;
  // Toạ độ từ map pick (nếu có) → gửi kèm để BE tin toạ độ thật, khỏi geocode.
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    widget.cubit.fetchAreas().then((list) {
      if (!mounted) return;
      setState(() {
        _areas = list;
        _loading = false;
      });
    });
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.push<MapPickResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: _lat,
          initialLng: _lng,
          title: 'Chọn khu vực trên bản đồ',
        ),
      ),
    );
    if (result == null || !mounted) return;
    // Ưu tiên "quận, tỉnh" cho đồng nhất (auto-gom); fallback display_name.
    final composed = (result.district != null && result.province != null)
        ? '${result.district}, ${result.province}'
        : (result.address ?? '');
    setState(() {
      _lat = result.latLng.latitude;
      _lng = result.latLng.longitude;
      _fieldController?.text = composed;
    });
  }

  void _save() {
    final value = _fieldController?.text.trim() ?? '';
    if (value.isEmpty) return;
    if (widget.address == null) {
      widget.cubit.addAddress(widget.providerId, value,
          latitude: _lat, longitude: _lng);
    } else {
      widget.cubit.updateAddress(widget.address!.providerAddressId, value,
          latitude: _lat, longitude: _lng);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.address == null ? 'Thêm khu vực' : 'Sửa khu vực',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Autocomplete<String>(
            initialValue:
                TextEditingValue(text: widget.address?.address ?? ''),
            optionsBuilder: (textValue) {
              final q = textValue.text.trim().toLowerCase();
              if (q.isEmpty) return _areas;
              return _areas.where((a) => a.toLowerCase().contains(q));
            },
            fieldViewBuilder: (ctx, controller, focusNode, onSubmit) {
              _fieldController = controller;
              return TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Chọn khu vực có sẵn hoặc nhập mới',
                  border: const OutlineInputBorder(),
                  suffixIcon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.arrow_drop_down),
                ),
                onSubmitted: (_) => onSubmit(),
                onChanged: (_) {
                  // User tự gõ → bỏ toạ độ map cũ (để BE geocode/gom theo tên mới).
                  if (_lat != null || _lng != null) {
                    setState(() {
                      _lat = null;
                      _lng = null;
                    });
                  }
                },
              );
            },
            optionsViewBuilder: (ctx, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220, maxWidth: 280),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: options
                          .map((o) => ListTile(
                                dense: true,
                                title: Text(o, style: GoogleFonts.inter(fontSize: 14)),
                                onTap: () => onSelected(o),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _pickOnMap,
              icon: Icon(
                _lat != null ? Icons.check_circle : Icons.map_outlined,
                size: 18,
                color: _lat != null ? Colors.green : AppColors.primaryRed,
              ),
              label: Text(
                _lat != null ? 'Đã chọn vị trí trên bản đồ' : 'Chọn vị trí trên bản đồ',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chọn khu vực đã có để gom chung toạ độ; hoặc chọn vị trí trên bản đồ cho khu vực mới '
            '(toạ độ thật, chống địa chỉ ảo). Có thể gõ tay kèm tỉnh, vd "Thủ Đức, TP. Hồ Chí Minh".',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: AppColors.textGrey)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
          child: const Text('Lưu', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
