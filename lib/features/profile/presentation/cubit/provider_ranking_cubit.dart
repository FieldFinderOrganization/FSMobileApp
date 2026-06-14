import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/pitch_ranking_model.dart';
import '../../domain/repositories/provider_repository.dart';

abstract class ProviderRankingState extends Equatable {
  const ProviderRankingState();
  @override
  List<Object?> get props => [];
}

class ProviderRankingInitial extends ProviderRankingState {}

class ProviderRankingLoading extends ProviderRankingState {}

class ProviderRankingLoaded extends ProviderRankingState {
  final List<PitchRankingModel> pitches;
  const ProviderRankingLoaded(this.pitches);
  @override
  List<Object?> get props => [pitches];
}

class ProviderRankingError extends ProviderRankingState {
  final String message;
  const ProviderRankingError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Tải bảng xếp hạng sân của provider (đặt nhiều / đánh giá cao / doanh thu cao).
/// Sắp xếp cụ thể từng bảng được thực hiện ở UI từ cùng một danh sách.
class ProviderRankingCubit extends Cubit<ProviderRankingState> {
  final ProviderRepository repository;
  final String providerId;

  ProviderRankingCubit({
    required this.repository,
    required this.providerId,
  }) : super(ProviderRankingInitial());

  Future<void> load() async {
    emit(ProviderRankingLoading());
    try {
      final pitches = await repository.getPitchRankings(providerId);
      emit(ProviderRankingLoaded(pitches));
    } on DioException catch (e) {
      emit(ProviderRankingError(
          e.response?.data?['message'] ?? e.message ?? 'Lỗi tải dữ liệu'));
    } catch (e) {
      emit(ProviderRankingError(e.toString()));
    }
  }
}
