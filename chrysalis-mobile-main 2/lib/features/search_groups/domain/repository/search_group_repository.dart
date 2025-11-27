import 'package:chrysalis_mobile/features/homepage/data/model/home_model.dart';

abstract class SearchGroupRepository {
  Future<List<GroupModel>> getRecentSearchGroups({int limit});
  Future<List<GroupModel>> searchGroupsByText({
    required String query,
    int page,
    int limit,
  });
  Future<void> addGroupToRecentSearch({required String groupId});
}
