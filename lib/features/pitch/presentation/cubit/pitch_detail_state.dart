import 'package:equatable/equatable.dart';
import '../../domain/entities/pitch_entity.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/entities/suggested_pitches_entity.dart';
import '../../../product/domain/entities/product_entity.dart';

abstract class PitchDetailState extends Equatable {
  const PitchDetailState();

  @override
  List<Object?> get props => [];
}

class PitchDetailInitial extends PitchDetailState {}

class PitchDetailLoading extends PitchDetailState {}

class PitchDetailSuccess extends PitchDetailState {
  final PitchEntity pitch;
  final List<ReviewEntity> reviews;
  final SuggestedPitchesEntity suggested;
  final List<ProductEntity> suggestedProducts;
  final bool suggestedLoading;

  const PitchDetailSuccess({
    required this.pitch,
    required this.reviews,
    this.suggested = const SuggestedPitchesEntity(),
    this.suggestedProducts = const [],
    this.suggestedLoading = false,
  });

  PitchDetailSuccess copyWith({
    PitchEntity? pitch,
    List<ReviewEntity>? reviews,
    SuggestedPitchesEntity? suggested,
    List<ProductEntity>? suggestedProducts,
    bool? suggestedLoading,
  }) {
    return PitchDetailSuccess(
      pitch: pitch ?? this.pitch,
      reviews: reviews ?? this.reviews,
      suggested: suggested ?? this.suggested,
      suggestedProducts: suggestedProducts ?? this.suggestedProducts,
      suggestedLoading: suggestedLoading ?? this.suggestedLoading,
    );
  }

  @override
  List<Object?> get props =>
      [pitch, reviews, suggested, suggestedProducts, suggestedLoading];
}

class PitchDetailFailure extends PitchDetailState {
  final String message;

  const PitchDetailFailure(this.message);

  @override
  List<Object?> get props => [message];
}
