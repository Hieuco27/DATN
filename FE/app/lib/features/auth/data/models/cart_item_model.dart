import 'package:equatable/equatable.dart';

class CartItemModel extends Equatable {
  final int documentId;
  final String title;
  final String coverPhoto;
  final int quantity;
  final int? minDeposit;
  final int? maxDeposit;

  const CartItemModel({
    required this.documentId,
    required this.title,
    required this.coverPhoto,
    required this.quantity,
    this.minDeposit,
    this.maxDeposit,
  });

  // copyWith method for immutable updates
  CartItemModel copyWith({
    int? documentId,
    String? title,
    String? coverPhoto,
    int? quantity,
    int? minDeposit,
    int? maxDeposit,
  }) {
    return CartItemModel(
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      coverPhoto: coverPhoto ?? this.coverPhoto,
      quantity: quantity ?? this.quantity,
      minDeposit: minDeposit ?? this.minDeposit,
      maxDeposit: maxDeposit ?? this.maxDeposit,
    );
  }

  // fromJson for deserialization
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      documentId: json['documentId'] as int,
      title: json['title'] as String? ?? '',
      coverPhoto: json['coverPhoto'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      minDeposit: json['minDeposit'] as int?,
      maxDeposit: json['maxDeposit'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'documentId': documentId,
    'quantity': quantity,
  };

  @override
  List<Object?> get props => [
        documentId,
        title,
        coverPhoto,
        quantity,
        minDeposit,
        maxDeposit,
      ];
}
