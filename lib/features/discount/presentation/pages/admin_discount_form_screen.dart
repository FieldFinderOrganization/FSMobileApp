import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/admin_discount_entity.dart';
import '../cubit/admin_discount_cubit.dart';
import '../../../product/domain/repositories/product_repository.dart';
import '../../../home/domain/entities/category_entity.dart';
import '../../../product/domain/entities/product_entity.dart';

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

  List<int> _selectedProductIds = [];
  List<int> _selectedCategoryIds = [];

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
      _selectedProductIds = List.from(d.applicableProductIds);
      _selectedCategoryIds = List.from(d.applicableCategoryIds);
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
    if (_scope == 'SPECIFIC_PRODUCT' && _selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 sản phẩm',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_scope == 'CATEGORY' && _selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 danh mục',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
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
      'applicableProductIds':
          _scope == 'SPECIFIC_PRODUCT' ? _selectedProductIds : [],
      'applicableCategoryIds':
          _scope == 'CATEGORY' ? _selectedCategoryIds : [],
    };
    final cubit = context.read<AdminDiscountCubit>();
    if (_isEdit) {
      await cubit.updateDiscount(widget.discount!.id, body);
    } else {
      await cubit.createDiscount(body);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _openProductPicker() async {
    final repo = context.read<ProductRepository>();
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductPickerSheet(
        repo: repo,
        initialSelected: List.from(_selectedProductIds),
      ),
    );
    if (result != null) {
      setState(() => _selectedProductIds = result);
    }
  }

  Future<void> _openCategoryPicker() async {
    final repo = context.read<ProductRepository>();
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryPickerSheet(
        repo: repo,
        initialSelected: List.from(_selectedCategoryIds),
      ),
    );
    if (result != null) {
      setState(() => _selectedCategoryIds = result);
    }
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
                  onChanged: (v) => setState(() {
                    _scope = v;
                    _selectedProductIds = [];
                    _selectedCategoryIds = [];
                  }),
                ),
                if (_scope == 'SPECIFIC_PRODUCT') ...[
                  const SizedBox(height: 12),
                  _PickerTile(
                    label: 'Sản phẩm áp dụng',
                    count: _selectedProductIds.length,
                    hint: 'Chọn sản phẩm',
                    onTap: () => _openProductPicker(),
                  ),
                ],
                if (_scope == 'CATEGORY') ...[
                  const SizedBox(height: 12),
                  _PickerTile(
                    label: 'Danh mục áp dụng',
                    count: _selectedCategoryIds.length,
                    hint: 'Chọn danh mục',
                    onTap: () => _openCategoryPicker(),
                  ),
                ],
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

// ── Picker tile (shows how many items selected) ──────────────────────────────

class _PickerTile extends StatelessWidget {
  final String label;
  final int count;
  final String hint;
  final VoidCallback onTap;

  const _PickerTile({
    required this.label,
    required this.count,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: count > 0
                    ? AppColors.primaryRed
                    : const Color(0xFF2A2A4A),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  count > 0
                      ? Icons.check_circle_outline_rounded
                      : Icons.add_circle_outline_rounded,
                  size: 16,
                  color: count > 0 ? AppColors.primaryRed : Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    count > 0 ? 'Đã chọn $count mục' : hint,
                    style: GoogleFonts.inter(
                      color: count > 0 ? Colors.white : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Product picker sheet ──────────────────────────────────────────────────────

class _ProductPickerSheet extends StatefulWidget {
  final ProductRepository repo;
  final List<int> initialSelected;

  const _ProductPickerSheet(
      {required this.repo, required this.initialSelected});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  late List<int> _selected;
  List<ProductEntity> _products = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final res = await widget.repo.getAllProducts(size: 200);
      final list = (res['products'] as List?)?.cast<ProductEntity>() ?? [];
      if (mounted) setState(() { _products = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? _products
        : _products
            .where((p) =>
                p.name.toLowerCase().contains(_search.toLowerCase()) ||
                p.id.toString().contains(_search))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Chọn sản phẩm',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ),
                  if (_selected.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_selected.length}',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            // Search
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Tìm sản phẩm...',
                  hintStyle: GoogleFonts.inter(
                      color: Colors.grey[600], fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Colors.grey, size: 18),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: Colors.grey, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          })
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF0F0F1E),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF2A2A4A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF2A2A4A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.primaryRed),
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFF2A2A4A), height: 1),
            // List
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryRed))
                  : filtered.isEmpty
                      ? Center(
                          child: Text('Không tìm thấy sản phẩm',
                              style: GoogleFonts.inter(
                                  color: Colors.grey[500])))
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(
                              color: Color(0xFF2A2A4A),
                              height: 1,
                              indent: 16),
                          itemBuilder: (_, i) {
                            final p = filtered[i];
                            final pid = int.tryParse(p.id) ?? 0;
                            final isSelected = _selected.contains(pid);
                            return ListTile(
                              dense: true,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  p.imageUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 40,
                                    height: 40,
                                    color: const Color(0xFF0F0F1E),
                                    child: const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 18,
                                        color: Colors.grey),
                                  ),
                                ),
                              ),
                              title: Text(p.name,
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              subtitle: Text(
                                  '${p.brand} • #${p.id}',
                                  style: GoogleFonts.inter(
                                      color: Colors.grey[500],
                                      fontSize: 11)),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.primaryRed,
                                      size: 22)
                                  : Icon(
                                      Icons.radio_button_unchecked_rounded,
                                      color: Colors.grey[600],
                                      size: 22),
                              onTap: () => setState(() {
                                if (isSelected) {
                                  _selected.remove(pid);
                                } else {
                                  _selected.add(pid);
                                }
                              }),
                            );
                          },
                        ),
            ),
            // Confirm button
            SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      _selected.isEmpty
                          ? 'Xác nhận (chưa chọn)'
                          : 'Xác nhận ${_selected.length} sản phẩm',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category picker sheet ─────────────────────────────────────────────────────

class _CategoryPickerSheet extends StatefulWidget {
  final ProductRepository repo;
  final List<int> initialSelected;

  const _CategoryPickerSheet(
      {required this.repo, required this.initialSelected});

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  late List<int> _selected;
  List<CategoryEntity> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await widget.repo.fetchCategories();
      if (mounted) setState(() { _categories = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Chọn danh mục',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ),
                  if (_selected.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_selected.length}',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2A2A4A), height: 1),
            // List
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryRed))
                  : _categories.isEmpty
                      ? Center(
                          child: Text('Không có danh mục',
                              style: GoogleFonts.inter(
                                  color: Colors.grey[500])))
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const Divider(
                              color: Color(0xFF2A2A4A),
                              height: 1,
                              indent: 16),
                          itemBuilder: (_, i) {
                            final cat = _categories[i];
                            final cid = int.tryParse(cat.id) ?? 0;
                            final isSelected = _selected.contains(cid);
                            return ListTile(
                              dense: true,
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryRed.withOpacity(0.15)
                                      : const Color(0xFF0F0F1E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.category_outlined,
                                  size: 18,
                                  color: isSelected
                                      ? AppColors.primaryRed
                                      : Colors.grey[500],
                                ),
                              ),
                              title: Text(cat.name,
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              subtitle: cat.parentName != null
                                  ? Text(cat.parentName!,
                                      style: GoogleFonts.inter(
                                          color: Colors.grey[500],
                                          fontSize: 11))
                                  : null,
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.primaryRed,
                                      size: 22)
                                  : Icon(
                                      Icons.radio_button_unchecked_rounded,
                                      color: Colors.grey[600],
                                      size: 22),
                              onTap: () => setState(() {
                                if (isSelected) {
                                  _selected.remove(cid);
                                } else {
                                  _selected.add(cid);
                                }
                              }),
                            );
                          },
                        ),
            ),
            // Confirm
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      _selected.isEmpty
                          ? 'Xác nhận (chưa chọn)'
                          : 'Xác nhận ${_selected.length} danh mục',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
