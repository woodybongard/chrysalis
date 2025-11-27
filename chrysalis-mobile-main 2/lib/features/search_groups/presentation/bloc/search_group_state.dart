import 'package:chrysalis_mobile/features/homepage/data/model/home_model.dart';
import 'package:equatable/equatable.dart';

abstract class SearchGroupState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SearchGroupInitial extends SearchGroupState {}

class SearchGroupLoading extends SearchGroupState {}

class SearchGroupLoaded extends SearchGroupState {
  SearchGroupLoaded({
    required this.groups,
    this.query,
    this.page = 1,
    this.hasMore = true,
  });
  final List<GroupModel> groups;
  final String? query;
  final int page;
  final bool hasMore;
  @override
  List<Object?> get props => [groups, query, page, hasMore];
}

class SearchGroupLoadingMore extends SearchGroupLoaded {
  SearchGroupLoadingMore({
    required super.groups,
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
