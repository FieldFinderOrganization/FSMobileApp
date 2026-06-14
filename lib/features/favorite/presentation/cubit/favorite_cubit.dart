import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../pitch/domain/entities/pitch_entity.dart';
import '../../domain/repositories/favorite_repository.dart';
import 'favorite_state.dart';

/// Cubit global: giữ tập pitchId yêu thích (cho nút tim) + danh sách sân (màn list).
/// Đăng ký 1 lần trong main.dart, gọi loadIds() sau login.
class FavoriteCubit extends Cubit<FavoriteState> {
  final FavoriteRepository _repository;

  FavoriteCubit({required FavoriteRepository repository})
      : _repository = repository,
        super(const FavoriteState());

  /// Xoá state khi logout — tránh rò favorite của user cũ sang user mới.
  void reset() => emit(const FavoriteState());

  /// Nạp tập id yêu thích (nhẹ) — gọi sau khi đăng nhập để nút tim đúng trạng thái.
  Future<void> loadIds() async {
    try {
      final ids = await _repository.getFavoriteIds();
      emit(state.copyWith(favoriteIds: ids.toSet()));
    } catch (_) {
      // Im lặng: tim mặc định rỗng, không chặn UX.
    }
  }

  /// Nạp danh sách sân đầy đủ cho màn "Sân yêu thích".
  Future<void> loadPitches() async {
    emit(state.copyWith(status: FavoriteListStatus.loading));
    try {
      final pitches = await _repository.getFavoritePitches();
      emit(state.copyWith(
        status: FavoriteListStatus.success,
        pitches: pitches,
        favoriteIds: pitches.map((p) => p.pitchId).toSet(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FavoriteListStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Bật/tắt yêu thích. Optimistic: cập nhật UI ngay, rollback nếu API lỗi.
  Future<void> toggle(String pitchId) async {
    if (state.toggling.contains(pitchId)) return;

    final wasFavorite = state.favoriteIds.contains(pitchId);
    final newIds = Set<String>.from(state.favoriteIds);
    List<PitchEntity> newPitches = state.pitches;

    if (wasFavorite) {
      newIds.remove(pitchId);
      // Gỡ khỏi danh sách hiển thị (nếu đang ở màn list).
      newPitches =
          state.pitches.where((p) => p.pitchId != pitchId).toList();
    } else {
      newIds.add(pitchId);
    }

    emit(state.copyWith(
      favoriteIds: newIds,
      pitches: newPitches,
      toggling: {...state.toggling, pitchId},
    ));

    try {
      if (wasFavorite) {
        await _repository.remove(pitchId);
      } else {
        await _repository.add(pitchId);
      }
      emit(state.copyWith(toggling: {...state.toggling}..remove(pitchId)));
    } catch (e) {
      // Rollback set; danh sách pitches sẽ đồng bộ lại ở lần loadPitches kế.
      final rolledBack = Set<String>.from(state.favoriteIds);
      if (wasFavorite) {
        rolledBack.add(pitchId);
      } else {
        rolledBack.remove(pitchId);
      }
      emit(state.copyWith(
        favoriteIds: rolledBack,
        toggling: {...state.toggling}..remove(pitchId),
        errorMessage: e.toString(),
      ));
    }
  }
}
