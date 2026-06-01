import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/search_history_remote_datasource.dart';
import '../../domain/entities/search_history_entity.dart';

class SearchHistoryState extends Equatable {
  final List<SearchHistoryEntity> items;
  final bool loading;
  final String? error;

  const SearchHistoryState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  SearchHistoryState copyWith({
    List<SearchHistoryEntity>? items,
    bool? loading,
    String? error,
  }) {
    return SearchHistoryState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [items, loading, error];
}

class SearchHistoryCubit extends Cubit<SearchHistoryState> {
  final SearchHistoryRemoteDatasource _datasource;

  SearchHistoryCubit(this._datasource) : super(const SearchHistoryState());

  Future<void> load({int limit = 10}) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await _datasource.fetchHistory(limit: limit);
      if (isClosed) return;
      emit(state.copyWith(items: items, loading: false));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> add(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    try {
      final added = await _datasource.upsert(trimmed);
      if (isClosed) return;
      final newList = [
        added,
        ...state.items.where((e) => e.keyword != added.keyword),
      ];
      emit(state.copyWith(items: newList.take(10).toList()));
    } catch (_) {
      // Silent fail — history nice-to-have
    }
  }

  Future<void> remove(String id) async {
    final prev = state.items;
    emit(state.copyWith(items: prev.where((e) => e.id != id).toList()));
    try {
      await _datasource.delete(id);
    } catch (_) {
      emit(state.copyWith(items: prev));
    }
  }

  Future<void> clearAll() async {
    final prev = state.items;
    emit(state.copyWith(items: const []));
    try {
      await _datasource.clear();
    } catch (_) {
      emit(state.copyWith(items: prev));
    }
  }
}
