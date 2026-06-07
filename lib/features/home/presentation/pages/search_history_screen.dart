import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/search_history_cubit.dart';

class SearchHistoryScreen extends StatelessWidget {
  const SearchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20,
              color: AppColors.textDark),
        ),
        title: Text(
          'Lịch sử tìm kiếm',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          BlocBuilder<SearchHistoryCubit, SearchHistoryState>(
            builder: (context, state) {
              if (state.items.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _confirmClearAll(context),
                child: Text(
                  'Xóa tất cả',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<SearchHistoryCubit, SearchHistoryState>(
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );
          }
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có lịch sử tìm kiếm',
                    style: GoogleFonts.inter(color: AppColors.textGrey),
                  ),
                ],
              ),
            );
          }
          final fmt = DateFormat('HH:mm dd/MM');
          return ListView.separated(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom),
            itemCount: state.items.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
            itemBuilder: (context, i) {
              final item = state.items[i];
              return ListTile(
                leading: const Icon(Icons.history_rounded,
                    color: AppColors.textGrey),
                title: Text(
                  item.keyword,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                subtitle: Text(
                  fmt.format(item.lastSearchedAt.toLocal()),
                  style:
                      GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textGrey),
                  onPressed: () =>
                      context.read<SearchHistoryCubit>().remove(item.id),
                ),
                onTap: () => Navigator.pop(context, item.keyword),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa tất cả lịch sử?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<SearchHistoryCubit>().clearAll();
    }
  }
}
