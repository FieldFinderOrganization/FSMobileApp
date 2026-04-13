import 'package:flutter/material.dart';
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

  // ValueNotifiers so only the overlay widgets rebuild, not the main tree
  final ValueNotifier<double> _headerOpacity = ValueNotifier<double>(0.0);
  final ValueNotifier<double> _parallaxOffset = ValueNotifier<double>(0.0);

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
    if ((offset - _parallaxOffset.value).abs() > 5.0) {
      _parallaxOffset.value = offset;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerOpacity.dispose();
    _parallaxOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Parallax background — only this layer rebuilds on scroll
          _ParallaxBackground(offsetNotifier: _parallaxOffset),

          // Main content — only rebuilds on BLoC state changes
          BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              return RefreshIndicator(
                color: const Color(0xFF7B0323),
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
                    SliverToBoxAdapter(child: QuickActionsBar(state: state)),
                    SliverToBoxAdapter(
                      child: FeaturedPitchesSection(state: state),
                    ),
                    SliverToBoxAdapter(child: TopProductsSection(state: state)),
                    SliverToBoxAdapter(child: AllProductsSection(state: state)),
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
    );
  }
}

// ── Parallax background ───────────────────────────────────────────────────────
// Isolated widget: only this rebuilds when scroll offset changes

class _ParallaxBackground extends StatelessWidget {
  final ValueNotifier<double> offsetNotifier;

  const _ParallaxBackground({required this.offsetNotifier});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Positioned.fill(
        child: ValueListenableBuilder<double>(
          valueListenable: offsetNotifier,
          builder: (_, offset, _) {
            return Stack(
              children: [
                Positioned(
                  top: -80 + offset * 0.15,
                  left: -60,
                  child: _circle(300, 0.06),
                ),
                Positioned(
                  top: 200 + offset * 0.08,
                  right: -80,
                  child: _circle(250, 0.04),
                ),
                Positioned(
                  top: 500 + offset * 0.12,
                  left: -40,
                  child: _circle(200, 0.05),
                ),
                Positioned(
                  top: 800 + offset * 0.05,
                  right: -50,
                  child: _circle(350, 0.04),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _circle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryRed.withValues(alpha: opacity),
      ),
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
