import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/entities/suggested_products_entity.dart';
import '../../../pitch/domain/repositories/pitch_repository.dart';
import '../../../pitch/domain/entities/suggested_pitches_entity.dart';
import 'product_detail_state.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  final ProductRepository _repository;
  final PitchRepository _pitchRepository;

  ProductDetailCubit({
    required ProductRepository repository,
    required PitchRepository pitchRepository,
  })  : _repository = repository,
        _pitchRepository = pitchRepository,
        super(const ProductDetailState());

  Future<void> loadProduct(String id) async {
    emit(state.copyWith(status: ProductDetailStatus.loading));
    try {
      final product = await _repository.getProductById(id);
      // Auto-select first available size
      final firstAvailable = product.variants
          .where((v) => v.isAvailable)
          .map((v) => v.size)
          .firstOrNull;
      emit(state.copyWith(
        status: ProductDetailStatus.success,
        product: product,
        selectedSize: firstAvailable,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProductDetailStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> loadSuggested(String productId, {double? lat, double? lng}) async {
    debugPrint("[PRODUCT_DETAIL_CUBIT] loadSuggested start productId=$productId lat=$lat lng=$lng");
    if (!isClosed) emit(state.copyWith(suggestedLoading: true));

    // Tách 2 call độc lập: 1 cái lỗi không được xoá cái còn lại.
    SuggestedProductsEntity suggested = const SuggestedProductsEntity();
    SuggestedPitchesEntity suggestedPitches = const SuggestedPitchesEntity();

    try {
      suggested = await _repository.getSuggested(productId);
    } catch (e, stack) {
      debugPrint("[PRODUCT_DETAIL_CUBIT] getSuggested(products) FAILED productId=$productId: $e");
      debugPrint("$stack");
    }

    try {
      suggestedPitches = await _pitchRepository.getSuggestedForProduct(lat: lat, lng: lng);
    } catch (e, stack) {
      debugPrint("[PRODUCT_DETAIL_CUBIT] getSuggestedForProduct(pitches) FAILED: $e");
      debugPrint("$stack");
    }

    debugPrint(
      "[PRODUCT_DETAIL_CUBIT] counts products similar=${suggested.similar.length} "
      "topSelling=${suggested.topSelling.length} history=${suggested.historyBased.length} "
      "pitches nearby=${suggestedPitches.nearby.length} topRated=${suggestedPitches.topRated.length} "
      "visited=${suggestedPitches.visited.length}",
    );

    if (!isClosed) {
      emit(state.copyWith(
        suggested: suggested,
        suggestedPitches: suggestedPitches,
        suggestedLoading: false,
      ));
    }
  }

  void selectSize(String size) {
    emit(state.copyWith(selectedSize: size));
  }

  void deselectSize() {
    emit(ProductDetailState(
      status: state.status,
      product: state.product,
      selectedSize: null,
      errorMessage: state.errorMessage,
      suggested: state.suggested,
      suggestedPitches: state.suggestedPitches,
    ));
  }
}
