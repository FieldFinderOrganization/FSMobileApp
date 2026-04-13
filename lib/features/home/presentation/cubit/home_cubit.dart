import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/home_repository.dart';
import 'home_state.dart';

export 'home_state.dart';

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
      emit(state.copyWith(categories: data, categoriesStatus: LoadStatus.success));
    } catch (e) {
      emit(state.copyWith(
          categoriesStatus: LoadStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _loadDiscounts() async {
    emit(state.copyWith(discountsStatus: LoadStatus.loading));
    try {
      final data = await _repository.fetchDiscounts();
      emit(state.copyWith(discounts: data, discountsStatus: LoadStatus.success));
    } catch (e) {
      emit(state.copyWith(
          discountsStatus: LoadStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _loadPitches() async {
    emit(state.copyWith(pitchesStatus: LoadStatus.loading));
    try {
      final data = await _repository.fetchPitches();
      emit(state.copyWith(pitches: data, pitchesStatus: LoadStatus.success));
    } catch (e) {
      emit(state.copyWith(
          pitchesStatus: LoadStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _loadTopProducts() async {
    emit(state.copyWith(topProductsStatus: LoadStatus.loading));
    try {
      final data = await _repository.fetchTopProducts();
      emit(state.copyWith(
          topProducts: data, topProductsStatus: LoadStatus.success));
    } catch (e) {
      emit(state.copyWith(
          topProductsStatus: LoadStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _loadProducts() async {
    emit(state.copyWith(productsStatus: LoadStatus.loading));
    try {
      final data = await _repository.fetchProducts();
      emit(state.copyWith(products: data, productsStatus: LoadStatus.success));
    } catch (e) {
      emit(state.copyWith(
          productsStatus: LoadStatus.failure, errorMessage: e.toString()));
    }
  }

  // ── Category ─────────────────────────────────────────────────────────────

  void selectCategory(String categoryName) {
    emit(state.copyWith(
      selectedCategoryName: categoryName,
      selectedSubCategoryNames: {},
      visibleProductCount: kProductPageSize,
      hasLoadedMore: false,
    ));
  }

  void toggleSubCategory(String subCategoryName) {
    final current = Set<String>.from(state.selectedSubCategoryNames);
    if (current.contains(subCategoryName)) {
      current.remove(subCategoryName);
    } else {
      current.add(subCategoryName);
    }
    emit(state.copyWith(
      selectedSubCategoryNames: current,
      visibleProductCount: kProductPageSize,
      hasLoadedMore: false,
    ));
  }

  // ── Pagination ────────────────────────────────────────────────────────────

  /// Xem thêm: tăng số sản phẩm, đánh dấu hasLoadedMore = true
  void loadMoreProducts() {
    emit(state.copyWith(
      visibleProductCount: state.visibleProductCount + kProductPageSize,
      hasLoadedMore: true,
    ));
  }

  /// Ẩn bớt: trở về số sản phẩm ban đầu
  void collapseProducts() {
    emit(state.copyWith(
      visibleProductCount: kProductPageSize,
      hasLoadedMore: false,
    ));
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  void setSortOption(SortOption option) {
    // Toggle: nếu đang chọn cái này thì bỏ (về none)
    final next =
        state.sortOption == option ? SortOption.none : option;
    emit(state.copyWith(
      sortOption: next,
      visibleProductCount: kProductPageSize,
      hasLoadedMore: false,
    ));
  }

  void toggleGender(String gender) {
    final current = Set<String>.from(state.selectedGenders);
    if (current.contains(gender)) {
      current.remove(gender);
    } else {
      current.add(gender);
    }
    emit(state.copyWith(
      selectedGenders: current,
      visibleProductCount: kProductPageSize,
      hasLoadedMore: false,
    ));
  }

  // ── Pitch District ────────────────────────────────────────────────────────

  void selectDistrict(String district) {
    // Toggle: tap lại quận đang chọn → reset về "Tất cả"
    final next = state.selectedDistrict == district ? '' : district;
    emit(state.copyWith(selectedDistrict: next));
  }

  void updatePitchFilters({String? type, String? sort}) {
    emit(state.copyWith(
      selectedPitchType: type ?? state.selectedPitchType,
      pitchSortOrder: sort ?? state.pitchSortOrder,
    ));
  }

  Future<void> refresh() => loadAll();
}

