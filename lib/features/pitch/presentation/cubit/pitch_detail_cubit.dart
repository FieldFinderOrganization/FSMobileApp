import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/pitch_repository.dart';
import '../../domain/entities/pitch_entity.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/entities/suggested_pitches_entity.dart';
import '../../../product/domain/repositories/product_repository.dart';
import '../../../product/domain/entities/product_entity.dart';
import 'pitch_detail_state.dart';

class PitchDetailCubit extends Cubit<PitchDetailState> {
  final PitchRepository pitchRepository;
  final ProductRepository productRepository;

  PitchDetailCubit(this.pitchRepository, this.productRepository) : super(PitchDetailInitial());

  Future<void> loadPitchDetails(String id) async {
    emit(PitchDetailLoading());
    try {
      final results = await Future.wait([
        pitchRepository.getPitchById(id),
        pitchRepository.getReviewsByPitch(id),
      ]);

      emit(PitchDetailSuccess(
        pitch: results[0] as PitchEntity,
        reviews: results[1] as List<ReviewEntity>,
      ));
    } catch (e) {
      emit(PitchDetailFailure(e.toString()));
    }
  }

  Future<void> loadSuggested(String pitchId, {double? lat, double? lng}) async {
    final current = state;
    if (current is! PitchDetailSuccess) return;
    debugPrint("[CUBIT_SUGGEST] loadSuggested start pitchId=$pitchId lat=$lat lng=$lng");
    if (!isClosed) emit(current.copyWith(suggestedLoading: true));

    // Tách 2 call độc lập: 1 cái lỗi không được xoá cái còn lại.
    SuggestedPitchesEntity suggestedPitches = const SuggestedPitchesEntity();
    List<ProductEntity> suggestedProducts = const [];

    try {
      suggestedPitches = await pitchRepository.getSuggested(
        pitchId,
        lat: lat,
        lng: lng,
      );
    } catch (e, stack) {
      debugPrint("[CUBIT_SUGGEST] getSuggested(pitches) FAILED pitchId=$pitchId: $e");
      debugPrint("$stack");
    }

    try {
      suggestedProducts = await productRepository.getSuggestedForPitch();
    } catch (e, stack) {
      debugPrint("[CUBIT_SUGGEST] getSuggestedForPitch(products) FAILED: $e");
      debugPrint("$stack");
    }

    debugPrint(
      "[CUBIT_SUGGEST] counts pitches nearby=${suggestedPitches.nearby.length} "
      "topRated=${suggestedPitches.topRated.length} visited=${suggestedPitches.visited.length} "
      "products=${suggestedProducts.length}",
    );

    if (!isClosed) {
      emit(current.copyWith(
        suggested: suggestedPitches,
        suggestedProducts: suggestedProducts,
        suggestedLoading: false,
      ));
    }
  }
}
