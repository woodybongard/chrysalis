import 'package:chrysalis_mobile/features/homepage/data/model/home_model.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/usecase/add_group_to_recent_search_usecase.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/usecase/get_recent_search_groups_usecase.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/usecase/search_groups_by_text_usecase.dart';
import 'package:chrysalis_mobile/features/search_groups/presentation/bloc/search_group_event.dart';
import 'package:chrysalis_mobile/features/search_groups/presentation/bloc/search_group_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchGroupBloc extends Bloc<SearchGroupEvent, SearchGroupState> {
  SearchGroupBloc(
    this.getRecentSearchGroupsUseCase,
    this.searchGroupsByTextUseCase,
    this.addGroupToRecentSearchUseCase,
  ) : super(SearchGroupInitial()) {
    on<LoadRecentSearchGroups>(_onLoadRecentSearchGroups);
    on<SearchGroupsByText>(_onSearchGroupsByText);
    on<LoadMoreGroups>(_onLoadMoreGroups);
    on<AddGroupToRecentSearch>(_onAddGroupToRecentSearch);
  }
  final GetRecentSearchGroupsUseCase getRecentSearchGroupsUseCase;
  final SearchGroupsByTextUseCase searchGroupsByTextUseCase;
  final AddGroupToRecentSearchUseCase addGroupToRecentSearchUseCase;

  int _currentPage = 1;
  bool _hasMore = true;
  List<GroupModel> _groups = [];

  Future<void> _onAddGroupToRecentSearch(
    AddGroupToRecentSearch event,
    Emitter<SearchGroupState> emit,
  ) async {
    await addGroupToRecentSearchUseCase(groupId: event.groupId);
    // No state change, no loading/error UI
  }

  Future<void> _onLoadRecentSearchGroups(
    LoadRecentSearchGroups event,
    Emitter<SearchGroupState> emit,
  ) async {
    emit(SearchGroupLoading());
    try {
      _groups = await getRecentSearchGroupsUseCase(limit: event.limit);
      _currentPage = 1;
      _hasMore = _groups.length == event.limit;
      if (_groups.isNotEmpty) {
        emit(
          SearchGroupLoaded(
            groups: _groups,
            page: _currentPage,
            hasMore: _hasMore,
          ),
        );
      } else {
        emit(SearchGroupError('No group Exist'));
      }
    } catch (e) {
      emit(SearchGroupError(e.toString()));
    }
  }

  Future<void> _onSearchGroupsByText(
    SearchGroupsByText event,
    Emitter<SearchGroupState> emit,
  ) async {
    emit(SearchGroupLoading());
    try {
      _currentPage = event.page;
      final results = await searchGroupsByTextUseCase(
        query: event.query,
        page: event.page,
        limit: event.limit,
      );
      _groups = results;
      _hasMore = results.length == event.limit;
      if (_groups.isNotEmpty) {
        emit(
          SearchGroupLoaded(
            groups: _groups,
            page: _currentPage,
            hasMore: _hasMore,
          ),
        );
      } else {
        emit(SearchGroupError('No group Exist'));
      }
    } catch (e) {
      emit(SearchGroupError(e.toString()));
    }
  }

  Future<void> _onLoadMoreGroups(
    LoadMoreGroups event,
    Emitter<SearchGroupState> emit,
  ) async {
    if (!_hasMore) return;
    emit(
      SearchGroupLoadingMore(
        groups: _groups,
        query: event.query,
        page: _currentPage,
        hasMore: _hasMore,
      ),
    );
    try {
      final nextPage = event.page;
      final results = await searchGroupsByTextUseCase(
        query: event.query,
        page: nextPage,
        limit: event.limit,
      );
      if (results.isNotEmpty) {
        _groups.addAll(results);
        _currentPage = nextPage;
        _hasMore = results.length == event.limit;
      } else {
        _hasMore = false;
      }
      emit(
        SearchGroupLoaded(
          groups: _groups,
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
