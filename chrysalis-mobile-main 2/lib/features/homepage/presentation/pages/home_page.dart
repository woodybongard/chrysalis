import 'dart:async';
import 'dart:developer';

import 'package:chrysalis_mobile/core/bloc/time_ticker_cubit.dart';
import 'package:chrysalis_mobile/core/constants/app_assets.dart';
import 'package:chrysalis_mobile/core/crypto_services/crypto_service.dart';
import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/core/socket/chat_list_helper.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/core/widgets/center_message_with_button.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/chat_detail_args.dart';
import 'package:chrysalis_mobile/features/homepage/domain/entity/home_entity.dart';
import 'package:chrysalis_mobile/features/homepage/presentation/bloc/home_bloc.dart';
import 'package:chrysalis_mobile/features/homepage/presentation/bloc/home_event.dart';
import 'package:chrysalis_mobile/features/homepage/presentation/widgets/homepage_loading_more_shimmer.dart';
import 'package:chrysalis_mobile/features/homepage/presentation/widgets/homepage_shimmer.dart';
import 'package:chrysalis_mobile/features/profile/presentation/widgets/profile_avatar_button.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/bloc/web_chat_bloc.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/bloc/web_chat_event.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    this.isShowAppBar=true,
    super.key});

  final bool? isShowAppBar;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late ScrollController _scrollController;
  int _currentPage = 1;
  final int _limit = 15;
  bool _isLoadingMore = false;
  final ChatListHelper _joinRoomHelper = ChatListHelper();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeBloc>().add(const LoadHomeDataEvent());
    });
    _joinRoomHelper
      ..listenForNewMessages((groupEntity) {
        if (!mounted) return;
        context.read<HomeBloc>().add(NewMessageReceivedEvent(groupEntity));
      })
      ..listenForUserTypingList(({
        required String userId,
        required String conversationId,
        required String name,
      }) {
        if (!mounted) return;
        context.read<HomeBloc>().add(
          UserTypingListEvent(conversationId: conversationId, name: name),
        );
      })
      ..listenForUserStopTypingList(({
        required String userId,
        required String conversationId,
        required String name,
      }) {
        if (!mounted) return;
        context.read<HomeBloc>().add(
          UserStopTypingListEvent(conversationId: conversationId),
        );
      })
      // Listen for chatlist_update event
      ..listenForChatListUpdate(({
        required String chatId,
        required String lastMessageId,
        required String lastMessageStatus,
      }) {
        if (!mounted) return;
        context.read<HomeBloc>().add(
          UpdateChatLastMessageStatusEvent(
            chatId: chatId,
            lastMessageId: lastMessageId,
            lastMessageStatus: lastMessageStatus,
          ),
        );
      });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore) {
      final state = context.read<HomeBloc>().state;
      if (state is HomeLoaded) {
        final pagination = state.data.pagination;
        if (pagination.page < pagination.totalPages) {
          _isLoadingMore = true;
          _currentPage = pagination.page + 1;
          context.read<HomeBloc>().add(
            LoadHomeDataEvent(page: _currentPage, limit: _limit),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;
    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is HomeLoaded) {
          _isLoadingMore = false;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar:widget.isShowAppBar! ? AppBar(
          toolbarHeight: 60 * scaleHeight,
          backgroundColor: Colors.white,
          elevation: 0,
          leadingWidth: scaleWidth * 41,
          leading: Padding(
            padding: EdgeInsets.only(left: scaleWidth * 17.0),
            child: Image.asset(AppAssets.appLogo, height: scaleHeight * 24),
          ),
          title: Text(
            'CHRYSALIS',
            style: AppTextStyles.displayBold20(
              context,
            ).copyWith(color: Colors.black),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: scaleWidth * 20.0),
              child: const ProfileAvatarButton(size: 32),
            ),
          ],
        ):null,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: Stack(
            children: [
              BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is HomeLoading && _currentPage == 1) {
                    return const HomePageShimmer();
                  } else if (state is HomeError) {
                    return CenterMessageWithButton(
                      message: state.message,
                      onPressed: _onRefresh,
                      scaleHeight:
                          context.scaleHeight, // pass your scaling util
                    );
                  } else {
                    // If loading more, keep showing the previous data
                    final groups = state is HomeLoaded
                        ? state.data.data
                        : state is HomeLoadingMore
                        ? state.data.data
                        : <GroupEntity>[];

                    final isLoadingMore = state is HomeLoadingMore;
                    return groups.isNotEmpty
                        ? Column(
                            children: [
                              Expanded(
                                child: Container(
                                  color: Colors
                                      .white, // Ensures background is always white
                                  padding: EdgeInsets.only(
                                    left: scaleWidth * 17.0,
                                    right: scaleWidth * 17.0,
                                  ),
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount:
                                        groups.length + (isLoadingMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index < groups.length) {
                                        final group = groups[index];
                                        return Padding(
                                          padding: EdgeInsets.all(
                                            scaleWidth * 4.0,
                                          ),
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  AppColors.neural50,
                                              backgroundImage:
                                                  group.avatar != null
                                                  ? NetworkImage(group.avatar!)
                                                  : null,
                                              radius: 24,
                                              child: group.avatar == null
                                                  ? const Icon(
                                                      Icons.group,
                                                      color:
                                                          AppColors.neural502,
                                                    )
                                                  : null,
                                            ),
                                            title: Text(
                                              group.name,
                                              style: AppTextStyles.p2SemiBold(
                                                context,
                                              ).copyWith(color: Colors.black,
                                              fontSize: kIsWeb?16.sp:null,
                                              height: kIsWeb?1.4:null,
                                              fontWeight: kIsWeb ?FontWeight.w500 :null,
                                              ),
                                            ),
                                            subtitle:
                                                group.typingText != null &&
                                                    group.typingText!.isNotEmpty
                                                ? Padding(
                                                    padding: EdgeInsets.only(
                                                      top: scaleHeight * 4.0,
                                                    ),
                                                    child: SizedBox(
                                                      height: scaleHeight * 18,
                                                      child: Row(
                                                        children: [
                                                          SizedBox(
                                                            width:
                                                                scaleWidth * 4,
                                                          ),
                                                          Text(
                                                            group.typingText !=
                                                                        null &&
                                                                    group
                                                                        .typingText!
                                                                        .isNotEmpty
                                                                ? group
                                                                      .typingText!
                                                                : '',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: AppTextStyles.p3Regular(context).copyWith(
                                                              color:
                                                                  group.typingText !=
                                                                          null &&
                                                                      group
                                                                          .typingText!
                                                                          .isNotEmpty
                                                                  ? AppColors
                                                                        .primaryMain
                                                                  : (group.unreadCount >
                                                                            0
                                                                        ? Colors
                                                                              .black
                                                                        : AppColors
                                                                              .neural500),
                                                              fontStyle:
                                                                  group.typingText !=
                                                                          null &&
                                                                      group
                                                                          .typingText!
                                                                          .isNotEmpty
                                                                  ? FontStyle
                                                                        .italic
                                                                  : FontStyle
                                                                        .normal,
                                                              fontSize: kIsWeb?14.sp:null,
                                                              height: kIsWeb?1.3:null,
                                                              fontWeight: kIsWeb ?FontWeight.w400 :null,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : group.lastMessage != null
                                                ? Padding(
                                                    padding: EdgeInsets.only(
                                                      top: scaleHeight * 4.0,
                                                    ),
                                                    child: SizedBox(
                                                      height: scaleHeight * 18,
                                                      child: Row(
                                                        children: [
                                                          if (group
                                                              .lastMessage!
                                                              .isSenderYou) ...[
                                                            Text(
                                                              'You: ',
                                                              style:
                                                                  AppTextStyles.p3Regular(
                                                                    context,
                                                                  ).copyWith(
                                                                    color:
                                                                        group.unreadCount >
                                                                            0
                                                                        ? Colors
                                                                              .black
                                                                        : AppColors
                                                                              .neural500,
                                                                    fontSize: kIsWeb?14.sp:null,
                                                                    fontWeight: kIsWeb ?FontWeight.w400 :null,
                                                                  ),
                                                            ),
                                                            _buildStatusIcon(
                                                              group
                                                                  .lastMessage!,
                                                              scaleHeight,
                                                            ),
                                                          ],
                                                          SizedBox(
                                                            width:
                                                                scaleWidth * 2,
                                                          ),
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                if (group
                                                                        .lastMessage!
                                                                        .type ==
                                                                    'FILE')
                                                                  SvgPicture.asset(
                                                                    AppAssets
                                                                        .fileIcon,
                                                                    width:
                                                                        scaleWidth *
                                                                        12,
                                                                    height:
                                                                        scaleHeight *
                                                                        12,
                                                                  )
                                                                else
                                                                  const SizedBox(),
                                                                if (group
                                                                        .lastMessage!
                                                                        .type ==
                                                                    'FILE')
                                                                  SizedBox(
                                                                    width:
                                                                        scaleWidth *
                                                                        2,
                                                                  )
                                                                else
                                                                  const SizedBox(),
                                                                Expanded(
                                                                  child: Text(
                                                                    group.lastMessage!.content.isNotEmpty &&
                                                                            group.lastMessage!.decryptedGroupKey !=
                                                                                null
                                                                        ? CryptoService.decryptGroupMessage(
                                                                            group.lastMessage!.decryptedGroupKey!,
                                                                            group.lastMessage!.content,
                                                                            group.lastMessage!.iv,
                                                                          )
                                                                        : '',
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style: AppTextStyles.p3Regular(context).copyWith(
                                                                      color:
                                                                          (group.unreadCount >
                                                                              0
                                                                          ? Colors.black
                                                                          : AppColors.neural500),
                                                                      fontStyle:
                                                                          FontStyle
                                                                              .normal,
                                                                      fontSize: kIsWeb?14.sp:null,
                                                                      fontWeight: kIsWeb ?FontWeight.w400 :null,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : null,
                                            trailing: group.lastMessage != null
                                                ? BlocBuilder<
                                                    TimeTickerCubit,
                                                    DateTime
                                                  >(
                                                    builder: (context, now) {
                                                      final timeText =
                                                          _formatRelativeTime(
                                                            group
                                                                .lastMessage!
                                                                .createdAt,
                                                            now,
                                                          );
                                                      final unread =
                                                          group.unreadCount;
                                                      final displayCount =
                                                          unread > 99
                                                          ? '99+'
                                                          : '$unread';
                                                      return Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Text(
                                                            timeText,
                                                            style:
                                                                AppTextStyles.caption2RegularCenter(
                                                                  context,
                                                                ).copyWith(
                                                                  color: AppColors
                                                                      .neural300,
                                                                  fontSize: kIsWeb?14.sp:null,
                                                                  height: kIsWeb?1.4:null,
                                                                  fontWeight: kIsWeb ?FontWeight.w400 :null,
                                                                ),
                                                          ),
                                                          if (unread > 0) ...[
                                                            const SizedBox(
                                                              height: 6,
                                                            ),
                                                            CircleAvatar(
                                                              radius: 10,
                                                              backgroundColor:
                                                                  AppColors
                                                                      .primaryMain,
                                                              child: Text(
                                                                displayCount,
                                                                style:
                                                                    AppTextStyles.caption2RegularCenter(
                                                                      context,
                                                                    ).copyWith(
                                                                      color: AppColors
                                                                          .white,
                                                                      fontSize:
                                                                          10,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      );
                                                    },
                                                  )
                                                : null,
                                            onTap: () async {
                                              log('=== HomePage onTap START ===');
                                              log('Platform: kIsWeb = $kIsWeb');
                                              log('isShowAppBar = ${widget.isShowAppBar}');
                                              log('Group: ${group.name} (ID: ${group.groupId})');
                                              
                                              final crypto = CryptoService();
                                              await crypto.loadKeys();
                                              if (!mounted) {
                                                log('Widget not mounted after crypto.loadKeys');
                                                return;
                                              }

                                              final encryptedGroupKey =
                                                  group.groupKey ?? '';
                                              log(
                                                'encryptedGroupKey123: $encryptedGroupKey',
                                              );
                                              log(
                                                'encryptedversion: ${group.version}',
                                              );
                                              final decryptGroupKey =
                                                  await crypto
                                                      .decryptGroupSenderKey(
                                                        encryptedGroupKey,
                                                      );
                                              if (!mounted) {
                                                log('Widget not mounted after decryptGroupSenderKey');
                                                return;
                                              }
                                              log(
                                                'decryptGroupKey: ${decryptGroupKey.length}',
                                              );
                                              if (decryptGroupKey.length !=
                                                      16 &&
                                                  decryptGroupKey.length !=
                                                      24 &&
                                                  decryptGroupKey.length !=
                                                      32) {
                                                log('ERROR: Invalid AES key length: ${decryptGroupKey.length}');
                                                throw Exception(
                                                  'Invalid AES key length: ${decryptGroupKey.length}',
                                                );
                                              }
                                              final isGroup = group.isGroup;
                                              final type = isGroup
                                                  ? 'group'
                                                  : 'conversation';
                                              
                                              log('Chat type: $type, isGroup: $isGroup');
                                              
                                              // Check if web platform
                                              if (kIsWeb && !widget.isShowAppBar!) {
                                                log('WEB PLATFORM DETECTED - Dispatching to WebChatBloc');
                                                // Web: Dispatch to WebChatBloc
                                                if (!context.mounted) {
                                                  log('Context not mounted before WebChatBloc dispatch');
                                                  return;
                                                }
                                                
                                                try {
                                                  final chatArgs = ChatDetailArgs(
                                                    id: group.groupId,
                                                    type: type,
                                                    title: group.name,
                                                    isGroup: group.isGroup,
                                                    avatar: group.avatar,
                                                    unReadMessage: group.unreadCount,
                                                    decryptGroupKey: decryptGroupKey,
                                                    encryptedGroupKey: encryptedGroupKey,
                                                    version: group.version,
                                                  );
                                                  log('Creating SelectChatEvent with args: ${group.groupId}');
                                                  
                                                  context.read<WebChatBloc>().add(
                                                    SelectChatEvent(chatArgs),
                                                  );
                                                  log('SelectChatEvent dispatched successfully');
                                                } catch (e, stack) {
                                                  log('ERROR dispatching to WebChatBloc: $e');
                                                  log('Stack: $stack');
                                                }
                                              } else {
                                                log('MOBILE PLATFORM - Navigating to chat detail');
                                                // Mobile: Navigate to chat detail
                                                // Join Conversations Room
                                                final joinRoomHelper =
                                                    ChatListHelper();
                                                await joinRoomHelper
                                                    .joinConversation(
                                                      conversationId:
                                                          group.groupId,
                                                      isGroup: isGroup,
                                                    );
                                                if (!context.mounted) {
                                                  log('Context not mounted after joinConversation');
                                                  return;
                                                }
                                                await _navigateToChatDetail(
                                                  group,
                                                  type,
                                                  decryptGroupKey,
                                                  encryptedGroupKey,
                                                );
                                                log('Navigation to chat detail completed');
                                              }
                                              log('=== HomePage onTap END ===');
                                            },
                                          ),
                                        );
                                      } else {
                                        return const HomePageLoadingMoreShimmer();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: scaleWidth * 64,
                                  color: AppColors.neural300,
                                ),
                                SizedBox(height: scaleHeight * 16),
                                Text(
                                  'No chats exists',
                                  style: AppTextStyles.p2SemiBold(
                                    context,
                                  ).copyWith(color: AppColors.neural500),
                                ),
                                SizedBox(height: scaleHeight * 16),
                                ElevatedButton.icon(
                                  onPressed: _onRefresh,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reload'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryMain,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                  }
                },
              ),
              if(widget.isShowAppBar!)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: scaleHeight * 45),
                  child: FloatingActionButton(
                    onPressed: () {
                      context.push(AppRoutes.searchContacts);
                    },
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    child: Container(
                      width: scaleWidth * 60,
                      height: scaleHeight * 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.fabGradientEnd),
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.fabGradientStart,
                            AppColors.fabGradientEnd,
                          ],
                          stops: [0.0, 0.62],
                        ),
                      ),
                      padding: EdgeInsets.all(scaleWidth * 16),
                      child: SvgPicture.asset(
                        AppAssets.searchIcon,
                        colorFilter: const ColorFilter.mode(
                          AppColors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    final completer = Completer<void>();
    late final StreamSubscription<HomeState> sub;
    sub = context.read<HomeBloc>().stream.listen((state) {
      if (state is HomeLoaded || state is HomeError) {
        completer.complete();
        sub.cancel();
      }
    });
    context.read<HomeBloc>().add(const LoadHomeDataEvent());
    _currentPage = 1;
    _isLoadingMore = false;
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        sub.cancel();
        return;
      },
    );
  }

  String _formatRelativeTime(String isoString, DateTime now) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final duration = now.difference(dateTime);

      if (duration.inSeconds < 60) return 'now';
      if (duration.inMinutes < 60) return '${duration.inMinutes}min';
      if (duration.inHours < 24) return '${duration.inHours}h';
      if (duration.inDays < 7) return '${duration.inDays}d';

      final weeks = (duration.inDays / 7).floor();
      if (weeks < 5) return '${weeks}w';

      final months = (duration.inDays / 30).floor();
      if (months < 12) return '${months}m';

      final years = (duration.inDays / 365).floor();
      return '${years}Y';
    } catch (_) {
      return isoString;
    }
  }

  Future<void> _navigateToChatDetail(
    GroupEntity group,
    String type,
    encrypt.Key decryptGroupKey,
    String encryptedGroupKey,
  ) async {
    await context.push(
      AppRoutes.chatDetail,
      extra: ChatDetailArgs(
        id: group.groupId,
        type: type,
        title: group.name,
        isGroup: group.isGroup,
        avatar: group.avatar,
        unReadMessage: group.unreadCount,
        decryptGroupKey: decryptGroupKey,
        encryptedGroupKey: encryptedGroupKey,
        version: group.version,
      ),
    );
  }

  Widget _buildStatusIcon(LastMessageEntity message, double scaleHeight) {
    final status = message.status.toUpperCase();
    String asset;
    if (status == 'READ') {
      asset = AppAssets.readChatIcon;
    } else if (status == 'DELIVERED') {
      asset = AppAssets.deliveredChatIcon;
    } else if (status == 'SENT') {
      asset = AppAssets.sentChatIcon;
    } else if (status == 'FAILED') {
      asset = AppAssets.infoIcon;
    } else {
      asset = AppAssets.sentChatIcon;
    }
    return SvgPicture.asset(
      asset,
      height: kIsWeb?18.sp: scaleHeight * 16,
      width: kIsWeb?18.sp:  scaleHeight * 16,
    );
  }
}
