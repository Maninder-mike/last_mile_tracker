import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'tracker_providers.dart';

part 'optimistic_favorites_provider.g.dart';

@riverpod
class OptimisticFavorites extends _$OptimisticFavorites {
  @override
  Map<String, bool> build() => {};

  Future<void> toggleFavorite(String id, bool currentState) async {
    // 1. Set optimistic state
    final newValue = !currentState;
    state = {...state, id: newValue};

    try {
      // 2. Persist to repository
      await ref.read(trackerRepositoryProvider).updateFavorite(id, newValue);
    } catch (e) {
      // 3. Rollback on error
      state = Map.from(state)..remove(id);
      rethrow;
    } finally {
      // 4. Optional: Clear optimistic state after a delay to let the stream catch up
      // In a real app, you might want to wait for the stream to emit the new value
      // but for simplicity, we'll clear it after 500ms.
      Future.delayed(const Duration(milliseconds: 500), () {
        state = Map.from(state)..remove(id);
      });
    }
  }
}

@riverpod
bool isFavorite(Ref ref, String id) {
  final optimisticState = ref.watch(optimisticFavoritesProvider);

  // If we have an optimistic override, use it
  if (optimisticState.containsKey(id)) {
    return optimisticState[id]!;
  }

  // Otherwise, fallback to the database state
  // We need to find the tracker in the list
  final trackersAsync = ref.watch(allTrackersProvider);
  return trackersAsync.maybeWhen(
    data: (trackers) => trackers.any((t) => t.id == id && t.isFavorite),
    orElse: () => false,
  );
}
