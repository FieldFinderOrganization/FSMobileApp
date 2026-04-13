import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class FilterSheet extends StatefulWidget {
  final String selectedType;
  final String priceSortOrder;
  final Function(String, String) onApply;

  const FilterSheet({
    super.key,
    required this.selectedType,
    required this.priceSortOrder,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late String _tempType;
  late String _tempSort;

  @override
  void initState() {
    super.initState();
    _tempType = widget.selectedType;
    _tempSort = widget.priceSortOrder;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bộ lọc & Sắp xếp',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tempType = '';
                    _tempSort = 'none';
                  });
                },
                child: const Text('Thiết lập lại'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Loại sân',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Sân 5', 'Sân 7', 'Sân 11'].map((t) {
              final isSel = _tempType == t;
              return ChoiceChip(
                label: Text(t),
                selected: isSel,
                onSelected: (val) => setState(() => _tempType = val ? t : ''),
                selectedColor: AppColors.primaryRed.withValues(alpha: 0.1),
                checkmarkColor: AppColors.primaryRed,
                labelStyle: GoogleFonts.inter(
                  color: isSel ? AppColors.primaryRed : AppColors.textGrey,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Giá tiền',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _SortOption(
            label: 'Thấp đến cao',
            isActive: _tempSort == 'asc',
            onTap: () => setState(() => _tempSort = 'asc'),
          ),
          const SizedBox(height: 8),
          _SortOption(
            label: 'Cao đến thấp',
            isActive: _tempSort == 'desc',
            onTap: () => setState(() => _tempSort = 'desc'),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_tempType, _tempSort);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Áp dụng',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryRed.withValues(alpha: 0.05)
              : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppColors.primaryRed : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isActive ? AppColors.primaryRed : AppColors.textDark,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isActive)
              const Icon(Icons.check_circle_rounded,
                  size: 20, color: AppColors.primaryRed),
          ],
        ),
      ),
    );
  }
}
