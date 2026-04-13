import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/home_cubit.dart';

class QuickActionsBar extends StatelessWidget {
  final HomeState state;
  const QuickActionsBar({super.key, required this.state});

  static const _items = [
    _QuickAction(label: 'Sân 5', icon: Icons.sports_soccer, pitchType: 'Sân 5'),
    _QuickAction(label: 'Sân 7', icon: Icons.sports_soccer, pitchType: 'Sân 7'),
    _QuickAction(label: 'Sân 11', icon: Icons.stadium, pitchType: 'Sân 11'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _items.map((item) => _buildItem(context, item)).toList(),
      ),
    );
  }

  Widget _buildItem(BuildContext context, _QuickAction item) {
    final isActive =
        item.pitchType != null && state.selectedPitchType == item.pitchType;

    return GestureDetector(
      onTap: () {
        if (item.pitchType != null) {
          final next = isActive ? '' : item.pitchType!;
          context.read<HomeCubit>().updatePitchFilters(type: next);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? AppColors.primaryRed
                  : AppColors.primaryRed.withValues(alpha: 0.10),
            ),
            child: Icon(
              item.icon,
              size: 22,
              color: isActive ? Colors.white : AppColors.primaryRed,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.primaryRed : AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final String? pitchType;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.pitchType,
  });
}
