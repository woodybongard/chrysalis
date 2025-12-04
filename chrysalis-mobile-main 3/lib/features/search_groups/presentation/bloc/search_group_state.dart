import 'package:chrysalis_mobile/features/search_groups/domain/entity/search_result_entity.dart';
import 'package:equatable/equatable.dart';

abstract class SearchGroupState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SearchGroupInitial extends SearchGroupState {}

class SearchGroupLoading extends SearchGroupState {}

class SearchGroupLoaded extends SearchGroupState {
  SearchGroupLoaded({
    required this.results,
    this.query,
    this.page = 1,
    this.hasMore = true,
  });
  final List<SearchResultEntity> results;
  final String? query;
  final int page;
  final bool hasMore;
  @override
  List<Object?> get props => [results, query, page, hasMore];
}

class SearchGroupLoadingMore extends SearchGroupLoaded {
  SearchGroupLoadingMore({
    required super.results,
    super.query,
    super.page,
    super.hasMore,
  });
}

class SearchGroupError extends SearchGroupState {
  SearchGroupError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
