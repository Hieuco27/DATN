import 'package:equatable/equatable.dart';

class CartItemModel extends Equatable {
  final int documentId;
  final String title; 
  final String coverPhoto;
 

  const CartItemModel({
    required this.documentId,
    required this.title,
    required this.coverPhoto,
   
  });

  // copyWith method for immutable updates
  CartItemModel copyWith({
    int? documentId,
    String? title,
    String? coverPhoto,
  
    
  }) {
    return CartItemModel(
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      coverPhoto: coverPhoto ?? this.coverPhoto,
     
    );
  }

  // fromJson for deserialization
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      documentId: json['documentId'] as int,
      title: json['title'] as String? ?? '',
      coverPhoto: json['coverPhoto'] as String? ?? '',
     
    );
  }

  Map<String, dynamic> toJson() => {
    'documentId': documentId,
    'title': title,
    'coverPhoto': coverPhoto,
  };

  @override
  List<Object?> get props => [
        documentId,
        title,
          coverPhoto,
      ];
}
