class CartItemModel {
  final int documentId;
  final String title;
  final String coverPhoto;
  final int quantity;
  final int? minDeposit;
  final int? maxDeposit;

  CartItemModel({
    required this.documentId,
    required this.title,
    required this.coverPhoto,
    required this.quantity,
    this.minDeposit,
    this.maxDeposit,
  });


  Map<String, dynamic> toJson() => {
    'documentId': documentId,
    'quantity': quantity,
  };
}
