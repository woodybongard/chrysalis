import 'package:chrysalis_mobile/features/search_groups/domain/entity/search_result_entity.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/repository/search_group_repository.dart';

class AddToRecentSearchUseCase {
  AddToRecentSearchUseCase(this.repository);
  final SearchGroupRepository repository;

  Future<void> call({required SearchResultEntity result}) {
    return repository.addToRecentSearch(result: result);
  }
}
