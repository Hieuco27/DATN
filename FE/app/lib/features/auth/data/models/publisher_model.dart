import '../../domain/entities/publisher_entity.dart';
class PublisherModel extends PublisherEntity {
  const PublisherModel({
    required super.publisherId,
    required super.name,
    required super.note,
    super.deleted = false,
    super.createdAt,
    super.updatedAt,
  });
  
  factory PublisherModel.fromJson(Map<String, dynamic> json) => PublisherModel(
    publisherId: json['publisherId'],
    name: json['name'],
    note: json['note'],
    deleted: json['deleted'],
    createdAt: json['createdAt'],
    updatedAt: json['updatedAt'],
  );
      
}