import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/home_cubit.dart';
import '../../../product/presentation/widgets/all_products_section.dart';
import '../../../pitch/presentation/widgets/featured_pitches_section.dart';
import '../widgets/hero_banner.dart';
import '../widgets/home_footer.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_actions_bar.dart';
import '../../../product/presentation/widgets/top_products_section.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeBody();
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody();

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  late final ScrollController _scrollController;

  // ValueNotifier so only the header rebuilds, not the main tree
  final ValueNotifier<double> _headerOpacity = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final opacity = (offset / 80).clamp(0.0, 1.0);

    if ((opacity - _headerOpacity.value).abs() > 0.01) {
      _headerOpacity.value = opacity;
    }

    // Infinite scroll for Products
    final state = context.read<HomeCubit>().state;
    if (state.isProductsExpanded &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 600) {
      context.read<HomeCubit>().loadNextPageProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerOpacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Main content — only rebuilds on BLoC state changes
            BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                return RefreshIndicator(
                  color: AppColors.primaryRed,
                  onRefresh: () => context.read<HomeCubit>().refresh(),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).padding.top + 56,
                        ),
                      ),
                      SliverToBoxAdapter(child: HeroBanner(state: state)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: QuickActionsBar(state: state),
                        ),
                      ),
                      const SliverToBoxAdapter(child: _SectionDivider()),
                      SliverToBoxAdapter(
                        child: FeaturedPitchesSection(state: state),
                      ),
                      const SliverToBoxAdapter(child: _SectionDivider()),
                      SliverToBoxAdapter(
                        child: TopProductsSection(state: state),
                      ),
                      const SliverToBoxAdapter(child: _SectionDivider()),
                      SliverToBoxAdapter(
                        child: AllProductsSection(state: state),
                      ),
                      const SliverToBoxAdapter(child: HomeFooter()),
                    ],
                  ),
                );
              },
            ),

            // Sticky header — only this layer rebuilds on opacity change
            _StickyHeader(
              opacityNotifier: _headerOpacity,
              onSearchTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section divider ───────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Divider(color: AppColors.hairline, height: 1, thickness: 1),
    );
  }
}

// ── Sticky header ─────────────────────────────────────────────────────────────
// Isolated widget: only this rebuilds when header opacity changes

class _StickyHeader extends StatelessWidget {
  final ValueNotifier<double> opacityNotifier;
  final VoidCallback onSearchTap;

  const _StickyHeader({
    required this.opacityNotifier,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ValueListenableBuilder<double>(
        valueListenable: opacityNotifier,
        builder: (_, opacity, _) {
          return HomeHeader(opacity: opacity, onSearchTap: onSearchTap);
        },
      ),
    );
  }
}
