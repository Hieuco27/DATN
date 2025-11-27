class FavoriteItemModel {
  final int documentId;
  final String title;
  final String coverPhoto;

  FavoriteItemModel({
    required this.documentId,
    required this.title,
    required this.coverPhoto,
  });

  factory FavoriteItemModel.fromJson(Map<String, dynamic> json) {
    return FavoriteItemModel(
      documentId: json['documentId'] as int,
      title: json['title'] as String? ?? '',
      coverPhoto: json['coverPhoto'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'title': title,
      'coverPhoto': coverPhoto,
    };
  }
}
