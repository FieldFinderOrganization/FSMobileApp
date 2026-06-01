import 'pitch_entity.dart';

class SuggestedPitchesEntity {
  final List<PitchEntity> nearby;
  final List<PitchEntity> topRated;
  final List<PitchEntity> visited;

  const SuggestedPitchesEntity({
    this.nearby = const [],
    this.topRated = const [],
    this.visited = const [],
  });

  bool get isEmpty => nearby.isEmpty && topRated.isEmpty && visited.isEmpty;
}
