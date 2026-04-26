import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/admin_discount_entity.dart';
import '../cubit/admin_discount_cubit.dart';

class AdminDiscountFormScreen extends StatefulWidget {
  final AdminDiscountEntity? discount;

  const AdminDiscountFormScreen({super.key, this.discount});

  @override
  State<AdminDiscountFormScreen> createState() =>
      _AdminDiscountFormScreenState();
}

class _AdminDiscountFormScreenState extends State<AdminDiscountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _valueCtrl;
  late TextEditingController _minOrderCtrl;
  late TextEditingController _maxDiscountCtrl;
  late TextEditingController _quantityCtrl;

  String _discountType = 'PERCENTAGE';
  String _scope = 'GLOBAL';
  String _status = 'ACTIVE';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  bool get _isEdit => widget.discount != null;

  @override
  void initState() {
    super.initState();
    final d = widget.discount;
    _codeCtrl = TextEditingController(text: d?.code ?? '');
    _descCtrl = TextEditingController(text: d?.description ?? '');
    _valueCtrl = TextEditingController(text: d?.value.toStringAsFixed(0) ?? '');
    _minOrderCtrl = TextEditingController(
        text: d?.minOrderValue?.toStringAsFixed(0) ?? '');
    _maxDiscountCtrl = TextEditingController(
        text: d?.maxDiscountAmount?.toStringAsFixed(0) ?? '');
    _quantityCtrl =
        TextEditingController(text: d?.quantity.toString() ?? '1');
    if (d != null) {
      _discountType = d.discountType;
      _scope = d.scope;
      _status = d.status;
      _startDate = d.startDate;
      _endDate = d.endDate;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    _minOrderCtrl.dispose();
    _maxDiscountCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryRed, surface: Color(0xFF1A1A2E)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final body = {
      'code': _codeCtrl.text.trim().toUpperCase(),
      'description': _descCtrl.text.trim(),
      'discountType': _discountType,
      'value': double.tryParse(_valueCtrl.text.trim()) ?? 0,
      'minOrderValue': _minOrderCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_minOrderCtrl.text.trim()),
      'maxDiscountAmount': _maxDiscountCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_maxDiscountCtrl.text.trim()),
      'scope': _scope,
      'quantity': int.tryParse(_quantityCtrl.text.trim()) ?? 1,
      'startDate': _startDate.toIso8601String().substring(0, 10),
      'endDate': _endDate.toIso8601String().substring(0, 10),
      'status': _status,
    };
    final cubit = context.read<AdminDiscountCubit>();
    if (_isEdit) {
      await cubit.updateDiscount(widget.discount!.id, body);
    } else {
      await cubit.createDiscount(body);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    String dateFmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEdit ? 'Sửa mã khuyến mãi' : 'Tạo mã khuyến mãi',
            style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 17)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(
              title: 'Thông tin cơ bản',
              children: [
                _Field(
                  label: 'Mã code',
                  controller: _codeCtrl,
                  hint: 'VD: SUMMER2025',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Bắt buộc' : null,
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Mô tả',
                  controller: _descCtrl,
                  hint: 'Giảm 20% cho toàn bộ đơn hàng...',
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Loại & Giá trị',
              children: [
                _SegmentedRow(
                  label: 'Loại giảm',
                  options: const ['PERCENTAGE', 'FIXED_AMOUNT'],
                  labels: const ['Theo %', 'Cố định (đ)'],
                  selected: _discountType,
                  onChanged: (v) => setState(() => _discountType = v),
                ),
                const SizedBox(height: 12),
                _Field(
                  label: _discountType == 'PERCENTAGE'
                      ? 'Giá trị (%)'
                      : 'Giá trị (đ)',
                  controller: _valueCtrl,
                  hint: _discountType == 'PERCENTAGE' ? '20' : '50000',
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Bắt buộc' : null,
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Đơn tối thiểu (đ, để trống nếu không có)',
                  controller: _minOrderCtrl,
                  hint: '100000',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Giảm tối đa (đ, để trống nếu không giới hạn)',
                  controller: _maxDiscountCtrl,
                  hint: '200000',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Phạm vi & Số lượng',
              children: [
                _SegmentedRow(
                  label: 'Phạm vi',
                  options: const ['GLOBAL', 'CATEGORY', 'SPECIFIC_PRODUCT'],
                  labels: const ['Toàn bộ', 'Danh mục', 'Sản phẩm'],
                  selected: _scope,
                  onChanged: (v) => setState(() => _scope = v),
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Số lượng',
                  controller: _quantityCtrl,
                  hint: '100',
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Bắt buộc' : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Thời gian & Trạng thái',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DateTile(
                        label: 'Ngày bắt đầu',
                        value: dateFmt(_startDate),
                        onTap: () => _pickDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateTile(
                        label: 'Ngày kết thúc',
                        value: dateFmt(_endDate),
                        onTap: () => _pickDate(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SegmentedRow(
                  label: 'Trạng thái',
                  options: const ['ACTIVE', 'INACTIVE'],
                  labels: const ['Hoạt động', 'Tắt'],
                  selected: _status,
                  onChanged: (v) => setState(() => _status = v),
                ),
              ],
            ),
            const SizedBox(height: 28),
            BlocBuilder<AdminDiscountCubit, AdminDiscountState>(
              builder: (context, state) {
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: state.status == AdminDiscountStatus.loading
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: state.status == AdminDiscountStatus.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _isEdit ? 'Cập nhật' : 'Tạo mã',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF0F0F1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF2A2A4A)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF2A2A4A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.primaryRed),
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _SegmentedRow extends StatelessWidget {
  final String label;
  final List<String> options;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SegmentedRow({
    required this.label,
    required this.options,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: options.asMap().entries.map((e) {
            final isSelected = e.value == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(e.value),
                child: Container(
                  margin: EdgeInsets.only(
                      right: e.key < options.length - 1 ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryRed
                        : const Color(0xFF0F0F1E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isSelected
                            ? AppColors.primaryRed
                            : const Color(0xFF2A2A4A)),
                  ),
                  child: Text(
                    labels[e.key],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color:
                            isSelected ? Colors.white : Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTile(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    color: Colors.grey[500], fontSize: 10)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.primaryRed),
                const SizedBox(width: 6),
                Text(value,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
