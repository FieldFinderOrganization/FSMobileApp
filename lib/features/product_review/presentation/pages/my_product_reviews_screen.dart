import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../order/data/datasources/order_remote_data_source.dart';
import '../../data/datasources/item_review_remote_datasource.dart';
import '../../data/repositories/item_review_repository_impl.dart';
import '../cubit/my_product_reviews_cubit.dart';
import '../cubit/my_product_reviews_state.dart';
import '../widgets/product_review_card.dart';
import '../widgets/unreviewed_product_card.dart';

class MyProductReviewsScreen extends StatelessWidget {
  final String userId;

  const MyProductReviewsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MyProductReviewsCubit(
        reviewRepository: ItemReviewRepositoryImpl(
          remoteDataSource: ItemReviewRemoteDataSource(
            dioClient: context.read<DioClient>(),
          ),
        ),
        orderDataSource: OrderRemoteDataSource(
          dioClient: context.read<DioClient>(),
        ),
        userId: userId,
      )..load(),
      child: const _MyProductReviewsBody(),
    );
  }
}

class _MyProductReviewsBody extends StatelessWidget {
  const _MyProductReviewsBody();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                BlocBuilder<MyProductReviewsCubit, MyProductReviewsState>(
                  builder: (context, state) {
                    final reviewCount =
                        state is MyProductReviewsLoaded ? state.reviews.length : 0;
                    final unreviewedCount = state is MyProductReviewsLoaded
                        ? state.unreviewedProducts.length
                        : 0;
                    return Container(
                      color: Colors.white,
                      child: TabBar(
                        labelStyle: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w700),
                        unselectedLabelStyle: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w500),
                        labelColor: AppColors.primaryRed,
                        unselectedLabelColor: AppColors.textGrey,
                        indicatorColor: AppColors.primaryRed,
                        indicatorWeight: 2.5,
                        tabs: [
                          Tab(text: 'Đã đánh giá ($reviewCount)'),
                          Tab(text: 'Chưa đánh giá ($unreviewedCount)'),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: BlocBuilder<MyProductReviewsCubit, MyProductReviewsState>(
                    builder: (context, state) {
                      if (state is MyProductReviewsLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primaryRed),
                        );
                      }
                      if (state is MyProductReviewsError) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.redAccent, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'Không thể tải dữ liệu',
                                style: GoogleFonts.inter(
                                    fontSize: 14, color: AppColors.textGrey),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () =>
                                    context.read<MyProductReviewsCubit>().load(),
                                child: Text(
                                  'Thử lại',
                                  style: GoogleFonts.inter(
                                      color: AppColors.primaryRed,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      if (state is MyProductReviewsLoaded ||
                          state is MyProductReviewsSubmitting ||
                          state is MyProductReviewsActionSuccess ||
                          state is MyProductReviewsActionError) {
                        return TabBarView(
                          children: [
                            _buildReviewsList(context, state),
                            _buildUnreviewedList(context, state),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.textGrey),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Đánh giá sản phẩm',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          BlocBuilder<MyProductReviewsCubit, MyProductReviewsState>(
            builder: (context, state) {
              if (state is MyProductReviewsLoading) {
                return const SizedBox.shrink();
              }
              return GestureDetector(
                onTap: () => context.read<MyProductReviewsCubit>().load(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      size: 18, color: AppColors.textGrey),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList(BuildContext context, MyProductReviewsState state) {
    if (state is! MyProductReviewsLoaded) {
      final cubit = context.read<MyProductReviewsCubit>();
      if (cubit.state is MyProductReviewsLoaded) {
        state = cubit.state;
      } else {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed));
      }
    }
    final loadedState = state as MyProductReviewsLoaded;
    if (loadedState.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_outline_rounded,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Bạn chưa đánh giá sản phẩm nào',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: loadedState.reviews.length,
      itemBuilder: (_, i) => ProductReviewCard(review: loadedState.reviews[i]),
    );
  }

  Widget _buildUnreviewedList(BuildContext context, MyProductReviewsState state) {
    if (state is! MyProductReviewsLoaded) {
      final cubit = context.read<MyProductReviewsCubit>();
      if (cubit.state is MyProductReviewsLoaded) {
        state = cubit.state;
      } else {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed));
      }
    }
    final loadedState = state as MyProductReviewsLoaded;
    if (loadedState.unreviewedProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Tất cả sản phẩm đã được đánh giá',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: loadedState.unreviewedProducts.length,
      itemBuilder: (_, i) =>
          UnreviewedProductCard(product: loadedState.unreviewedProducts[i]),
    );
  }
}
