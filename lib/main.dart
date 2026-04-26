import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/network/dio_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/login/presentation/bloc/auth_cubit.dart';
import 'features/home/data/datasources/home_remote_datasource.dart';
import 'features/home/data/repositories/home_repository_impl.dart';
import 'features/home/presentation/cubit/home_cubit.dart';
import 'features/product/data/datasources/product_remote_data_source.dart';
import 'features/product/data/repositories/product_repository_impl.dart';
import 'features/product/domain/repositories/product_repository.dart';
import 'features/product/presentation/cubit/product_cubit.dart';
import 'features/cart/data/datasources/cart_remote_data_source.dart';
import 'features/cart/data/repositories/cart_repository_impl.dart';
import 'features/cart/domain/repositories/cart_repository.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';
import 'features/pitch/data/datasources/booking_remote_datasource.dart';
import 'features/pitch/data/datasources/pitch_remote_datasource.dart';
import 'features/pitch/data/datasources/review_remote_datasource.dart';
import 'features/pitch/data/repositories/booking_repository_impl.dart';
import 'features/pitch/data/repositories/pitch_repository_impl.dart';
import 'features/pitch/domain/repositories/pitch_repository.dart';
import 'features/profile/data/datasources/provider_remote_datasource.dart';
import 'features/profile/data/repositories/provider_repository_impl.dart';
import 'features/profile/domain/repositories/provider_repository.dart';
import 'features/chat/data/datasources/ai_chat_remote_datasource.dart';
import 'features/chat/data/datasources/chat_local_datasource.dart';
import 'features/chat/presentation/cubit/chat_cubit.dart';
import 'features/admin/data/datasources/admin_statistics_datasource.dart';
import 'features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import 'features/discount/data/datasources/discount_remote_data_source.dart';
import 'features/discount/data/repositories/discount_repository_impl.dart';
import 'features/discount/domain/repositories/discount_repository.dart';
import 'features/discount/presentation/cubit/my_wallet_cubit.dart';
import 'features/discount/presentation/cubit/admin_discount_cubit.dart';
import 'features/welcome/presentation/pages/welcome_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('vi');

  final tokenStorage = TokenStorage();
  final dioClient = DioClient(tokenStorage);
  final authDatasource = AuthRemoteDatasource(dioClient.dio);
  final authRepository = AuthRepositoryImpl(authDatasource);

  final homeDatasource = HomeRemoteDatasource(dioClient.dio);
  final homeRepository = HomeRepositoryImpl(homeDatasource);

  final productDatasource = ProductRemoteDataSource(dioClient.dio);
  final productRepository = ProductRepositoryImpl(productDatasource);

  final cartDatasource = CartRemoteDataSource(dioClient.dio);
  final cartRepository = CartRepositoryImpl(cartDatasource);

  final providerDatasource = ProviderRemoteDatasource(dioClient.dio);
  final providerRepository = ProviderRepositoryImpl(providerDatasource);

  final bookingDatasource = BookingRemoteDataSource(dioClient: dioClient);
  final bookingRepository = BookingRepositoryImpl(remoteDataSource: bookingDatasource);

  final pitchDatasource = PitchRemoteDatasource(dioClient.dio);
  final reviewDatasource = ReviewRemoteDatasource(dioClient.dio);
  final pitchRepository = PitchRepositoryImpl(
    pitchRemoteDatasource: pitchDatasource,
    reviewRemoteDatasource: reviewDatasource,
  );

  final aiChatDatasource = AIChatRemoteDatasource(dioClient);
  final adminStatisticsDatasource = AdminStatisticsDatasource(dioClient: dioClient);

  final discountDatasource = DiscountRemoteDataSource(dioClient.dio);
  final discountRepository = DiscountRepositoryImpl(discountDatasource);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TokenStorage>.value(value: tokenStorage),
        RepositoryProvider<DioClient>.value(value: dioClient),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<ProductRepository>.value(value: productRepository),
        RepositoryProvider<CartRepository>.value(value: cartRepository),
        RepositoryProvider<ProviderRepository>.value(value: providerRepository),
        RepositoryProvider<PitchRepository>.value(value: pitchRepository),
        RepositoryProvider<BookingRepository>.value(value: bookingRepository),
        RepositoryProvider<DiscountRepository>.value(value: discountRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(
              authRepository: authRepository,
              tokenStorage: tokenStorage,
            ),
          ),
          BlocProvider<HomeCubit>(
            create: (context) => HomeCubit(repository: homeRepository)..loadAll(),
          ),
          BlocProvider<ProductCubit>(
            create: (context) => ProductCubit(repository: productRepository)..loadProducts(),
          ),
          BlocProvider<CartCubit>(
            create: (context) => CartCubit(cartRepository),
          ),
          BlocProvider<ChatCubit>(
            create: (context) => ChatCubit(
              remoteDatasource: aiChatDatasource,
              localDatasource: ChatLocalDatasource(),
            )..loadSessions(),
          ),
          BlocProvider<AdminDashboardCubit>(
            create: (context) => AdminDashboardCubit(datasource: adminStatisticsDatasource),
          ),
          BlocProvider<MyWalletCubit>(
            create: (context) => MyWalletCubit(repository: discountRepository),
          ),
          BlocProvider<AdminDiscountCubit>(
            create: (context) => AdminDiscountCubit(repository: discountRepository),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FS Mobile App',
      theme: ThemeData(primarySwatch: Colors.red, useMaterial3: true),
      home: const WelcomeScreen(),
    );
  }
}
