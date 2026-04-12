import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/pitch_repository.dart';
import '../../domain/entities/pitch_entity.dart';
import '../../domain/entities/review_entity.dart';
import 'pitch_detail_state.dart';

class PitchDetailCubit extends Cubit<PitchDetailState> {
  final PitchRepository pitchRepository;

  PitchDetailCubit(this.pitchRepository) : super(PitchDetailInitial());

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
}
