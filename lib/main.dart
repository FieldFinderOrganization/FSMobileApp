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

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TokenStorage>.value(value: tokenStorage),
        RepositoryProvider<DioClient>.value(value: dioClient),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<ProductRepository>.value(value: productRepository),
        RepositoryProvider<CartRepository>.value(value: cartRepository),
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
