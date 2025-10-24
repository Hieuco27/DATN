class CategoryEntity {
  final int categoryId;
  final String name;
  final double? depositRate;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CategoryEntity({
    required this.categoryId,
    required this.name,
    this.depositRate,
    this.deleted = false,
    this.createdAt,
    this.updatedAt,
  });
}