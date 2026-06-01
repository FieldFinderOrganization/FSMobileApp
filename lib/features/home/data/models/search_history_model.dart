import '../../domain/entities/search_history_entity.dart';

class SearchHistoryModel extends SearchHistoryEntity {
  const SearchHistoryModel({
    required super.id,
    required super.keyword,
    required super.lastSearchedAt,
  });

  factory SearchHistoryModel.fromJson(Map<String, dynamic> json) {
    return SearchHistoryModel(
      id: json['id']?.toString() ?? '',
      keyword: json['keyword'] as String? ?? '',
      lastSearchedAt: DateTime.tryParse(json['lastSearchedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
