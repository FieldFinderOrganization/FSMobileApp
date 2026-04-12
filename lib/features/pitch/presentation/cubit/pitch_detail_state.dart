import 'package:equatable/equatable.dart';
import '../../domain/entities/pitch_entity.dart';
import '../../domain/entities/review_entity.dart';

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

  const PitchDetailSuccess({
    required this.pitch,
    required this.reviews,
  });

  @override
  List<Object?> get props => [pitch, reviews];
}

class PitchDetailFailure extends PitchDetailState {
  final String message;

  const PitchDetailFailure(this.message);

  @override
  List<Object?> get props => [message];
}
