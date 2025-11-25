import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'wishlist_event.dart';
import 'wishlist_state.dart';
import '../providers/wishlist_provider.dart'; // Re-use WishlistItem model

/// WishlistBloc - Manages wishlist state
/// 
/// Replaces WishlistProvider with BLoC pattern
/// Business logic giữ nguyên 100%
class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  static const String _storageKey = 'wishlist_items_v1';

  WishlistBloc() : super(const WishlistLoading()) {
    on<WishlistLoaded>(_onLoaded);
    on<WishlistItemToggled>(_onItemToggled);
    on<WishlistItemRemoved>(_onItemRemoved);
    on<WishlistCleared>(_onCleared);

    // Auto-load on initialization
    add(const WishlistLoaded());
  }

  /// Handle: Load wishlist from storage
  /// Logic giữ nguyên từ WishlistProvider._load()
  Future<void> _onLoaded(
    WishlistLoaded event,
    Emitter<WishlistState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null) {
      emit(const WishlistData(items: []));
      return;
    }

    try {
      final List list = json.decode(raw) as List;
      final items = list
          .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(WishlistData(items: items));
    } catch (_) {
      emit(const WishlistData(items: []));
    }
  }

  /// Handle: Toggle item in wishlist
  /// Logic giữ nguyên từ WishlistProvider.toggle()
  Future<void> _onItemToggled(
    WishlistItemToggled event,
    Emitter<WishlistState> emit,
  ) async {
    if (state is! WishlistData) return;

    final currentState = state as WishlistData;
    final items = List<WishlistItem>.from(currentState.items);

    final idx = items.indexWhere((e) => e.documentId == event.item.documentId);
    if (idx >= 0) {
      items.removeAt(idx);
    } else {
      items.insert(0, event.item);
    }

    emit(WishlistData(items: items));
    await _persist(items);
  }

  /// Handle: Remove item from wishlist
  /// Logic giữ nguyên từ WishlistProvider.remove()
  Future<void> _onItemRemoved(
    WishlistItemRemoved event,
    Emitter<WishlistState> emit,
  ) async {
    if (state is! WishlistData) return;

    final currentState = state as WishlistData;
    final items = List<WishlistItem>.from(currentState.items);

    items.removeWhere((e) => e.documentId == event.documentId);

    emit(WishlistData(items: items));
    await _persist(items);
  }

  /// Handle: Clear wishlist
  /// Logic giữ nguyên từ WishlistProvider.clear()
  Future<void> _onCleared(
    WishlistCleared event,
    Emitter<WishlistState> emit,
  ) async {
    emit(const WishlistData(items: []));
    await _persist([]);
  }

  /// Persist to SharedPreferences
  /// Logic giữ nguyên từ WishlistProvider._persist()
  Future<void> _persist(List<WishlistItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
