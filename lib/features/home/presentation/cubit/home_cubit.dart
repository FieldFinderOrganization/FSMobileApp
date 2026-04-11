import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;

  HomeCubit({required HomeRepository repository})
      : _repository = repository,
        super(const HomeState());

  Future<void> loadAll() async {
    await Future.wait([
      _loadCategories(),
      _loadDiscounts(),
      _loadPitches(),
      _loadTopProducts(),
      _loadProducts(),
    ]);
  }

  Future<void> _loadCategories() async {
    emit(state.copyWith(categoriesStatus: LoadStatus.loading));
    try {
      final data = await _repository.fetchCategories();
      emit(state.copyWith(
        categories: data,
        categoriesStatus: LoadStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        categoriesStatus: LoadStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _loadDiscounts() async {
    emit(state.copyWith(discountsStatus: LoadStatus.loading));
    try {
      final data = await _repository.fetchDiscounts();
      emit(state.copyWith(
        discounts: data,
        discountsStatus: LoadStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        discountsStatus: LoadStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _loadPitches() async {
    emit(state.copyWith(pitchesStatus: LoadStatus.loading));
    try {
      final data = await _repository.fetchPitches();
      emit(state.copyWith(
        pitches: data,
        pitchesStatus: LoadStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        pitchesStatus: LoadStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _loadTopProducts() async {
    emit(state.copyWith(topProductsStatus: LoadStatus.loading));
    try {
      final data = await _repository.fetchTopProducts();
      emit(state.copyWith(
        topProducts: data,
        topProductsStatus: LoadStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        topProductsStatus: LoadStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _loadProducts() async {
    emit(state.copyWith(productsStatus: LoadStatus.loading));
    try {
      final data = await _repository.fetchProducts();
      emit(state.copyWith(
        products: data,
        productsStatus: LoadStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        productsStatus: LoadStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void selectCategory(String categoryName) {
    emit(state.copyWith(selectedCategoryName: categoryName));
  }

  Future<void> refresh() => loadAll();
}
