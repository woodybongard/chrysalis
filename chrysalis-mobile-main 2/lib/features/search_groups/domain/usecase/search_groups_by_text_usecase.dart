import 'package:chrysalis_mobile/features/homepage/data/model/home_model.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/repository/search_group_repository.dart';

class SearchGroupsByTextUseCase {
  SearchGroupsByTextUseCase(this.repository);
  final SearchGroupRepository repository;

  Future<List<GroupModel>> call({
    required String query,
    int page = 1,
    int limit = 10,
  }) {
    return repository.searchGroupsByText(
      query: query,
      page: page,
      limit: limit,
    );
  }
}
