import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/favorite_cubit.dart';
import '../cubit/favorite_state.dart';

/// Nút tim dùng chung (card + detail). Đọc FavoriteCubit global, tap để toggle.
/// [filledBackground] = true cho nền tròn mờ (đè trên ảnh); false cho nút trơn.
class FavoriteHeartButton extends StatelessWidget {
  final String pitchId;
  final double size;
  final bool filledBackground;

  const FavoriteHeartButton({
    super.key,
    required this.pitchId,
    this.size = 22,
    this.filledBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final isFav = context.select<FavoriteCubit, bool>(
      (c) => c.state.isFavorite(pitchId),
    );

    final icon = Icon(
      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      size: size,
      color: isFav ? AppColors.primaryRed : Colors.white,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<FavoriteCubit>().toggle(pitchId);
      },
      child: filledBackground
          ? Container(
              padding: EdgeInsets.all(size * 0.36),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: icon,
            )
          : Padding(
              padding: EdgeInsets.all(size * 0.2),
              child: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: size,
                color: AppColors.primaryRed,
              ),
            ),
    );
  }
}

/// Tiện ích lắng nghe lỗi toggle để hiện snackbar (đặt cao trong cây widget).
class FavoriteErrorListener extends StatelessWidget {
  final Widget child;
  const FavoriteErrorListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<FavoriteCubit, FavoriteState>(
      listenWhen: (prev, curr) =>
          curr.errorMessage.isNotEmpty &&
          curr.errorMessage != prev.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không cập nhật được sân yêu thích. Thử lại.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
      child: child,
    );
  }
}
