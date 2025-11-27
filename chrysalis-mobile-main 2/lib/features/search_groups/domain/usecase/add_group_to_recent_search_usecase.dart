import 'package:chrysalis_mobile/features/search_groups/domain/repository/search_group_repository.dart';

class AddGroupToRecentSearchUseCase {
  AddGroupToRecentSearchUseCase(this.repository);
  final SearchGroupRepository repository;

  Future<void> call({required String groupId}) {
    return repository.addGroupToRecentSearch(groupId: groupId);
  }
}
