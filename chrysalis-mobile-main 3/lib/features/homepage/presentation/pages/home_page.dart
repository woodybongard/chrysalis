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
        appBar: widget.isShowAppBar! ? AppBar(
          toolbarHeight: 54,
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(left: 17),
            child: Row(
              children: [
                Image.asset(
                  AppAssets.appLogo,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'CHRYSALIS',
                  style: AppTextStyles.displayBold20(
                    context,
                  ).copyWith(color: Colors.black),
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 17),
              child: const ProfileAvatarButton(size: 32),
            ),
          ],
        ) : null,
        floatingActionButton: widget.isShowAppBar!
            ? GestureDetector(
                onTap: () {
                  context.push(AppRoutes.searchContactsPath);
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF000000),
                        Color(0xFF444462),
                      ],
                      stops: [0.0, 0.62],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      AppAssets.searchIcon,
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primaryMain,
          backgroundColor: AppColors.white,
          strokeWidth: 2.5,
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
                                  color: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 17,
                                  ),
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    itemCount:
                                        groups.length + (isLoadingMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index < groups.length) {
                                        final group = groups[index];
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            bottom: index < groups.length - 1 ? 16 : 0,
                                          ),
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => _onChatTileTap(group),
                                            child: SizedBox(
                                              height: 44,
                                              child: Row(
                                                children: [
                                                  // Avatar - 44x44
                                                  Builder(
                                                    builder: (context) {
                                                      final hasAvatar = group.avatar != null && group.avatar!.isNotEmpty;
                                                      return Container(
                                                        width: 44,
                                                        height: 44,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: AppColors.neural50,
                                                          image: hasAvatar
                                                              ? DecorationImage(
                                                                  image: NetworkImage(group.avatar!),
                                                                  fit: BoxFit.cover,
                                                                )
                                                              : null,
                                                        ),
                                                        child: !hasAvatar
                                                            ? Center(
                                                                child: SvgPicture.asset(
                                                                  group.isGroup
                                                                      ? AppAssets.groupIcon
                                                                      : AppAssets.profileIcon,
                                                                  width: 20,
                                                                  height: 20,
                                                                  colorFilter: const ColorFilter.mode(
                                                                    AppColors.neural400,
                                                                    BlendMode.srcIn,
                                                                  ),
                                                                ),
                                                              )
                                                            : null,
                                                      );
                                                    },
                                                  ),
                                                  // Gap 12px
                                                  const SizedBox(width: 12),
                                                  // Content
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        // Title row: Name + Time
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                group.name,
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: AppTextStyles.p2SemiBold(context).copyWith(
                                                                  color: Colors.black,
                                                                  fontSize: kIsWeb ? 16.sp : 14,
                                                                  height: 1.3,
                                                                ),
                                                              ),
                                                            ),
                                                            if (group.lastMessage != null)
                                                              BlocBuilder<TimeTickerCubit, DateTime>(
                                                                builder: (context, now) {
                                                                  return Text(
                                                                    _formatRelativeTime(
                                                                      group.lastMessage!.createdAt,
                                                                      now,
                                                                    ),
                                                                    style: AppTextStyles.caption2RegularCenter(context).copyWith(
                                                                      color: AppColors.neural300,
                                                                      fontSize: kIsWeb ? 14.sp : 12,
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                          ],
                                                        ),
                                                        // Gap 4px
                                                        const SizedBox(height: 2),
                                                        // Subtitle row
                                                        _buildSubtitleRow(group, context),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
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
                        : CenterMessageWithButton(
                            message: 'No conversations yet',
                            onPressed: _onRefresh,
                            scaleHeight: context.scaleHeight,
                          );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleRow(GroupEntity group, BuildContext context) {
    // Typing indicator
    if (group.typingText != null && group.typingText!.isNotEmpty) {
      return Text(
        group.typingText!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.p3Regular(context).copyWith(
          color: AppColors.primaryMain,
          fontStyle: FontStyle.italic,
          fontSize: kIsWeb ? 14.sp : 14,
          height: 1.3,
        ),
      );
    }

    // Last message
    if (group.lastMessage != null) {
      final isSenderYou = group.lastMessage!.isSenderYou;

      return Row(
        children: [
          // When message is by you: "You:" + status icon + file icon + message
          if (isSenderYou) ...[
            Text(
              'You:',
              style: AppTextStyles.p3Regular(context).copyWith(
                color: const Color(0xFF666666),
                fontSize: kIsWeb ? 14.sp : 14,
                height: 1.3,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 4),
            // Status icon 18x18
            SizedBox(
              width: 18,
              height: 18,
              child: _buildStatusIcon(group.lastMessage!, 1.0),
            ),
            const SizedBox(width: 2),
            // File icon 12x12 if it's a file
            if (group.lastMessage!.type == 'FILE') ...[
              SvgPicture.asset(
                AppAssets.fileIcon,
                width: 12,
                height: 12,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF666666),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 2),
            ],
          ],
          // When message is by someone else: status icon + message
          if (!isSenderYou) ...[
            // Status icon 18x18
            SizedBox(
              width: 18,
              height: 18,
              child: _buildStatusIcon(group.lastMessage!, 1.0),
            ),
            const SizedBox(width: 4),
          ],
          // Message text
          Expanded(
            child: Text(
              _getMessageContent(group),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.p3Regular(context).copyWith(
                color: const Color(0xFF666666),
                fontSize: kIsWeb ? 14.sp : 14,
                height: 1.3,
                letterSpacing: -0.3,
              ),
            ),
          ),
          // Unread badge
          if (group.unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.primaryMain,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Center(
                child: Text(
                  group.unreadCount > 99 ? '99+' : '${group.unreadCount}',
                  style: AppTextStyles.caption2RegularCenter(context).copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  String _getMessageContent(GroupEntity group) {
    if (group.lastMessage == null) return '';
    final msg = group.lastMessage!;
    
    // For FILE messages, return content directly without decryption
    if (msg.type == 'FILE') {
      return msg.content;
    }
    
    // For TEXT messages, decrypt if keys are available
    if (msg.content.isNotEmpty && msg.decryptedGroupKey != null && msg.iv != null) {
      return CryptoService.decryptGroupMessage(
        msg.decryptedGroupKey!,
        msg.content,
        msg.iv!,
      );
    }
    return msg.content;
  }

  Future<void> _onChatTileTap(GroupEntity group) async {
    log('=== HomePage onTap START ===');
    log('Platform: kIsWeb = $kIsWeb');
    log('isShowAppBar = ${widget.isShowAppBar}');
    log('Group: ${group.name} (ID: ${group.groupId})');

    final encryptedGroupKey = group.groupKey ?? '';
    final isGroup = group.isGroup;
    final type = isGroup ? 'group' : 'conversation';

    log('Chat type: $type, isGroup: $isGroup');

    // Check if web platform
    if (kIsWeb && !widget.isShowAppBar!) {
      log('WEB PLATFORM DETECTED - Dispatching to WebChatBloc');
      // Web: Dispatch to WebChatBloc - needs crypto work done here for now
      if (!context.mounted) {
        log('Context not mounted before WebChatBloc dispatch');
        return;
      }

      try {
        final crypto = CryptoService();
        await crypto.loadKeys();
        if (!mounted) return;

        final decryptGroupKey = await crypto.decryptGroupSenderKey(encryptedGroupKey);
        if (!mounted) return;

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
          memberCount: group.memberCount,
        );
        log('Creating SelectChatEvent with args: ${group.groupId}');

        context.read<WebChatBloc>().add(SelectChatEvent(chatArgs));
        log('SelectChatEvent dispatched successfully');
      } catch (e, stack) {
        log('ERROR dispatching to WebChatBloc: $e');
        log('Stack: $stack');
      }
    } else {
      log('MOBILE PLATFORM - Navigating to chat detail immediately');
      // Mobile: Navigate immediately - crypto/socket work happens in ChatDetailBloc
      context.push(
        AppRoutes.chatDetailPath,
        extra: ChatDetailArgs(
          id: group.groupId,
          type: type,
          title: group.name,
          isGroup: group.isGroup,
          avatar: group.avatar,
          unReadMessage: group.unreadCount,
          encryptedGroupKey: encryptedGroupKey,
          version: group.version,
          memberCount: group.memberCount,
        ),
      );
      log('Navigation triggered');
    }
    log('=== HomePage onTap END ===');
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
      height: kIsWeb?16.sp: scaleHeight * 16,
      width: kIsWeb?16.sp:  scaleHeight * 16,
    );
  }
}
