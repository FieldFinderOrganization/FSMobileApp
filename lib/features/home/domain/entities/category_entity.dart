class CategoryEntity {
  final String id;
  final String name;
  final String description;
  final String? parentName; // null = root category

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.description,
    this.parentName,
  });
}
