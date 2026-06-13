import 'dart:async';
import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/user_chat_remote_datasource.dart';
import '../../data/datasources/user_chat_websocket_service.dart';
import '../../data/models/user_chat_message_model.dart';
import '../../../call/presentation/cubit/call_cubit.dart';
import '../cubit/user_chat_cubit.dart';
import 'chat_video_player_page.dart';

/// Bộ emoji cố định cho reaction (kiểu Messenger)
const _reactionEmojis = ['❤️', '😆', '😮', '😢', '👍', '😡'];

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
  final _imagePicker = ImagePicker();
  final _inputFocus = FocusNode();
  bool _showEmojiPanel = false;
  DateTime? _otherUserLastLogin;
  Timer? _labelTimer;

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
    _labelTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _fetchOtherUserInfo() async {
    final lastLogin = await _datasource.getUserLastLogin(widget.otherUserId);
    if (mounted) setState(() => _otherUserLastLogin = lastLogin);
  }

  @override
  void dispose() {
    _labelTimer?.cancel();
    _cubit.closeChat();
    _cubit.close();
    _textController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
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

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      _cubit.sendImage(File(picked.path));
    }
  }

  Future<void> _pickImageFromCamera() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null) {
      _cubit.sendImage(File(picked.path));
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final picked = await _imagePicker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 60),
    );
    if (picked == null) return;
    final ok = await _cubit.sendVideo(File(picked.path));
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không gửi được video (tối đa 50MB)',
            style: GoogleFonts.inter(),
          ),
        ),
      );
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Thư viện ảnh', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text('Máy ảnh', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: Text('Video từ thư viện', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: Text('Quay video', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
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
          actions: [
            IconButton(
              icon: const Icon(Icons.call_rounded,
                  color: AppColors.primaryRed, size: 24),
              tooltip: 'Gọi thoại',
              onPressed: () => context
                  .read<CallCubit>()
                  .startCall(widget.otherUserId, widget.otherUserName),
            ),
            IconButton(
              icon: const Icon(Icons.videocam_rounded,
                  color: AppColors.primaryRed, size: 26),
              tooltip: 'Gọi video',
              onPressed: () => context.read<CallCubit>().startCall(
                  widget.otherUserId, widget.otherUserName,
                  video: true),
            ),
          ],
        ),
        body: Column(
          children: [
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Expanded(child: _buildMessageList()),
            _buildInputBar(),
            Offstage(
              offstage: !_showEmojiPanel,
              child: SizedBox(
                height: 280,
                child: emoji.EmojiPicker(
                  textEditingController: _textController,
                  config: const emoji.Config(
                    height: 280,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: emoji.EmojiViewConfig(emojiSizeMax: 28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(UserChatMessageModel msg, bool isMe) {
    final Widget bubble;
    if (msg.isCall) {
      bubble = _buildCallBubble(msg, isMe);
    } else if (msg.isVideo) {
      bubble = _buildVideoBubble(msg, isMe);
    } else if (msg.isImage) {
      bubble = _buildImageBubble(msg, isMe);
    } else {
      bubble = _buildTextBubble(msg, isMe);
    }

    // Long-press tin của người kia → thanh reaction; chip emoji đè góc bubble
    // (không áp dụng cho tin cuộc gọi)
    final canReact = !isMe && msg.hasServerId && !msg.isCall;
    final interactive = canReact
        ? GestureDetector(
            onLongPress: () => _showReactionBar(msg),
            child: bubble,
          )
        : bubble;

    if (msg.reaction == null) return interactive;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: interactive,
        ),
        Positioned(
          bottom: 0,
          right: isMe ? null : 8,
          left: isMe ? 8 : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Text(msg.reaction!, style: const TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }

  void _showReactionBar(UserChatMessageModel msg) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _reactionEmojis.map((emoji) {
              final selected = msg.reaction == emoji;
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _cubit.reactToMessage(msg, emoji);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: selected
                      ? BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(20),
                        )
                      : null,
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Bong bóng cuộc gọi (kiểu Messenger) — tap để gọi lại (đúng loại thoại/video).
  Widget _buildCallBubble(UserChatMessageModel msg, bool isMe) {
    final missed = msg.callStatus == 'MISSED';
    final rejected = msg.callStatus == 'REJECTED';
    final canceled = msg.callStatus == 'CANCELED';
    final video = msg.isVideoCall;
    final kind = video ? 'video' : 'thoại';
    final dur = msg.callDurationSec ?? 0;

    String label;
    if (missed) {
      label = isMe ? 'Cuộc gọi $kind không trả lời' : 'Cuộc gọi $kind nhỡ';
    } else if (rejected) {
      label = 'Cuộc gọi $kind bị từ chối';
    } else if (canceled) {
      label = 'Cuộc gọi $kind đã hủy';
    } else {
      final m = (dur ~/ 60).toString().padLeft(2, '0');
      final s = (dur % 60).toString().padLeft(2, '0');
      label = dur > 0 ? 'Cuộc gọi $kind · $m:$s' : 'Cuộc gọi $kind';
    }

    final accent = missed ? AppColors.primaryRed : (isMe ? Colors.white : AppColors.textDark);
    final IconData icon = missed
        ? (video ? Icons.videocam_off_rounded : Icons.phone_missed_rounded)
        : (video ? Icons.videocam_rounded : Icons.phone_rounded);

    return GestureDetector(
      onTap: () => context.read<CallCubit>().startCall(
          widget.otherUserId, widget.otherUserName,
          video: video),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isMe ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextBubble(UserChatMessageModel msg, bool isMe) {
    return Container(
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
    );
  }

  Widget _buildImageBubble(UserChatMessageModel msg, bool isMe) {
    // imageUrl có thể là URL Cloudinary (http) hoặc local path (optimistic)
    final isLocalFile = msg.imageUrl != null && !msg.imageUrl!.startsWith('http');
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        child: isLocalFile
            ? Stack(
                children: [
                  Image.file(
                    File(msg.imageUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _brokenImagePlaceholder(),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            : Image.network(
                msg.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 200,
                    height: 150,
                    color: const Color(0xFFF0F0F0),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, _, _) => _brokenImagePlaceholder(),
              ),
      ),
    );
  }

  /// Cloudinary trả thumbnail khi đổi đuôi video thành .jpg trên URL /video/upload/
  String _videoThumbUrl(String videoUrl) =>
      videoUrl.replaceAll(RegExp(r'\.\w+$'), '.jpg');

  Widget _buildVideoBubble(UserChatMessageModel msg, bool isMe) {
    final isLocalFile = msg.imageUrl != null && !msg.imageUrl!.startsWith('http');
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        child: isLocalFile
            // Đang upload: placeholder + spinner (URL local chưa phát được)
            ? Container(
                width: 220,
                height: 150,
                color: Colors.black87,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              )
            : GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatVideoPlayerPage(videoUrl: msg.imageUrl!),
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      _videoThumbUrl(msg.imageUrl!),
                      width: 220,
                      height: 150,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: 220,
                          height: 150,
                          color: const Color(0xFFF0F0F0),
                        );
                      },
                      errorBuilder: (_, _, _) => Container(
                        width: 220,
                        height: 150,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 32),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _brokenImagePlaceholder() {
    return Container(
      width: 200,
      height: 150,
      color: const Color(0xFFF0F0F0),
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
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
                    child: _buildMessageBubble(msg, isMe),
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
            BlocBuilder<UserChatCubit, UserChatState>(
              builder: (context, state) {
                final sending = state is UserChatLoaded && state.isSending;
                return GestureDetector(
                  onTap: sending ? null : _showImageSourceSheet,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.image_outlined,
                      color: sending ? AppColors.textGrey : AppColors.primaryRed,
                      size: 26,
                    ),
                  ),
                );
              },
            ),
            GestureDetector(
              onTap: () {
                setState(() => _showEmojiPanel = !_showEmojiPanel);
                if (_showEmojiPanel) {
                  _inputFocus.unfocus();
                } else {
                  _inputFocus.requestFocus();
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  _showEmojiPanel
                      ? Icons.keyboard_alt_outlined
                      : Icons.emoji_emotions_outlined,
                  color: AppColors.primaryRed,
                  size: 26,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _inputFocus,
                onTap: () {
                  if (_showEmojiPanel) {
                    setState(() => _showEmojiPanel = false);
                  }
                },
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
