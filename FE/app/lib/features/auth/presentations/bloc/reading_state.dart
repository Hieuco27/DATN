import 'package:equatable/equatable.dart';
import '../providers/reading_provider.dart'; // Re-use ReadingItem model

/// States for ReadingBloc
abstract class ReadingState extends Equatable {
  const ReadingState();

  @override
  List<Object?> get props => [];
}

/// State: Reading history is loading
class ReadingLoading extends ReadingState {
  const ReadingLoading();
}

/// State: Reading history loaded
class ReadingData extends ReadingState {
  final List<ReadingItem> items;

  const ReadingData({required this.items});

  @override
  List<Object?> get props => [items];

  ReadingData copyWith({List<ReadingItem>? items}) {
    return ReadingData(items: items ?? this.items);
  }
}
