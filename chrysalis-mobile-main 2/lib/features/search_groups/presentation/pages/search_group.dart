import 'dart:developer';

import 'package:chrysalis_mobile/core/constants/app_assets.dart';
import 'package:chrysalis_mobile/core/crypto_services/crypto_service.dart';
import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/core/socket/chat_list_helper.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/chat_detail_args.dart';
import 'package:chrysalis_mobile/features/homepage/data/model/home_model.dart';
import 'package:chrysalis_mobile/features/search_groups/presentation/bloc/search_group_bloc.dart';
import 'package:chrysalis_mobile/features/search_groups/presentation/bloc/search_group_event.dart';
import 'package:chrysalis_mobile/features/search_groups/presentation/bloc/search_group_state.dart';
import 'package:chrysalis_mobile/features/search_groups/presentation/widgets/search_group_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class SearchGroupPage extends StatefulWidget {
  const SearchGroupPage({super.key});

  @override
  State<SearchGroupPage> createState() => _SearchGroupPageState();
}

class _SearchGroupPageState extends State<SearchGroupPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<SearchGroupBloc>().add(LoadRecentSearchGroups());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final bloc = context.read<SearchGroupBloc>();
    final state = bloc.state;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (state is SearchGroupLoaded && state.hasMore) {
        if (state.query != null && state.query!.isNotEmpty) {
          bloc.add(LoadMoreGroups(query: state.query!, page: state.page + 1));
        }
      }
    }
  }

  void _onSearch(String value) {
    final bloc = context.read<SearchGroupBloc>();
    _lastQuery = value.trim();
    if (_lastQuery.isEmpty) {
      bloc.add(LoadRecentSearchGroups());
    } else {
      bloc.add(SearchGroupsByText(query: _lastQuery));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60 * scaleHeight,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 24 * scaleWidth,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0 * scaleWidth),
            child: SizedBox(
              width: double.infinity,
              child: Container(
                height: 48 * scaleHeight,
                decoration: BoxDecoration(
                  color: AppColors.neural100,
                  borderRadius: BorderRadius.circular(10 * scaleWidth),
                ),
                child: TextField(
                  controller: _controller,
                  cursorColor: AppColors.primaryMain,
                  cursorWidth: 1.5 * scaleWidth,
                  cursorHeight: 16 * scaleHeight,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(13.0 * scaleWidth),
                      child: SvgPicture.asset(
                        AppAssets.searchIcon,
                        colorFilter: const ColorFilter.mode(
                          AppColors.neural501,
                          BlendMode.srcIn,
                        ),
                        height: 12 * scaleHeight,
                        width: 12 * scaleWidth,
                      ),
                    ),
                    hintText: 'Search',
                    hintStyle: AppTextStyles.p1regular(context).copyWith(
                      color: AppColors.neural301,
                      fontSize: 16 * scaleHeight,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10.0 * scaleWidth,
                      vertical: 11.0 * scaleHeight,
                    ),
                  ),
                  style: TextStyle(fontSize: 16 * scaleHeight),
                  onSubmitted: _onSearch,
                ),
              ),
            ),
          ),
          SizedBox(height: 24 * scaleHeight),
          Expanded(
            child: BlocBuilder<SearchGroupBloc, SearchGroupState>(
              builder: (context, state) {
                if (state is SearchGroupLoading) {
                  return const SearchGroupShimmer();
                } else if (state is SearchGroupLoaded ||
                    state is SearchGroupLoadingMore) {
                  final isSearch = state is SearchGroupLoaded
                      ? state.query != null && state.query!.isNotEmpty
                      : state is SearchGroupLoadingMore &&
                            state.query != null &&
                            state.query!.isNotEmpty;
                  final groups = state is SearchGroupLoaded
                      ? state.groups
                      : state is SearchGroupLoadingMore
                      ? state.groups
                      : <GroupModel>[];
                  final isLoadingMore = state is SearchGroupLoadingMore;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isSearch)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.0 * scaleWidth,
                          ),
                          child: Text(
                            'Recently searched',
                            style: AppTextStyles.h5bold(context).copyWith(
                              color: AppColors.black,
                              fontSize: 18 * scaleHeight,
                            ),
                          ),
                        ),
                      if (!isSearch) SizedBox(height: 12 * scaleHeight),

                      if (groups.isNotEmpty)
                        Expanded(
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.0 * scaleWidth,
                            ),
                            itemCount: groups.length + (isLoadingMore ? 1 : 0),
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 16 * scaleHeight),
                            itemBuilder: (context, index) {
                              if (index < groups.length) {
                                final group = groups[index];
                                return InkWell(
                                  onTap: () async {
                                    context.read<SearchGroupBloc>().add(
                                      AddGroupToRecentSearch(
                                        groupId: group.groupId,
                                      ),
                                    );

                                    final crypto = CryptoService();
                                    await crypto.loadKeys();
                                    final encryptedGroupKey =
                                        group.groupKey ?? '';
                                    log(
                                      'encryptedGroupKey123: $encryptedGroupKey',
                                    );
                                    log(
                                      'encryptedversion: ${group.version}',
                                    );
                                    final decryptGroupKey = await crypto
                                        .decryptGroupSenderKey(
                                          encryptedGroupKey,
                                        );
                                    log(
                                      'decryptGroupKey: ${decryptGroupKey.length}',
                                    );
                                    if (decryptGroupKey.length != 16 &&
                                        decryptGroupKey.length != 24 &&
                                        decryptGroupKey.length != 32) {
                                      throw Exception(
                                        'Invalid AES key length: ${decryptGroupKey.length}',
                                      );
                                    }
                                    final isGroup = group.isGroup;
                                    final type = isGroup
                                        ? 'group'
                                        : 'conversation';
                                    // Join Conversations Room
                                    final joinRoomHelper = ChatListHelper();
                                    await joinRoomHelper.joinConversation(
                                      conversationId: group.groupId,
                                      isGroup: isGroup,
                                    );
                                    if (context.mounted) {
                                      await context.push(
                                        AppRoutes.chatDetail,
                                        extra: ChatDetailArgs(
                                          id: group.groupId,
                                          type: type,
                                          title: group.name,
                                          isGroup: isGroup,
                                          avatar: group.avatar,
                                          unReadMessage: group.unreadCount,
                                          decryptGroupKey: decryptGroupKey,
                                          encryptedGroupKey: encryptedGroupKey,
                                          version: group.version,
                                        ),
                                      );
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: const AssetImage(
                                          AppAssets.appLogo,
                                        ),
                                        radius: 20 * scaleWidth,
                                        backgroundColor: Colors.transparent,
                                      ),
                                      SizedBox(width: 12 * scaleWidth),
                                      Text(
                                        group.name,
                                        style: AppTextStyles.p2SemiBold(
                                          context,
                                        ).copyWith(color: Colors.black),
                                      ),
                                      SizedBox(width: 12 * scaleWidth),
                                    ],
                                  ),
                                );
                              } else {
                                // Show shimmer for load more
                                return const SearchGroupShimmer(itemCount: 2);
                              }
                            },
                          ),
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: scaleWidth * 64,
                                color: AppColors.neural300,
                              ),
                              SizedBox(height: scaleHeight * 16),
                              Text(
                                'No group exists',
                                style: AppTextStyles.p2SemiBold(
                                  context,
                                ).copyWith(color: AppColors.neural500),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                } else if (state is SearchGroupError) {
                  return Center(child: Text(state.message));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
