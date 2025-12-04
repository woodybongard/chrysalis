import 'package:chrysalis_mobile/features/search_groups/domain/entity/search_result_entity.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/usecase/add_group_to_recent_search_usecase.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/usecase/get_recent_search_groups_usecase.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/usecase/search_groups_by_text_usecase.dart';
import 'package:chrysalis_mobile/features/search_groups/presentation/bloc/search_group_event.dart';
import 'package:chrysalis_mobile/features/search_groups/presentation/bloc/search_group_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchGroupBloc extends Bloc<SearchGroupEvent, SearchGroupState> {
  SearchGroupBloc(
    this.getRecentSearchesUseCase,
    this.searchUseCase,
    this.addToRecentSearchUseCase,
  ) : super(SearchGroupInitial()) {
    on<LoadRecentSearches>(_onLoadRecentSearches);
    on<PerformSearch>(_onPerformSearch);
    on<LoadMoreResults>(_onLoadMoreResults);
    on<AddToRecentSearch>(_onAddToRecentSearch);
  }

  final GetRecentSearchesUseCase getRecentSearchesUseCase;
  final SearchUseCase searchUseCase;
  final AddToRecentSearchUseCase addToRecentSearchUseCase;

  int _currentPage = 1;
  bool _hasMore = true;
  List<SearchResultEntity> _results = [];

  Future<void> _onAddToRecentSearch(
    AddToRecentSearch event,
    Emitter<SearchGroupState> emit,
  ) async {
    await addToRecentSearchUseCase(result: event.result);
    // No state change, no loading/error UI
  }

  Future<void> _onLoadRecentSearches(
    LoadRecentSearches event,
    Emitter<SearchGroupState> emit,
  ) async {
    emit(SearchGroupLoading());
    try {
      _results = await getRecentSearchesUseCase(limit: event.limit);
      _currentPage = 1;
      _hasMore = _results.length == event.limit;
      emit(
        SearchGroupLoaded(
          results: _results,
          page: _currentPage,
          hasMore: _hasMore,
        ),
      );
    } catch (e) {
      emit(SearchGroupError(e.toString()));
    }
  }

  Future<void> _onPerformSearch(
    PerformSearch event,
    Emitter<SearchGroupState> emit,
  ) async {
    emit(SearchGroupLoading());
    try {
      _currentPage = event.page;
      final results = await searchUseCase(
        query: event.query,
        page: event.page,
        limit: event.limit,
      );
      _results = results;
      _hasMore = results.length == event.limit;
      emit(
        SearchGroupLoaded(
          results: _results,
          query: event.query,
          page: _currentPage,
          hasMore: _hasMore,
        ),
      );
    } catch (e) {
      emit(SearchGroupError(e.toString()));
    }
  }

  Future<void> _onLoadMoreResults(
    LoadMoreResults event,
    Emitter<SearchGroupState> emit,
  ) async {
    if (!_hasMore) return;
    emit(
      SearchGroupLoadingMore(
        results: _results,
        query: event.query,
        page: _currentPage,
        hasMore: _hasMore,
      ),
    );
    try {
      final nextPage = event.page;
      final results = await searchUseCase(
        query: event.query,
        page: nextPage,
        limit: event.limit,
      );
      if (results.isNotEmpty) {
        _results = [..._results, ...results];
        _currentPage = nextPage;
        _hasMore = results.length == event.limit;
      } else {
        _hasMore = false;
      }
      emit(
        SearchGroupLoaded(
          results: _results,
          query: event.query,
          page: _currentPage,
          hasMore: _hasMore,
        ),
      );
    } catch (e) {
      emit(SearchGroupError(e.toString()));
    }
  }
}
