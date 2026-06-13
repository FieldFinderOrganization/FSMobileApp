import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../order/presentation/pages/order_history_screen.dart';
import '../../../pitch/presentation/pages/booking_history_screen.dart';
import '../../data/models/notification_model.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';

class NotificationScreen extends StatefulWidget {
  final String currentUserId;

  const NotificationScreen({super.key, required this.currentUserId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<NotificationCubit>().loadNotifications(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<NotificationCubit>().state;
      if (state.hasMore && state.status != NotificationStatus.loading) {
        context.read<NotificationCubit>().loadNotifications();
      }
    }
  }

  void _onItemTap(NotificationModel item) {
    context.read<NotificationCubit>().markRead(item);
    switch (item.refType) {
      case 'ORDER':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderHistoryScreen(userId: widget.currentUserId),
          ),
        );
      case 'BOOKING':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingHistoryScreen(userId: widget.currentUserId),
          ),
        );
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Thông báo',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () =>
                    context.read<NotificationCubit>().markAllRead(),
                child: Text(
                  'Đọc tất cả',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryRed,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state.status == NotificationStatus.loading &&
              state.items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );
          }
          if (state.items.isEmpty) {
            return _EmptyState();
          }
          return RefreshIndicator(
            color: AppColors.primaryRed,
            onRefresh: () => context
                .read<NotificationCubit>()
                .loadNotifications(refresh: true),
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                  );
                }
                final item = state.items[index];
                return _NotificationTile(
                  item: item,
                  onTap: () => _onItemTap(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  IconData get _icon => switch (item.type) {
        'ORDER_CONFIRMED' => Icons.check_circle_outline_rounded,
        'ORDER_CLAIMED' => Icons.delivery_dining_rounded,
        'ORDER_SHIPPING' => Icons.local_shipping_outlined,
        'ORDER_DELIVERED' => Icons.inventory_2_outlined,
        'BOOKING_CONFIRMED' => Icons.event_available_rounded,
        'BOOKING_PLAY_REMINDER' => Icons.sports_soccer_rounded,
        _ => Icons.notifications_outlined,
      };

  String _relativeTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: item.isRead
            ? Colors.white
            : AppColors.primaryRed.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 20, color: AppColors.primaryRed),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight:
                          item.isRead ? FontWeight.w500 : FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _relativeTime(item.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFFB0B0B0),
                    ),
                  ),
                ],
              ),
            ),
            if (!item.isRead)
              Container(
                margin: const EdgeInsets.only(top: 6, left: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryRed,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_outlined,
                size: 36, color: AppColors.primaryRed),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có thông báo nào',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
