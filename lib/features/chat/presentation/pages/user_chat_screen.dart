import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/user_chat_remote_datasource.dart';
import '../../data/datasources/user_chat_websocket_service.dart';
import '../cubit/user_chat_cubit.dart';

String _formatLastLogin(DateTime? time) {
  if (time == null) return '';
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 5) return 'Vừa hoạt động';
  if (diff.inHours < 1) return 'Hoạt động ${diff.inMinutes} phút trước';
  if (diff.inDays == 0) return 'Hoạt động lúc ${DateFormat('HH:mm').format(time)}';
  if (diff.inDays == 1) return 'Hoạt động hôm qua lúc ${DateFormat('HH:mm').format(time)}';
  return 'Hoạt động ${DateFormat('dd/MM/yyyy').format(time)}';
}

class UserChatScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;

  const UserChatScreen({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  late UserChatCubit _cubit;
  late UserChatRemoteDatasource _datasource;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  DateTime? _otherUserLastLogin;

  @override
  void initState() {
    super.initState();
    final dioClient = context.read<DioClient>();
    final tokenStorage = context.read<TokenStorage>();
    _datasource = UserChatRemoteDatasource(dioClient: dioClient);
    _cubit = UserChatCubit(
      remoteDatasource: _datasource,
      wsService: UserChatWebSocketService(tokenStorage: tokenStorage),
      currentUserId: widget.currentUserId,
      otherUserId: widget.otherUserId,
    );
    _cubit.initChat();
    _fetchOtherUserInfo();
  }

  Future<void> _fetchOtherUserInfo() async {
    final lastLogin = await _datasource.getUserLastLogin(widget.otherUserId);
    if (mounted) setState(() => _otherUserLastLogin = lastLogin);
  }

  @override
  void dispose() {
    _cubit.closeChat();
    _cubit.close();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUserName,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              BlocBuilder<UserChatCubit, UserChatState>(
                builder: (context, state) {
                  final connected = state is UserChatLoaded && state.isConnected;
                  if (!connected) {
                    return Text(
                      'Đang kết nối...',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
                    );
                  }
                  final label = _formatLastLogin(_otherUserLastLogin);
                  if (label.isEmpty) return const SizedBox.shrink();
                  return Text(
                    label,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
                  );
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Expanded(child: _buildMessageList()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return BlocConsumer<UserChatCubit, UserChatState>(
      listener: (context, state) {
        if (state is UserChatLoaded) _scrollToBottom();
      },
      builder: (context, state) {
        if (state is UserChatLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
        }
        if (state is UserChatError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.textGrey, size: 40),
                const SizedBox(height: 8),
                Text(state.message, style: GoogleFonts.inter(color: AppColors.textGrey)),
                TextButton(
                  onPressed: () => context.read<UserChatCubit>().initChat(),
                  child: const Text('Thử lại', style: TextStyle(color: AppColors.primaryRed)),
                ),
              ],
            ),
          );
        }
        if (state is UserChatLoaded) {
          if (state.messages.isEmpty) {
            return Center(
              child: Text(
                'Bắt đầu cuộc trò chuyện',
                style: GoogleFonts.inter(color: AppColors.textGrey),
              ),
            );
          }
          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: state.messages.length,
            itemBuilder: (context, index) {
              final msg = state.messages[index];
              final isMe = msg.senderId == widget.currentUserId;
              final showTime = index == 0 ||
                  state.messages[index].sentAt
                          .difference(state.messages[index - 1].sentAt)
                          .inMinutes >
                      10;
              return Column(
                children: [
                  if (showTime)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        DateFormat('HH:mm dd/MM').format(msg.sentAt),
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey),
                      ),
                    ),
                  Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.72,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.primaryRed : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                      ),
                      child: Text(
                        msg.content,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isMe ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Nhắn tin...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textGrey),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: GoogleFonts.inter(fontSize: 14),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<UserChatCubit, UserChatState>(
              builder: (context, state) {
                final sending = state is UserChatLoaded && state.isSending;
                return GestureDetector(
                  onTap: sending ? null : _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: sending ? AppColors.textGrey : AppColors.primaryRed,
                      shape: BoxShape.circle,
                    ),
                    child: sending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    _cubit.sendMessage(text);
  }
}
