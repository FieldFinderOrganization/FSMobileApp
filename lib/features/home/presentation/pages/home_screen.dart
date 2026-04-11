import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/all_products_section.dart';
import '../widgets/featured_pitches_section.dart';
import '../widgets/hero_banner.dart';
import '../widgets/home_footer.dart';
import '../widgets/home_header.dart';
import '../widgets/top_products_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = TokenStorage();
    final dioClient = DioClient(tokenStorage);
    final datasource = HomeRemoteDatasource(dioClient.dio);
    final repository = HomeRepositoryImpl(datasource);

    return BlocProvider(
      create: (_) => HomeCubit(repository: repository)..loadAll(),
      child: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody();

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  late final ScrollController _scrollController;
  double _headerOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final opacity = (offset / 80).clamp(0.0, 1.0);
    if ((opacity - _headerOpacity).abs() > 0.01) {
      setState(() => _headerOpacity = opacity);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              return RefreshIndicator(
                color: const Color(0xFF7B0323),
                onRefresh: () => context.read<HomeCubit>().refresh(),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Space for the floating header
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).padding.top + 56,
                      ),
                    ),
                    SliverToBoxAdapter(child: HeroBanner(state: state)),
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
          // Floating sticky header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeader(opacity: _headerOpacity),
          ),
        ],
      ),
    );
  }
}
