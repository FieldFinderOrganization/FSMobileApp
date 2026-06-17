import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/conversation_model.dart';
import '../cubit/conversation_list_cubit.dart';
import '../../../notification/presentation/cubit/notification_cubit.dart';
import 'user_chat_screen.dart';

class ConversationListScreen extends StatefulWidget {
  final String currentUserId;

  const ConversationListScreen({super.key, required this.currentUserId});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ConversationListCubit>().load(widget.currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationListCubit, ConversationListState>(
      builder: (context, state) {
        if (state is ConversationListLoading ||
            state is ConversationListInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          );
        }
        if (state is ConversationListError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.textGrey,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: GoogleFonts.inter(color: AppColors.textGrey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.read<ConversationListCubit>().load(
                    widget.currentUserId,
                  ),
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(color: AppColors.primaryRed),
                  ),
                ),
              ],
            ),
          );
        }
        if (state is ConversationListLoaded) {
          final convos = state.conversations;
          final activeFilter = state.activeFilter;
          return Column(
            children: [
              _FilterChips(
                activeFilter: activeFilter,
                onSelected: (f) =>
                    context.read<ConversationListCubit>().setFilter(f),
              ),
              Expanded(
                child: convos.isEmpty
                    ? _EmptyConversations(filter: activeFilter)
                    : RefreshIndicator(
                        color: AppColors.primaryRed,
                        onRefresh: () =>
                            context.read<ConversationListCubit>().refresh(),
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            0,
                            8,
                            0,
                            8 + MediaQuery.of(context).padding.bottom,
                          ),
                          itemCount: convos.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, indent: 76),
                          itemBuilder: (context, index) {
                            return _ConversationTile(
                              conversation: convos[index],
                              onTap: () => _openChat(context, convos[index]),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _openChat(BuildContext context, ConversationModel conv) {
    context.read<ConversationListCubit>().markConversationRead(
      conv.otherUserId,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserChatScreen(
          currentUserId: widget.currentUserId,
          otherUserId: conv.otherUserId,
          otherUserName: conv.otherUserName,
        ),
      ),
    ).then((_) {
      if (!context.mounted) return;
      context.read<ConversationListCubit>().refresh();
      // Tin đã đọc khi mở chat → đồng bộ lại badge chat toàn cục (bottom-nav).
      context.read<NotificationCubit>().refreshChatUnread();
    });
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(conversation.lastMessageTime);
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _Avatar(
              name: conversation.otherUserName,
              imageUrl: conversation.otherUserImageUrl,
              hasUnread: hasUnread,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          conversation.otherUserName,
                          style: GoogleFonts.inter(
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: 15,
                            color: const Color(0xFF1F2937),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _roleBadge(conversation.otherUserRole),
                      const Spacer(),
                      Text(
                        timeStr,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: hasUnread
                              ? AppColors.primaryRed
                              : AppColors.textGrey,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (conversation.isLastMessageFromMe)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            'Bạn: ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: hasUnread
                                ? const Color(0xFF1F2937)
                                : AppColors.textGrey,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : '${conversation.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chip role cạnh tên (vd "Chủ sân", "Shipper"). USER/null → không hiện.
  Widget _roleBadge(String? role) {
    final (String, Color, Color)? badge = switch (role) {
      'PROVIDER' => ('Chủ sân', const Color(0xFFFEE2E2), AppColors.primaryRed),
      'SHIPPER' => ('Shipper', const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
      'ADMIN' => ('Admin', const Color(0xFFFEE2E2), AppColors.primaryRed),
      _ => null,
    };
    if (badge == null) return const SizedBox.shrink();
    final (label, bgColor, fgColor) = badge;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: fgColor,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) return DateFormat('HH:mm').format(time);
    if (diff.inDays < 7) return DateFormat('EEE', 'vi').format(time);
    return DateFormat('dd/MM').format(time);
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool hasUnread;

  const _Avatar({required this.name, this.imageUrl, required this.hasUnread});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primaryRed.withValues(alpha: 0.12),
          backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
              ? NetworkImage(imageUrl!)
              : null,
          child: imageUrl == null || imageUrl!.isEmpty
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        if (hasUnread)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  final ConversationFilter activeFilter;
  final ValueChanged<ConversationFilter> onSelected;

  const _FilterChips({
    required this.activeFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          _chip(context, 'Tất cả', ConversationFilter.all),
          const SizedBox(width: 8),
          _chip(context, 'Chủ sân', ConversationFilter.provider),
          const SizedBox(width: 8),
          _chip(context, 'Shipper', ConversationFilter.shipper),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, ConversationFilter filter) {
    final selected = activeFilter == filter;
    return GestureDetector(
      onTap: () => onSelected(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryRed
              : AppColors.primaryRed.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.primaryRed,
          ),
        ),
      ),
    );
  }
}

class _EmptyConversations extends StatelessWidget {
  final ConversationFilter filter;
  const _EmptyConversations({this.filter = ConversationFilter.all});

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = switch (filter) {
      ConversationFilter.all => (
          Icons.chat_bubble_outline_rounded,
          'Chưa có tin nhắn nào',
          'Bấm "Nhắn tin" trên trang sân để bắt đầu\ncuộc trò chuyện với chủ sân',
        ),
      ConversationFilter.provider => (
          Icons.store_outlined,
          'Chưa có tin nhắn với chủ sân',
          'Các cuộc trò chuyện với chủ sân\nsẽ hiện ở đây',
        ),
      ConversationFilter.shipper => (
          Icons.delivery_dining_outlined,
          'Chưa có tin nhắn với shipper',
          'Các cuộc trò chuyện với shipper\nsẽ hiện ở đây',
        ),
    };
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
            child: Icon(icon, size: 36, color: AppColors.primaryRed),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
