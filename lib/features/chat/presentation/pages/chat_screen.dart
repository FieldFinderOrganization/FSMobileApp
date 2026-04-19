import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/user_chat_remote_datasource.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../cubit/conversation_list_cubit.dart';
import '../widgets/chat_session_tile.dart';
import 'chat_detail_screen.dart';
import 'conversation_list_screen.dart';

class ChatScreen extends StatelessWidget {
  final String currentUserId;

  const ChatScreen({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          title: Text(
            'Chat',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.primaryRed,
            unselectedLabelColor: AppColors.textGrey,
            indicatorColor: AppColors.primaryRed,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle:
                GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle:
                GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(text: 'AI Chat'),
              Tab(text: 'Tin nhắn'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AiChatTab(),
            BlocProvider(
              create: (context) => ConversationListCubit(
                datasource: UserChatRemoteDatasource(
                    dioClient: context.read<DioClient>()),
              ),
              child: ConversationListScreen(currentUserId: currentUserId),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiChatTab extends StatefulWidget {
  @override
  State<_AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<_AiChatTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<ChatCubit>().loadSessions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatCubit, ChatState>(
      listenWhen: (previous, current) =>
          current is ChatSessionOpen && previous is! ChatSessionOpen,
      listener: (context, state) {
        if (state is ChatSessionOpen) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<ChatCubit>(),
                child: const ChatDetailScreen(),
              ),
            ),
          ).then((_) {
            if (context.mounted) context.read<ChatCubit>().backToList();
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.read<ChatCubit>().createSession(),
          backgroundColor: AppColors.primaryRed,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            if (state is ChatInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ChatSessionListLoaded) {
              if (state.sessions.isEmpty) {
                return _EmptyState(
                  onCreateTap: () => context.read<ChatCubit>().createSession(),
                );
              }
              return ListView.builder(
                itemCount: state.sessions.length,
                itemBuilder: (context, index) {
                  final session = state.sessions[index];
                  return ChatSessionTile(
                    session: session,
                    onTap: () =>
                        context.read<ChatCubit>().openSession(session.sessionId),
                    onDelete: () =>
                        context.read<ChatCubit>().deleteSession(session.sessionId),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyState({required this.onCreateTap});

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
            child: const Icon(Icons.smart_toy_outlined,
                size: 36, color: AppColors.primaryRed),
          ),
          const SizedBox(height: 20),
          Text(
            'Chat AI',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hỏi về sân bóng, sản phẩm hoặc tìm kiếm bằng hình ảnh',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Bắt đầu trò chuyện',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
