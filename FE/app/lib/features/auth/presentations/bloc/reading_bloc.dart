import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reading_event.dart';
import 'reading_state.dart';
import '../providers/reading_provider.dart'; // Re-use ReadingItem model

/// ReadingBloc - Manages reading history state
/// 
/// Replaces ReadingProvider with BLoC pattern
/// Business logic giữ nguyên 100%
class ReadingBloc extends Bloc<ReadingEvent, ReadingState> {
  static const String _storageKey = 'reading_items_v1';

  ReadingBloc() : super(const ReadingLoading()) {
    on<ReadingLoaded>(_onLoaded);
    on<ReadingItemAddedOrUpdated>(_onItemAddedOrUpdated);
    on<ReadingItemRemoved>(_onItemRemoved);
    on<ReadingCleared>(_onCleared);

    // Auto-load on initialization
    add(const ReadingLoaded());
  }

  /// Handle: Load reading history from storage
  /// Logic giữ nguyên từ ReadingProvider._load()
  Future<void> _onLoaded(
    ReadingLoaded event,
    Emitter<ReadingState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null) {
      emit(const ReadingData(items: []));
      return;
    }

    try {
      final List list = json.decode(raw) as List;
      final items = list
          .map((e) => ReadingItem.fromJson(e as Map<String, dynamic>))
          .toList();

      // Sort by latest startedAt desc (business logic giữ nguyên)
      items.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      emit(ReadingData(items: items));
    } catch (_) {
      emit(const ReadingData(items: []));
    }
  }

  /// Handle: Add or update reading item
  /// Logic giữ nguyên từ ReadingProvider.addOrUpdate()
  Future<void> _onItemAddedOrUpdated(
    ReadingItemAddedOrUpdated event,
    Emitter<ReadingState> emit,
  ) async {
    if (state is! ReadingData) return;

    final currentState = state as ReadingData;
    final items = List<ReadingItem>.from(currentState.items);

    final idx = items.indexWhere((e) => e.documentId == event.item.documentId);
    if (idx >= 0) {
      items.removeAt(idx);
    }
    items.insert(0, event.item);

    emit(ReadingData(items: items));
    await _persist(items);
  }

  /// Handle: Remove reading item
  /// Logic giữ nguyên từ ReadingProvider.remove()
  Future<void> _onItemRemoved(
    ReadingItemRemoved event,
    Emitter<ReadingState> emit,
  ) async {
    if (state is! ReadingData) return;

    final currentState = state as ReadingData;
    final items = List<ReadingItem>.from(currentState.items);

    items.removeWhere((e) => e.documentId == event.documentId);

    emit(ReadingData(items: items));
    await _persist(items);
  }

  /// Handle: Clear reading history
  /// Logic giữ nguyên từ ReadingProvider.clear()
  Future<void> _onCleared(
    ReadingCleared event,
    Emitter<ReadingState> emit,
  ) async {
    emit(const ReadingData(items: []));
    await _persist([]);
  }

  /// Persist to SharedPreferences
  /// Logic giữ nguyên từ ReadingProvider._persist()
  Future<void> _persist(List<ReadingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
