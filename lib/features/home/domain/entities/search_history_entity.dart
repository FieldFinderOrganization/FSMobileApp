class SearchHistoryEntity {
  final String id;
  final String keyword;
  final DateTime lastSearchedAt;

  const SearchHistoryEntity({
    required this.id,
    required this.keyword,
    required this.lastSearchedAt,
  });
}
