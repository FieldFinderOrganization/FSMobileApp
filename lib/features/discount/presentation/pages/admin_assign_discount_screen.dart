import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../admin/data/models/admin_user_list_model.dart';
import '../../domain/entities/admin_discount_entity.dart';
import '../cubit/admin_discount_cubit.dart';

class AdminAssignDiscountScreen extends StatefulWidget {
  final AdminDiscountEntity discount;

  const AdminAssignDiscountScreen({super.key, required this.discount});

  @override
  State<AdminAssignDiscountScreen> createState() =>
      _AdminAssignDiscountScreenState();
}

class _AdminAssignDiscountScreenState extends State<AdminAssignDiscountScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  final List<AdminUserItem> _users = [];
  final Set<String> _selectedIds = {};

  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  bool _loadingMore = false;
  String _searchQuery = '';

  static const _kPageSize = 20;

  @override
  void initState() {
    super.initState();
    _fetchPage(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) _fetchPage();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = query;
      _fetchPage(reset: true);
    });
  }

  Future<void> _fetchPage({bool reset = false}) async {
    if (reset) {
      if (_loading) return;
      setState(() {
        _loading = true;
        _page = 0;
        _users.clear();
        _hasMore = true;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final dio = context.read<DioClient>().dio;
      final currentPage = reset ? 0 : _page;
      final response = await dio.get(
        ApiConstants.adminUsers,
        queryParameters: {
          'size': _kPageSize,
          'page': currentPage,
          if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        },
      );
      final model = AdminUserListModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      if (!mounted) return;
      setState(() {
        _users.addAll(model.content);
        _page = currentPage + 1;
        _hasMore = _page < model.totalPages;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _assign() async {
    if (_selectedIds.isEmpty) return;
    await context.read<AdminDiscountCubit>().assignToUsers(
      widget.discount.id,
      _selectedIds.toList(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gán mã: ${widget.discount.code}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            Text(
              'Chọn người dùng để gán',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _selectedIds.isEmpty ? null : _assign,
            child: Text(
              'Gán (${_selectedIds.length})',
              style: GoogleFonts.inter(
                color: _selectedIds.isEmpty ? Colors.white38 : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên hoặc email...',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // Selected count bar
          if (_selectedIds.isNotEmpty)
            Container(
              color: AppColors.primaryRed.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primaryRed,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đã chọn ${_selectedIds.length} người dùng',
                    style: GoogleFonts.inter(
                      color: AppColors.primaryRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _selectedIds.clear()),
                    child: Text(
                      'Bỏ chọn tất cả',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // List
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryRed,
                    ),
                  )
                : _users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 52,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Không tìm thấy người dùng',
                          style: GoogleFonts.inter(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scrollCtrl,
                    padding: EdgeInsets.only(bottom: bottomPad + 16),
                    itemCount: _users.length + (_loadingMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (_, i) {
                      // Loading more indicator
                      if (i == _users.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryRed,
                            ),
                          ),
                        );
                      }
                      final u = _users[i];
                      final selected = _selectedIds.contains(u.userId);
                      return Material(
                        color: selected
                            ? AppColors.primaryRed.withValues(alpha: 0.05)
                            : Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: selected
                                ? AppColors.primaryRed
                                : const Color(0xFFEEF2FF),
                            child: Text(
                              u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                              style: GoogleFonts.inter(
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF4454A0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            u.name,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1A1D2E),
                            ),
                          ),
                          subtitle: Text(
                            u.email,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          trailing: Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: selected
                                ? AppColors.primaryRed
                                : Colors.grey.shade400,
                            size: 22,
                          ),
                          onTap: () => setState(() {
                            if (selected) {
                              _selectedIds.remove(u.userId);
                            } else {
                              _selectedIds.add(u.userId);
                            }
                          }),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
