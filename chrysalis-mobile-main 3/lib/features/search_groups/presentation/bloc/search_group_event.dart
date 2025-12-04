import 'package:chrysalis_mobile/features/search_groups/domain/entity/search_result_entity.dart';
import 'package:equatable/equatable.dart';

abstract class SearchGroupEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadRecentSearches extends SearchGroupEvent {
  LoadRecentSearches({this.limit = 10});
  final int limit;
  @override
  List<Object?> get props => [limit];
}

class PerformSearch extends SearchGroupEvent {
  PerformSearch({required this.query, this.page = 1, this.limit = 10});
  final String query;
  final int page;
  final int limit;
  @override
  List<Object?> get props => [query, page, limit];
}

class LoadMoreResults extends SearchGroupEvent {
  LoadMoreResults({required this.query, required this.page, this.limit = 10});
  final String query;
  final int page;
  final int limit;
  @override
  List<Object?> get props => [query, page, limit];
}

class AddToRecentSearch extends SearchGroupEvent {
  AddToRecentSearch({required this.result});
  final SearchResultEntity result;
  @override
  List<Object?> get props => [result];
}
