import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/error_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../pitch/data/datasources/booking_remote_datasource.dart';

/// Sheet cho chủ sân khóa lịch thủ công 1 hoặc nhiều slot (bảo trì / đặt ngoài app).
/// Slot 1..15 → 06:00..21:00 (slot n bắt đầu lúc (5+n):00), khớp BE.
class BlockSlotSheet extends StatefulWidget {
  final String pitchId;
  final String pitchName;

  /// Gọi khi khóa thành công (để tab gọi reload nếu cần).
  final VoidCallback? onBlocked;

  const BlockSlotSheet({
    super.key,
    required this.pitchId,
    required this.pitchName,
    this.onBlocked,
  });

  static Future<void> show(
    BuildContext context, {
    required String pitchId,
    required String pitchName,
    VoidCallback? onBlocked,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlockSlotSheet(
        pitchId: pitchId,
        pitchName: pitchName,
        onBlocked: onBlocked,
      ),
    );
  }

  @override
  State<BlockSlotSheet> createState() => _BlockSlotSheetState();
}

class _BlockSlotSheetState extends State<BlockSlotSheet> {
  static const int _slotCount = 15; // 1..15 → 06:00..21:00

  late final BookingRemoteDataSource _ds;
  DateTime _date = DateTime.now();
  final Set<int> _selected = {};
  final Set<int> _booked = {};
  String _blockType = 'MAINTENANCE';
  final _notesController = TextEditingController();
  bool _loadingSlots = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _ds = BookingRemoteDataSource(dioClient: context.read<DioClient>());
    _loadBooked();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _slotLabel(int n) {
    final start = (5 + n).toString().padLeft(2, '0');
    final end = (6 + n).toString().padLeft(2, '0');
    return '$start:00 - $end:00';
  }

  /// Slot đã qua giờ (chỉ tính khi ngày khóa là hôm nay).
  bool _isPastSlot(int slot) {
    final now = DateTime.now();
    final isToday =
        _date.year == now.year && _date.month == now.month && _date.day == now.day;
    if (!isToday) return false;
    final slotStart = DateTime(_date.year, _date.month, _date.day, 5 + slot, 0);
    return slotStart.isBefore(now);
  }

  Future<void> _loadBooked() async {
    setState(() => _loadingSlots = true);
    try {
      final booked = await _ds.getBookedSlots(widget.pitchId, _dateStr(_date));
      if (!mounted) return;
      setState(() {
        _booked
          ..clear()
          ..addAll(booked);
      });
    } catch (_) {
      // bỏ qua — vẫn cho chọn, BE sẽ chặn nếu trùng
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'Chọn ngày khóa lịch',
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _selected.clear();
    });
    _loadBooked();
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ít nhất 1 khung giờ để khóa')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _ds.blockSlots(
        pitchId: widget.pitchId,
        bookingDate: _dateStr(_date),
        slots: _selected.toList()..sort(),
        blockType: _blockType,
        providerNotes: _notesController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onBlocked?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã khóa lịch thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể khóa lịch: ${messageFromError(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = _blockType == 'OFFLINE_BOOKING';
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Khóa lịch sân',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(widget.pitchName,
                style:
                    GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey)),
            const SizedBox(height: 18),

            // Ngày
            _label('Ngày'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.primaryRed),
                    const SizedBox(width: 10),
                    Text(_dateStr(_date),
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textGrey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Loại khóa
            _label('Lý do khóa'),
            const SizedBox(height: 8),
            Row(
              children: [
                _typeChip('Bảo trì', 'MAINTENANCE', Icons.build_rounded),
                const SizedBox(width: 10),
                _typeChip('Đặt ngoài app', 'OFFLINE_BOOKING',
                    Icons.phone_in_talk_rounded),
              ],
            ),
            const SizedBox(height: 18),

            // Khung giờ
            Row(
              children: [
                _label('Khung giờ'),
                const SizedBox(width: 8),
                if (_loadingSlots)
                  const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_slotCount, (i) {
                final slot = i + 1;
                final booked = _booked.contains(slot);
                final past = _isPastSlot(slot);
                final disabled = booked || past;
                final selected = _selected.contains(slot);
                return GestureDetector(
                  onTap: disabled
                      ? null
                      : () => setState(() {
                            if (selected) {
                              _selected.remove(slot);
                            } else {
                              _selected.add(slot);
                            }
                          }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: disabled
                          ? const Color(0xFFF0F0F0)
                          : selected
                              ? AppColors.primaryRed
                              : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: disabled
                            ? const Color(0xFFE0E0E0)
                            : selected
                                ? AppColors.primaryRed
                                : const Color(0xFFDDDDDD),
                      ),
                    ),
                    child: Text(
                      _slotLabel(slot),
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: disabled
                            ? const Color(0xFFBBBBBB)
                            : selected
                                ? Colors.white
                                : AppColors.textDark,
                        decoration:
                            disabled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),

            // Ghi chú
            _label(isOffline ? 'Ghi chú khách đặt (tuỳ chọn)' : 'Ghi chú (tuỳ chọn)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: isOffline
                    ? 'Tên khách, SĐT, tiền cọc...'
                    : 'Lý do bảo trì (đèn, cỏ, ngập...)',
                hintStyle:
                    GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
                filled: true,
                fillColor: const Color(0xFFF9F9F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Khóa lịch',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey));

  Widget _typeChip(String label, String value, IconData icon) {
    final selected = _blockType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _blockType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryRed.withValues(alpha: 0.10)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    selected ? AppColors.primaryRed : const Color(0xFFDDDDDD)),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? AppColors.primaryRed : AppColors.textGrey),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? AppColors.primaryRed : AppColors.textDark)),
            ],
          ),
        ),
      ),
    );
  }
}
