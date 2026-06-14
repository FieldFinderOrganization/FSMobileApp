import '../../../pitch/domain/entities/pitch_entity.dart';

enum FavoriteListStatus { initial, loading, success, failure }

class FavoriteState {
  /// pitchId đã yêu thích — nguồn sự thật cho nút tim ở mọi nơi.
  final Set<String> favoriteIds;

  /// Danh sách sân đầy đủ cho màn "Sân yêu thích".
  final List<PitchEntity> pitches;

  final FavoriteListStatus status;
  final String errorMessage;

  /// pitchId đang gọi add/remove (chặn double-tap).
  final Set<String> toggling;

  const FavoriteState({
    this.favoriteIds = const {},
    this.pitches = const [],
    this.status = FavoriteListStatus.initial,
    this.errorMessage = '',
    this.toggling = const {},
  });

  bool isFavorite(String pitchId) => favoriteIds.contains(pitchId);

  FavoriteState copyWith({
    Set<String>? favoriteIds,
    List<PitchEntity>? pitches,
    FavoriteListStatus? status,
    String? errorMessage,
    Set<String>? toggling,
  }) {
    return FavoriteState(
      favoriteIds: favoriteIds ?? this.favoriteIds,
      pitches: pitches ?? this.pitches,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      toggling: toggling ?? this.toggling,
    );
  }
}
