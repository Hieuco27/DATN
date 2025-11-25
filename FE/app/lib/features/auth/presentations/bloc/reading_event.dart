import 'package:equatable/equatable.dart';
import '../providers/reading_provider.dart'; // Re-use ReadingItem model

/// Events for ReadingBloc
abstract class ReadingEvent extends Equatable {
  const ReadingEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Load reading history from storage
class ReadingLoaded extends ReadingEvent {
  const ReadingLoaded();
}

/// Event: Add or update reading item
class ReadingItemAddedOrUpdated extends ReadingEvent {
  final ReadingItem item;

  const ReadingItemAddedOrUpdated(this.item);

  @override
  List<Object?> get props => [item];
}

/// Event: Remove reading item
class ReadingItemRemoved extends ReadingEvent {
  final int documentId;

  const ReadingItemRemoved(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

/// Event: Clear reading history
class ReadingCleared extends ReadingEvent {
  const ReadingCleared();
}
