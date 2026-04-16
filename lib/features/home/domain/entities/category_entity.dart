class CategoryEntity {
  final String id;
  final String name;
  final String description;
  final String? parentName; // null = root category
  final String? categoryType; // STANDARD, SUPER_CATEGORY, BRAND

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.description,
    this.parentName,
    this.categoryType,
  });
}
