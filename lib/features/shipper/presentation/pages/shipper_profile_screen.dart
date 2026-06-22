import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/login/presentation/bloc/auth_cubit.dart';
import '../../../profile/presentation/pages/change_password_screen.dart';
import '../../data/shipper_remote_data_source.dart';

/// Tab "Hồ sơ" của shipper: online toggle, thông tin xe, sửa info, đổi mk, logout.
class ShipperProfileScreen extends StatefulWidget {
  final UserEntity user;
  final bool online;
  final ValueChanged<bool> onOnlineChanged;
  const ShipperProfileScreen({
    super.key,
    required this.user,
    required this.online,
    required this.onOnlineChanged,
  });

  @override
  State<ShipperProfileScreen> createState() => _ShipperProfileScreenState();
}

class _ShipperProfileScreenState extends State<ShipperProfileScreen> {
  late final ShipperRemoteDataSource _ds;

  late bool _online;
  late String _name;
  String? _phone;
  String? _vehicleType;
  String? _vehiclePlate;
  bool _savingOnline = false;

  @override
  void initState() {
    super.initState();
    _ds = ShipperRemoteDataSource(dioClient: context.read<DioClient>());
    _online = widget.online;
    _name = widget.user.name;
    _phone = widget.user.phone;
    _vehicleType = widget.user.vehicleType;
    _vehiclePlate = widget.user.vehiclePlate;
  }

  Future<void> _toggleOnline(bool v) async {
    setState(() => _savingOnline = true);
    try {
      await _ds.updateProfile(widget.user.userId, {'available': v});
      if (!mounted) return;
      setState(() {
        _online = v;
        _savingOnline = false;
      });
      widget.onOnlineChanged(v);
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingOnline = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đổi trạng thái thất bại: ${messageFromError(e)}')),
      );
    }
  }

  Future<void> _editInfo() async {
    final nameCtrl = TextEditingController(text: _name);
    final phoneCtrl = TextEditingController(text: _phone ?? '');
    final typeCtrl = TextEditingController(text: _vehicleType ?? '');
    final plateCtrl = TextEditingController(text: _vehiclePlate ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sửa thông tin',
                      style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _field(nameCtrl, 'Họ tên',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null),
                  _field(phoneCtrl, 'Số điện thoại',
                      keyboard: TextInputType.phone),
                  _field(typeCtrl, 'Loại xe (vd Xe máy)'),
                  _field(plateCtrl, 'Biển số xe'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheet(() => saving = true);
                              try {
                                await _ds.updateProfile(widget.user.userId, {
                                  'name': nameCtrl.text.trim(),
                                  'phone': phoneCtrl.text.trim(),
                                  'vehicleType': typeCtrl.text.trim(),
                                  'vehiclePlate': plateCtrl.text.trim(),
                                });
                                if (ctx.mounted) Navigator.pop(ctx, true);
                              } catch (e) {
                                setSheet(() => saving = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Lưu thất bại: ${messageFromError(e)}')),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Lưu',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (saved == true && mounted) {
      setState(() {
        _name = nameCtrl.text.trim();
        _phone = phoneCtrl.text.trim();
        _vehicleType = typeCtrl.text.trim();
        _vehiclePlate = plateCtrl.text.trim();
      });
    }
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboard, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        title: Text('Hồ sơ',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFEEEEEE),
                backgroundImage: (u.imageUrl != null && u.imageUrl!.isNotEmpty)
                    ? NetworkImage(u.imageUrl!)
                    : null,
                child: (u.imageUrl == null || u.imageUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 32, color: AppColors.textGrey)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name,
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('Shipper · ${u.email}',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textGrey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Online toggle
          _card(
            child: SwitchListTile(
              value: _online,
              onChanged: _savingOnline ? null : _toggleOnline,
              activeTrackColor: Colors.green,
              contentPadding: EdgeInsets.zero,
              title: Text('Trạng thái nhận đơn',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              subtitle: Text(
                _savingOnline
                    ? 'Đang cập nhật…'
                    : (_online ? 'Online — đang nhận đơn' : 'Offline'),
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _online ? Colors.green : AppColors.textGrey),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Thông tin
          _card(
            child: Column(
              children: [
                _infoRow(Icons.phone_outlined, 'SĐT', _phone ?? '—'),
                const Divider(height: 16),
                _infoRow(Icons.two_wheeler_outlined, 'Loại xe',
                    _vehicleType?.isNotEmpty == true ? _vehicleType! : '—'),
                const Divider(height: 16),
                _infoRow(Icons.confirmation_number_outlined, 'Biển số',
                    _vehiclePlate?.isNotEmpty == true ? _vehiclePlate! : '—'),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _editInfo,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Sửa'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Actions
          _card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: Text('Đổi mật khẩu', style: GoogleFonts.inter()),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen()),
                  ),
                ),
                const Divider(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.logout_rounded, color: AppColors.primaryRed),
                  title: Text('Đăng xuất',
                      style: GoogleFonts.inter(color: AppColors.primaryRed)),
                  onTap: () => context.read<AuthCubit>().logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: child,
      );

  Widget _infoRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textGrey),
          const SizedBox(width: 10),
          Text(label,
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      );
}
