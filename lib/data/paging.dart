import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable state for an infinite-scroll list.
class PagedState<T> {
  const PagedState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  bool get isEmpty => items.isEmpty;

  PagedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) =>
      PagedState<T>(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Fetches one page: [offset] rows already loaded, return up to [limit] more.
typedef PageFetcher<T> = Future<List<T>> Function(int offset, int limit);

/// Generic infinite-scroll controller. Recreated by its provider whenever the
/// underlying filters change (so a new query starts fresh).
class PagedNotifier<T> extends StateNotifier<PagedState<T>> {
  PagedNotifier(this._fetch, {this.pageSize = 25})
      : super(PagedState<T>(isLoading: true)) {
    _load(reset: true);
  }

  final PageFetcher<T> _fetch;
  final int pageSize;

  Future<void> refresh() => _load(reset: true);

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    await _load(reset: false);
  }

  Future<void> _load({required bool reset}) async {
    state = reset
        ? state.copyWith(isLoading: true, clearError: true)
        : state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final offset = reset ? 0 : state.items.length;
      final page = await _fetch(offset, pageSize);
      final items = reset ? page : [...state.items, ...page];
      state = PagedState<T>(items: items, hasMore: page.length >= pageSize);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e,
      );
    }
  }
}
