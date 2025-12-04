import 'dart:async';
import 'dart:developer';

import 'package:chrysalis_mobile/core/constants/app_assets.dart';
import 'package:chrysalis_mobile/core/crypto_services/crypto_service.dart';
import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/core/socket/chat_list_helper.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/chat_detail_args.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/entity/search_result_entity.dart';
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
  Timer? _debounceTimer;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<SearchGroupBloc>().add(LoadRecentSearches());
    _scrollController.addListener(_onScroll);
    _controller.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _onSearch(_controller.text);
    });
  }

  void _onScroll() {
    final bloc = context.read<SearchGroupBloc>();
    final state = bloc.state;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (state is SearchGroupLoaded && state.hasMore) {
        if (state.query != null && state.query!.isNotEmpty) {
          bloc.add(LoadMoreResults(query: state.query!, page: state.page + 1));
        }
      }
    }
  }

  void _onSearch(String value) {
    final bloc = context.read<SearchGroupBloc>();
    _lastQuery = value.trim();
    if (_lastQuery.isEmpty) {
      bloc.add(LoadRecentSearches());
    } else {
      bloc.add(PerformSearch(query: _lastQuery));
    }
  }

  Future<void> _onResultTap(SearchResultEntity result) async {
    // Add to recent search
    context.read<SearchGroupBloc>().add(AddToRecentSearch(result: result));

    // Handle based on result type
    if (result.isUserType) {
      // For user type, we need to handle starting a new conversation.
      // For now, just log and return - implement user profile/new chat later.
      log('User tapped: ${result.name}, publicKey: ${result.publicKey}');
      return;
    }

    // For group and conversation types, navigate to chat
    final crypto = CryptoService();
    await crypto.loadKeys();
    final encryptedKey = result.encryptionKey ?? '';
    log('encryptedKey: $encryptedKey');
    log('version: ${result.version}');

    final decryptGroupKey = await crypto.decryptGroupSenderKey(encryptedKey);
    log('decryptGroupKey length: ${decryptGroupKey.length}');

    if (decryptGroupKey.length != 16 &&
        decryptGroupKey.length != 24 &&
        decryptGroupKey.length != 32) {
      throw Exception('Invalid AES key length: ${decryptGroupKey.length}');
    }

    final isGroup = result.isGroup ?? false;
    final type = result.type;

    // Join Conversations Room
    final joinRoomHelper = ChatListHelper();
    await joinRoomHelper.joinConversation(
      conversationId: result.id,
      isGroup: isGroup,
    );

    if (mounted) {
      await context.push(
        AppRoutes.chatDetailPath,
        extra: ChatDetailArgs(
          id: result.id,
          type: type,
          title: result.name,
          isGroup: isGroup,
          avatar: result.avatar,
          unReadMessage: result.unreadCount ?? 0,
          decryptGroupKey: decryptGroupKey,
          encryptedGroupKey: encryptedKey,
          version: result.version ?? 0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56 * scaleHeight,
        leadingWidth: 56 * scaleWidth,
        leading: Padding(
          padding: EdgeInsets.only(left: 12 * scaleWidth),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.pop(),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0 * scaleWidth),
              child: Container(
                height: 40 * scaleHeight,
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
                      padding: EdgeInsets.all(10.0 * scaleWidth),
                      child: SvgPicture.asset(
                        AppAssets.searchIcon,
                        colorFilter: const ColorFilter.mode(
                          AppColors.neural501,
                          BlendMode.srcIn,
                        ),
                        height: 20 * scaleHeight,
                        width: 20 * scaleWidth,
                      ),
                    ),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: 40 * scaleWidth,
                      minHeight: 40 * scaleHeight,
                    ),
                    hintText: 'Search',
                    hintStyle: AppTextStyles.p1regular(context).copyWith(
                      color: AppColors.neural301,
                      fontSize: 16 * scaleHeight,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.0 * scaleWidth,
                      vertical: 10,
                    ),
                  ),
                  style: AppTextStyles.p1regular(context).copyWith(
                    color: AppColors.black,
                    fontSize: 16 * scaleHeight,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _onSearch,
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
                    final results = state is SearchGroupLoaded
                        ? state.results
                        : state is SearchGroupLoadingMore
                            ? state.results
                            : <SearchResultEntity>[];
                    final isLoadingMore = state is SearchGroupLoadingMore;

                    if (results.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80 * scaleWidth,
                              height: 80 * scaleWidth,
                              decoration: const BoxDecoration(
                                color: AppColors.neural100,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  AppAssets.searchIcon,
                                  width: 32 * scaleWidth,
                                  height: 32 * scaleWidth,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.neural300,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16 * scaleHeight),
                            Text(
                              isSearch
                                  ? 'No results found'
                                  : 'No recent searches',
                              style: AppTextStyles.p2SemiBold(
                                context,
                              ).copyWith(
                                color: AppColors.black,
                                fontSize: 16 * scaleHeight,
                              ),
                            ),
                            SizedBox(height: 8 * scaleHeight),
                            Text(
                              isSearch
                                  ? 'Try searching with different keywords'
                                  : 'Your recent searches will appear here',
                              style: AppTextStyles.p1regular(
                                context,
                              ).copyWith(
                                color: AppColors.neural500,
                                fontSize: 14 * scaleHeight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 120 * scaleHeight),

                          ],
                        ),
                      );
                    }

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
                        Expanded(
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.0 * scaleWidth,
                            ),
                            itemCount:
                                results.length + (isLoadingMore ? 1 : 0),
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 16 * scaleHeight),
                            itemBuilder: (context, index) {
                              if (index < results.length) {
                                final result = results[index];
                                return _buildResultItem(
                                  result,
                                  scaleWidth,
                                  scaleHeight,
                                );
                              } else {
                                return const SearchGroupShimmer(itemCount: 2);
                              }
                            },
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
      ),
    );
  }

  Widget _buildResultItem(
    SearchResultEntity result,
    double scaleWidth,
    double scaleHeight,
  ) {
    return InkWell(
      onTap: () => _onResultTap(result),
      child: Row(
        children: [
          _buildAvatar(result, scaleWidth),
          SizedBox(width: 12 * scaleWidth),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.name,
                  style: AppTextStyles.body2Semibold(context).copyWith(
                    color: AppColors.black,
                    fontSize: 14 * scaleHeight,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (result.isUserType && result.username != null)
                  Text(
                    '@${result.username}',
                    style: AppTextStyles.captionRegular(context).copyWith(
                      color: AppColors.neural500,
                      fontSize: 12 * scaleHeight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (result.isUserType)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8 * scaleWidth,
                vertical: 4 * scaleHeight,
              ),
              decoration: BoxDecoration(
                color: AppColors.neural100,
                borderRadius: BorderRadius.circular(12 * scaleWidth),
              ),
              child: Text(
                'User',
                style: AppTextStyles.captionRegular(context).copyWith(
                  color: AppColors.neural500,
                  fontSize: 10 * scaleHeight,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(SearchResultEntity result, double scaleWidth) {
    final hasAvatar = result.avatar != null && result.avatar!.isNotEmpty;

    return Container(
      width: 44 * scaleWidth,
      height: 44 * scaleWidth,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.neural50,
        image: hasAvatar
            ? DecorationImage(
                image: NetworkImage(result.avatar!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: !hasAvatar
          ? Center(
              child: SvgPicture.asset(
                _getIconForType(result),
                width: 20 * scaleWidth,
                height: 20 * scaleWidth,
                colorFilter: const ColorFilter.mode(
                  AppColors.neural400,
                  BlendMode.srcIn,
                ),
              ),
            )
          : null,
    );
  }

  String _getIconForType(SearchResultEntity result) {
    if (result.isUserType) {
      return AppAssets.profileIcon;
    } else if (result.isGroup ?? false) {
      return AppAssets.groupIcon;
    } else {
      return AppAssets.profileIcon;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller
      ..removeListener(_onSearchChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
