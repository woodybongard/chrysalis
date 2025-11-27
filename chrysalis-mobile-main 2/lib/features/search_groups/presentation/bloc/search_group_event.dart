import 'package:equatable/equatable.dart';

class AddGroupToRecentSearch extends SearchGroupEvent {
  AddGroupToRecentSearch({required this.groupId});
  final String groupId;
  @override
  List<Object?> get props => [groupId];
}

abstract class SearchGroupEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadRecentSearchGroups extends SearchGroupEvent {
  LoadRecentSearchGroups({this.limit = 10});
  final int limit;
  @override
  List<Object?> get props => [limit];
}

class SearchGroupsByText extends SearchGroupEvent {
  SearchGroupsByText({required this.query, this.page = 1, this.limit = 10});
  final String query;
  final int page;
  final int limit;
  @override
  List<Object?> get props => [query, page, limit];
}

class LoadMoreGroups extends SearchGroupEvent {
  LoadMoreGroups({required this.query, required this.page, this.limit = 10});
  final String query;
  final int page;
  final int limit;
  @override
  List<Object?> get props => [query, page, limit];
}
