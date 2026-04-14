import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/product_repository.dart';
import 'product_detail_state.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  final ProductRepository _repository;

  ProductDetailCubit({required ProductRepository repository})
      : _repository = repository,
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

  void selectSize(String size) {
    emit(state.copyWith(selectedSize: size));
  }
}
