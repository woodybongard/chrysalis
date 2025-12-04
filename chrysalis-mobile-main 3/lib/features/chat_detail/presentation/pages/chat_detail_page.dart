import 'dart:async';
import 'dart:io';

import 'package:chrysalis_mobile/core/constants/app_assets.dart';
import 'package:chrysalis_mobile/core/constants/app_keys.dart';
import 'package:chrysalis_mobile/core/constants/file_constants.dart';
import 'package:chrysalis_mobile/core/crypto_services/crypto_service.dart';
import 'package:chrysalis_mobile/core/local_storage/chat_file_database.dart';
import 'package:chrysalis_mobile/core/local_storage/local_storage.dart';
import 'package:chrysalis_mobile/core/socket/bloc/socket_connection_cubit.dart';
import 'package:chrysalis_mobile/core/socket/bloc/socket_connection_state.dart';
import 'package:chrysalis_mobile/core/socket/chat_list_helper.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart' show AppColors;
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/core/widgets/center_message_with_button.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/chat_detail_args.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/message_entity.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/bloc/chat_detail_bloc.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/widgets/chat_detail_shimmer.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/widgets/file_send_dialog.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/widgets/message_bubble_wrapper.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/widgets/message_skeleton.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/widgets/typing_indicator.dart';
import 'package:chrysalis_mobile/features/homepage/presentation/bloc/home_bloc.dart';
import 'package:chrysalis_mobile/features/homepage/presentation/bloc/home_event.dart';
import 'package:chrysalis_mobile/features/notifications/presentation/service/notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({required this.args, super.key});

  final ChatDetailArgs args;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> with WidgetsBindingObserver {
  final ValueNotifier<String?> _typingNameNotifier = ValueNotifier<String?>(
    null,
  );
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  String? _currentUserId;
  final ChatListHelper _joinRoomHelper = ChatListHelper();
  bool _hasEmittedTyping = false;
  final FocusNode _focusNode = FocusNode();
  StreamSubscription<SocketConnectionState>? _socketStatusSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    NotificationService.clearNotificationsForChat(widget.args.id);
    NotificationService.setCurrentlyViewingChat(widget.args.id);

    if (widget.args.unReadMessage! > 0) {
      context.read<HomeBloc>().add(
        MarkAllAsReadEvent(type: widget.args.type, chatId: widget.args.id),
      );
    }
    _loadUserId();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadChats();
      _setupSocketListeners();
      _listenToSocketStatus();
    });
    _textController.addListener(_handleTyping);
  }

  void _listenToSocketStatus() {
    // Listen to socket connection status changes
    _socketStatusSubscription = context.read<SocketConnectionCubit>().stream.listen((status) {
      if (status.status == SocketConnectionStatus.connected || 
          status.status == SocketConnectionStatus.reconnected) {
        // Re-setup listeners when socket reconnects
        _setupSocketListeners();
        // Re-join the conversation room
        _joinRoomHelper.joinConversation(
          conversationId: widget.args.id,
          isGroup: widget.args.isGroup,
        );
      }
    });
  }

  void _setupSocketListeners() {
    // Clear existing listeners first to avoid duplicates
    _joinRoomHelper
      ..listenForChatMessages((messageEntity) {
        if (mounted) {
          context.read<ChatDetailBloc>().add(
            PrependNewMessageEvent(messageEntity),
          );
          // Mark incoming message as read immediately since user is viewing the chat
          if (!messageEntity.isSenderYou) {
            _joinRoomHelper.markRead(
              chatId: widget.args.id,
              messageId: messageEntity.id,
              isGroup: widget.args.isGroup,
            );
          }
        }
      })
      ..listenForConversationalMessages((messageEntity) {
        if (mounted) {
          context.read<ChatDetailBloc>().add(
            PrependNewMessageEvent(messageEntity),
          );
          // Mark incoming message as read immediately since user is viewing the chat
          if (!messageEntity.isSenderYou) {
            _joinRoomHelper.markRead(
              chatId: widget.args.id,
              messageId: messageEntity.id,
              isGroup: widget.args.isGroup,
            );
          }
        }
      })
      // Listen for message status updates and update bloc
      ..listenForMessagesUpdateStatus((updateEntity) {
        if (mounted) {
          if (updateEntity.chatId == widget.args.id) {
            context.read<ChatDetailBloc>().add(
              ChatMessagesStatusUpdatedEvent(updateEntity),
            );
          }
        }
      })
      ..listenForUserTyping(({
        required String userId,
        required String conversationId,
        required String name,
      }) {
        if (mounted) {
          if (conversationId == widget.args.id && userId != _currentUserId) {
            _typingNameNotifier.value = name;
          }
        }
      })
      ..listenForUserStopTyping(({
        required String userId,
        required String conversationId,
      }) {
        if (mounted) {
          if (conversationId == widget.args.id && userId != _currentUserId) {
            _typingNameNotifier.value = null;
          }
        }
      })
      ..listenForReactionAdded((reactionData) {
        if (mounted) {
          final messageId = reactionData['messageId'] as String?;
          if (messageId != null) {
            context.read<ChatDetailBloc>().add(
              ReactionAddedEvent(messageId: messageId, reaction: reactionData),
            );
          }
        }
      })
      ..listenForReactionRemoved((reactionData) {
        if (mounted) {
          final messageId = reactionData['messageId'] as String?;
          final userId = reactionData['userId'] as String?;
          if (messageId != null && userId != null) {
            context.read<ChatDetailBloc>().add(
              ReactionRemovedEvent(messageId: messageId, userId: userId),
            );
          }
        }
      })
      ..listenForMessageAllDelivered(({
        required String messageId,
        required String status,
      }) {
        if (mounted) {
          context.read<ChatDetailBloc>().add(
            SingleMessageStatusUpdatedEvent(messageId: messageId, status: status),
          );
        }
      });

    _joinRoomHelper.joinConversation(
      conversationId: widget.args.id,
      isGroup: widget.args.isGroup,
    );
  }

  Future<void> loadChats() async {
    await ChatFileDatabase().getAllFiles();
    if (!mounted) return;

    // Use InitializeChatEvent if we don't have decrypted key yet (navigated from home)
    // Otherwise use LoadChatMessagesEvent (for refresh/reload)
    if (widget.args.decryptGroupKey == null) {
      context.read<ChatDetailBloc>().add(
        InitializeChatEvent(
          type: widget.args.type,
          id: widget.args.id,
          isGroup: widget.args.isGroup,
          encryptedGroupKey: widget.args.encryptedGroupKey ?? '',
        ),
      );
    } else {
      context.read<ChatDetailBloc>().add(
        LoadChatMessagesEvent(
          type: widget.args.type,
          id: widget.args.id,
          decryptGroupKey: widget.args.decryptGroupKey,
        ),
      );
    }
  }

  void _handleTyping() {
    if (!_hasEmittedTyping && _textController.text.isNotEmpty) {
      _hasEmittedTyping = true;
      _joinRoomHelper.emitTyping(
        conversationId: widget.args.id,
        isGroup: widget.args.isGroup,
      );
    }
    if (mounted) {
      // If user clears all text, emit stopTyping and reset flag
      if (_hasEmittedTyping && _textController.text.isEmpty) {
        _hasEmittedTyping = false;
        _joinRoomHelper.stopTyping(
          conversationId: widget.args.id,
          isGroup: widget.args.isGroup,
        );
      }
    }
  }

  Future<void> _loadUserId() async {
    final id = await LocalStorage().read(key: AppKeys.userID);
    if (!mounted) return;
    setState(() {
      _currentUserId = id;
    });
  }

  void _onScroll() {
    final state = context.read<ChatDetailBloc>().state;

    if (state is ChatDetailLoaded) {
      // user reached near the top (older messages)

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        context.read<ChatDetailBloc>().add(const LoadMoreChatMessagesEvent());
      }
    }
  }

  /// Mark all unread messages from other users as read via socket
  void _markVisibleMessagesAsRead(List<MessageEntity> messages) {
    final unreadFromOthers = messages
        .where((msg) => !msg.isSenderYou && msg.status != 'READ')
        .toList();

    if (unreadFromOthers.isEmpty) return;

    for (final msg in unreadFromOthers) {
      _joinRoomHelper.markRead(
        chatId: widget.args.id,
        messageId: msg.id,
        isGroup: widget.args.isGroup,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // When app comes back to foreground, ensure we're listening
      // Socket cubit will handle reconnection if needed
      final socketStatus = context.read<SocketConnectionCubit>().state;
      if (socketStatus.status == SocketConnectionStatus.connected) {
        // Re-setup listeners and rejoin conversation
        _setupSocketListeners();
      }
    } else if (state == AppLifecycleState.paused) {
      // When app goes to background, stop typing but keep connection
      if (_hasEmittedTyping) {
        _joinRoomHelper.stopTyping(
          conversationId: widget.args.id,
          isGroup: widget.args.isGroup,
        );
        _hasEmittedTyping = false;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socketStatusSubscription?.cancel();
    NotificationService.setCurrentlyViewingChat(null);
    ChatListHelper()
      ..stopTyping(conversationId: widget.args.id, isGroup: widget.args.isGroup)
      ..leaveConversation(
        conversationId: widget.args.id,
        isGroup: widget.args.isGroup,
      );
    _scrollController.dispose();
    _textController
      ..removeListener(_handleTyping)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: kIsWeb ? Colors.transparent : Colors.white,
        appBar: kIsWeb
            ? null
            : AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                toolbarHeight: 66,
                automaticallyImplyLeading: false,
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.neural50, width: 1),
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    // Back button - 24x24
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: SvgPicture.asset(
                        AppAssets.backIcon,
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          AppColors.black,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Avatar - 36x36
                    _buildAvatar(),
                    const SizedBox(width: 8),
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.args.title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                              letterSpacing: -0.3,
                              height: 1.3,
                            ),
                          ),
                          ValueListenableBuilder<String?>(
                            valueListenable: _typingNameNotifier,
                            builder: (context, typingName, _) {
                              if (typingName != null) {
                                return Row(
                                  children: [
                                    Text(
                                      '$typingName is typing',
                                      style: const TextStyle(
                                        fontFamily: 'SF Pro Text',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0x66000000),
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const SizedBox(
                                      height: 16,
                                      child: TypingIndicator(
                                        dotSize: 6,
                                        dotSpacing: 2,
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                final subtitle = widget.args.isGroup
                                    ? (widget.args.memberCount != null
                                        ? '${widget.args.memberCount} members'
                                        : 'Group')
                                    : 'Conversation';
                                return Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontFamily: 'SF Pro Text',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0x66000000),
                                    height: 1.5,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                titleSpacing: 17,
              ),
        body: Column(
          children: [
            // Custom app bar for web
            if (kIsWeb)
              Container(
                height: 71.h,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.neural50)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          widget.args.avatar != null &&
                              widget.args.avatar!.isNotEmpty
                          ? NetworkImage(widget.args.avatar!)
                          : const AssetImage(AppAssets.appLogo)
                                as ImageProvider,
                      radius: 20.r,
                      backgroundColor: Colors.transparent,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.args.title,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.p2SemiBold(context).copyWith(
                              fontSize: 18.sp,
                              color: AppColors.black,
                              height: 1,
                            ),
                          ),
                          ValueListenableBuilder<String?>(
                            valueListenable: _typingNameNotifier,
                            builder: (context, typingName, _) {
                              if (typingName != null) {
                                return Row(
                                  children: [
                                    Text(
                                      '$typingName is typing',
                                      style:
                                          AppTextStyles.captionSemibold13(
                                            context,
                                          ).copyWith(
                                            color: Colors.grey[700],
                                            fontSize: 13.sp,
                                          ),
                                    ),
                                    SizedBox(width: 6.w),
                                    SizedBox(
                                      height: 16.h,
                                      child: const TypingIndicator(
                                        dotSize: 6,
                                        dotSpacing: 2,
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return Text(
                                  widget.args.isGroup
                                      ? 'Group'
                                      : 'Conversation',
                                  style:
                                      AppTextStyles.captionSemibold13(
                                        context,
                                      ).copyWith(
                                        color: Colors.grey,
                                        fontSize: 13.sp,
                                      ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (!kIsWeb) const Divider(height: 1, color: AppColors.neural50),
            // _EncryptionBanner(scaleHeight: scaleHeight, scaleWidth: scaleWidth),
            Expanded(
              child: BlocConsumer<ChatDetailBloc, ChatDetailState>(
                listener: (context, state) {
                  // Mark messages as read when chat is loaded
                  if (state is ChatDetailLoaded) {
                    _markVisibleMessagesAsRead(state.messages);
                  }
                },
                builder: (context, state) {
                  debugPrint('ChatDetailPage state: ${state.runtimeType}');
                  if (state is ChatDetailInitial || state is ChatDetailLoading) {
                    return const ChatDetailShimmer();
                  } else if (state is ChatDetailError) {
                    return CenterMessageWithButton(
                      message: state.message,
                      onPressed: loadChats,
                      scaleHeight:
                          context.scaleHeight, // pass your scaling util
                    );
                  } else {
                    // get current messages list safely
                    final messages = (state is ChatDetailLoaded)
                        ? state.messages
                        : (state is ChatDetailLoadingMore)
                        ? state.messages
                        : <MessageEntity>[];

                    final isLoadingMore = state is ChatDetailLoadingMore;

                    // build chat list items with grouping
                    final items = _buildChatItems(messages);

                    return Column(
                      children: [
                        if (isLoadingMore)
                          Padding(
                            padding: EdgeInsets.all(scaleWidth * 8.0),
                            child: const CircularProgressIndicator(),
                          ),
                        Expanded(
                          child: ListView.builder(
                            reverse: true,
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(
                              horizontal: 17 * scaleWidth,
                            ),
                            itemCount: items.length + 1,
                            itemBuilder: (context, index) {
                              if (index == items.length) {
                                // Encryption banner should always be on top
                                return const Padding(
                                  padding: EdgeInsets.only(
                                    top: 18,
                                    bottom: 18,
                                  ),
                                  child: _EncryptionBanner(),
                                );
                              }
                              final item = items[index];

                              if (item.type == _ChatListItemType.header) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 18,
                                    ),
                                    child: Text(
                                      item.header!,
                                      style: const TextStyle(
                                        fontFamily: 'SF Pro Text',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF666666),
                                        letterSpacing: -0.3,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              if (item.type == _ChatListItemType.message) {
                                final message = item.message!;
                                final isMine =
                                    _currentUserId == message.senderId;

                                // Calculate if we should show timestamp on web
                                bool showTimeOnWeb = true;
                                if (kIsWeb) {
                                  // Check next message for time grouping (since list is reversed)
                                  if (index < items.length - 1 &&
                                      items[index + 1].type ==
                                          _ChatListItemType.message) {
                                    final nextMessage =
                                        items[index + 1].message!;
                                    final currentTime = DateTime.parse(
                                      message.createdAt,
                                    );
                                    final nextTime = DateTime.parse(
                                      nextMessage.createdAt,
                                    );

                                    // Group messages within the same minute and same sender
                                    final sameMinute =
                                        currentTime.year == nextTime.year &&
                                        currentTime.month == nextTime.month &&
                                        currentTime.day == nextTime.day &&
                                        currentTime.hour == nextTime.hour &&
                                        currentTime.minute == nextTime.minute;

                                    final sameSender =
                                        message.senderId ==
                                        nextMessage.senderId;

                                    // Only show time if different minute OR different sender
                                    showTimeOnWeb = !sameMinute || !sameSender;
                                  }
                                }

                                // Check if message has decryption key (from bloc state)
                              final hasDecryptKey = message.decryptGroupKey != null;

                              return hasDecryptKey
                                    ? MessageBubbleWrapper(
                                        key: ValueKey(message.id),
                                        message: message,
                                        isMine: isMine,
                                        showSender:
                                            item.message!.showAvatarImage,
                                        showSenderName:
                                            item.message!.showSenderName,
                                        isSameSender: kIsWeb
                                            ? // Web: Group by same sender AND same timestamp
                                              index >= 1 &&
                                                  items[index - 1].type ==
                                                      _ChatListItemType
                                                          .message &&
                                                  (items[index - 1]
                                                          .message
                                                          ?.senderId ==
                                                      item.message?.senderId) &&
                                                  () {
                                                    final prevMessage =
                                                        items[index - 1]
                                                            .message!;
                                                    final currentTime =
                                                        DateTime.parse(
                                                          message.createdAt,
                                                        );
                                                    final prevTime =
                                                        DateTime.parse(
                                                          prevMessage.createdAt,
                                                        );
                                                    return currentTime.year ==
                                                            prevTime.year &&
                                                        currentTime.month ==
                                                            prevTime.month &&
                                                        currentTime.day ==
                                                            prevTime.day &&
                                                        currentTime.hour ==
                                                            prevTime.hour &&
                                                        currentTime.minute ==
                                                            prevTime.minute;
                                                  }()
                                            : // Mobile: Group by same sender only
                                              index >= 1 &&
                                                  items[index - 1].type ==
                                                      _ChatListItemType
                                                          .message &&
                                                  (items[index - 1]
                                                          .message
                                                          ?.senderId ==
                                                      item.message?.senderId),
                                        showTimeOnWeb: showTimeOnWeb,
                                        onRetry: (msg) {
                                          context.read<ChatDetailBloc>().add(
                                            RetrySendMessageEvent(
                                              msg,
                                              widget.args.version ?? 0,
                                            ),
                                          );
                                        },
                                        senderKey: message.decryptGroupKey!,
                                        iv: message.iv,
                                        chatId: widget.args.id,
                                        isGroup: widget.args.isGroup,
                                      )
                                    : const MessageSkeleton();
                              }

                              return const SizedBox.shrink();
                            },
                          ),
                        ),

                        // input bar
                        if (!kIsWeb)
                          const Divider(height: 1, color: AppColors.neural50),
                        SafeArea(
                          child: kIsWeb
                              ? _buildWebInputArea(isLoadingMore)
                              : _buildMobileInputArea(
                                  isLoadingMore,
                                  scaleWidth,
                                  scaleHeight,
                                ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EncryptionBanner extends StatelessWidget {
  const _EncryptionBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              AppAssets.lockIcon,
              width: 12,
              height: 12,
              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ),
            const SizedBox(width: 4),
            const Text(
              'Messages are end-to-end encrypted.',
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                letterSpacing: -0.3,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatListItem {
  _ChatListItem._({
    required this.type,
    this.header,
    this.message,
    this.isMine = false,
    this.showSenderAvatar = true,
    this.showSenderName = true,
    this.time,
  });

  factory _ChatListItem.header(String text) =>
      _ChatListItem._(type: _ChatListItemType.header, header: text);

  factory _ChatListItem.message(
    MessageEntity msg, {
    required bool showSender,
    required bool showSenderName,
    required String time,
  }) => _ChatListItem._(
    type: _ChatListItemType.message,
    message: msg,
    showSenderAvatar: showSender,
    showSenderName: showSenderName,
    isMine: msg.isSenderYou,
    time: time,
  );
  final _ChatListItemType type;
  final String? header;
  final MessageEntity? message;
  final bool isMine;
  final bool showSenderAvatar;
  final bool showSenderName;
  final String? time;

  @override
  String toString() {
    return '_ChatListItem{type: $type, header: $header, message: $message, isMine: $isMine, showSender: $showSenderAvatar,showSenderName: $showSenderName, time: $time}';
  }

  _ChatListItem copyWith({required bool showSenderName}) {
    return _ChatListItem._(
      type: type,
      header: header,
      message: message,
      isMine: isMine,
      showSenderAvatar: showSenderAvatar,
      showSenderName: showSenderName,
      time: time,
    );
  }
}

enum _ChatListItemType { header, message }

List<_ChatListItem> _buildChatItems(List<MessageEntity> messages) {
  final items = <_ChatListItem>[];

  final ordered = messages.toList();
  if (ordered.isEmpty) return items;

  String? lastDateKey = _getDateKey(DateTime.parse(ordered.first.createdAt).toLocal());
  DateTime? firstMsgTimeForDay = DateTime.parse(ordered.first.createdAt).toLocal();

  for (var i = 0; i < ordered.length; i++) {
    final msg = ordered[i];
    final msgDate = DateTime.parse(msg.createdAt).toLocal();
    final dateKey = _getDateKey(msgDate);

    items.add(
      _ChatListItem.message(
        msg,
        showSender: msg.showAvatarImage,
        showSenderName: msg.showSenderName,
        time: _formatTime(msgDate),
      ),
    );

    if (dateKey != lastDateKey) {
      // Day changed - add header for the previous day
      final lastMessage = items.removeLast();

      // Add header with the first message time of that day
      items
        ..add(_ChatListItem.header(_formatDateHeader(firstMsgTimeForDay!)))
        ..add(lastMessage);

      lastDateKey = dateKey;
      firstMsgTimeForDay = msgDate;
    }

    // Last message - add header for current day
    if (i == ordered.length - 1) {
      items.add(_ChatListItem.header(_formatDateHeader(firstMsgTimeForDay!)));
    }
  }
  return items;
}

/// Returns a date-only key for grouping messages by day (no time)
String _getDateKey(DateTime dt) {
  return '${dt.year}-${dt.month}-${dt.day}';
}

String _formatDateHeader(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final msgDate = DateTime(dt.year, dt.month, dt.day);

  // Format time as "2:31 PM"
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final timeStr = '$hour:$minute $ampm';

  if (msgDate == today) return 'Today, $timeStr';
  if (msgDate == yesterday) return 'Yesterday, $timeStr';

  // Format as "Thu, May 06, 2:31 PM"
  final dayName = _dayName(dt.weekday);
  final monthName = _monthName(dt.month);
  final day = dt.day.toString().padLeft(2, '0');

  return '$dayName, $monthName $day, $timeStr';
}

String _dayName(int weekday) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[weekday - 1];
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}

String _formatTime(DateTime dt) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $ampm';
}

extension _ChatDetailPageMethods on _ChatDetailPageState {
  /// Builds avatar with proper placeholder for group/individual chats
  Widget _buildAvatar() {
    final hasAvatar = widget.args.avatar != null && widget.args.avatar!.isNotEmpty;

    if (hasAvatar) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(widget.args.avatar!),
        backgroundColor: Colors.transparent,
      );
    }

    // Show placeholder based on chat type
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.neural50,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SvgPicture.asset(
          widget.args.isGroup ? AppAssets.groupIcon : AppAssets.profileIcon,
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
            AppColors.neural400,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildWebInputArea(bool isLoadingMore) {
    return Container(
      padding: EdgeInsets.all(24.w),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF808080).withValues(alpha: 0.10),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: const Color(0xFF808080).withValues(alpha: 0.09),
                  blurRadius: 5,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: const Color(0xFF808080).withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF808080).withValues(alpha: 0.01),
                  blurRadius: 7,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Row(
              children: [
                // Attachment button inside input field
                Padding(
                  padding: EdgeInsets.only(left: 16.w),
                  child: GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: FileConstants.allowedFileExtensions,
                      );
                      if (result != null &&
                          result.files.single.path != null &&
                          _currentUserId != null) {
                        if (!context.mounted) return;
                        final file = result.files.single;

                        // Validate file type
                        if (!FileConstants.isFileTypeAllowed(file.name)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'File type not supported. ${FileConstants.allowedFormatsMessage}',
                              ),
                              duration: const Duration(seconds: 3),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Validate file size
                        if (!FileConstants.isFileSizeAllowed(file.size)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'File too large. Maximum size is ${FileConstants.getFormattedFileSize(FileConstants.maxFileSize)}',
                              ),
                              duration: const Duration(seconds: 3),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        var isSending = false;
                        await showDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return FileSendDialog(
                                  file: file,
                                  args: widget.args,
                                  currentUserId: _currentUserId!,
                                  isLoading: isSending,
                                  onSend: () async {
                                    setState(() => isSending = true);

                                    try {
                                      // Read file bytes (web-compatible)
                                      List<int> fileBytes;
                                      if (kIsWeb) {
                                        fileBytes = file.bytes!;
                                      } else {
                                        fileBytes = await File(
                                          file.path!,
                                        ).readAsBytes();
                                      }

                                      // Skip file encryption - send filename directly without encryption
                                      context.read<ChatDetailBloc>().add(
                                        SendFileMessageEvent(
                                          iv: '', // No IV needed since no encryption
                                          isGroup: widget.args.isGroup,
                                          groupId: widget.args.id,
                                          fileBytes: fileBytes,
                                          fileName: file.name,
                                          fileType: file.extension ?? '',
                                          currentUserId: _currentUserId!,
                                          encryptedGroupKey:
                                              widget.args.encryptedGroupKey!,
                                          version: widget.args.version ?? 0,
                                          fileSize: fileBytes.length.toString(),
                                          filePages: 1,
                                          content: file.name, // Send filename as plain text
                                        ),
                                      );
                                      Navigator.pop(context);
                                    } catch (e) {
                                      setState(() => isSending = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to read file: $e',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                );
                              },
                            );
                          },
                        );
                      }
                    },
                    child: Icon(
                      Icons.attach_file,
                      color: AppColors.black,
                      size: 20.sp,
                    ),
                  ),
                ),
                // Text input field
                Expanded(
                  child: RawKeyboardListener(
                    focusNode: FocusNode(),
                    onKey: (RawKeyEvent event) {
                      if (event is RawKeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter) {
                        if (event.isShiftPressed) {
                          // Shift+Enter: Manually add new line
                          final currentText = _textController.text;
                          final selection = _textController.selection;
                          final newText = currentText.replaceRange(
                            selection.start,
                            selection.end,
                            '\n',
                          );
                          _textController.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(
                              offset: selection.start + 1,
                            ),
                          );
                          return;
                        } else {
                          // Enter only: Send message and prevent default behavior
                          final content = _textController.text.trim();
                          if (!isLoadingMore &&
                              content.isNotEmpty &&
                              _currentUserId != null) {
                            _sendMessage(content);
                          }
                          return;
                        }
                      }
                    },
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _textController,
                      cursorColor: const Color(0xFF23223A),
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.none,
                      // Prevent default Enter behavior
                      minLines: 1,
                      maxLines: 3,
                      style: AppTextStyles.p3Regular(context).copyWith(
                        color: AppColors.black,
                        fontSize: 14.sp,
                        height: 1.3,
                        fontWeight: FontWeight.w400,
                      ),

                      decoration: InputDecoration(
                        hintText: 'Write here',
                        hintStyle: AppTextStyles.p3Regular(context).copyWith(
                          color: AppColors.neural400,
                          fontSize: 14.sp,
                          height: 1.3,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          // Helper text
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Shift + Enter to add a new line',
              style: AppTextStyles.p2SemiBold(context).copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.neural300,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInputArea(
    bool isLoadingMore,
    double scaleWidth,
    double scaleHeight,
  ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5E5), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text input area
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 100),
            child: TextField(
              focusNode: _focusNode,
              controller: _textController,
              cursorColor: const Color(0xFF23223A),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              maxLines: null,
              style: const TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                letterSpacing: -0.3,
                height: 1.4,
              ),
              decoration: const InputDecoration(
                hintText: 'Send a message...',
                hintStyle: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF666666),
                  letterSpacing: -0.3,
                  height: 1.4,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Bottom row with attachment buttons and send
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Attachment buttons
              Row(
                children: [
                  // Attachment button
                  _buildCircularButton(
                    onTap: () => _onAttachmentTap(context),
                    child: SvgPicture.asset(
                      AppAssets.attachFileIcon,
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Camera button
                  _buildCircularButton(
                    onTap: () => _showImagePickerSheet(context),
                    child: SvgPicture.asset(
                      AppAssets.cameraIcon,
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
              // Send button
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _textController,
                builder: (context, value, child) {
                  final hasText = value.text.trim().isNotEmpty;
                  return GestureDetector(
                    onTap: hasText && !isLoadingMore
                        ? () {
                            final content = _textController.text.trim();
                            if (content.isEmpty || _currentUserId == null) {
                              return;
                            }
                            _sendMessage(content);
                          }
                        : null,
                    child: Text(
                      'Send',
                      style: TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: hasText && !isLoadingMore
                            ? const Color(0xFF25253D)
                            : const Color(0xFF9F9D9F),
                        letterSpacing: -0.3,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFB3B5B6).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }

  Future<void> _onAttachmentTap(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: FileConstants.allowedFileExtensions,
    );
    if (result != null &&
        result.files.single.path != null &&
        _currentUserId != null) {
      if (!context.mounted) return;
      final file = result.files.single;

      // Validate file type
      if (!FileConstants.isFileTypeAllowed(file.name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File type not supported. ${FileConstants.allowedFormatsMessage}',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate file size
      if (!FileConstants.isFileSizeAllowed(file.size)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File too large. Maximum size is ${FileConstants.getFormattedFileSize(FileConstants.maxFileSize)}',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      var isSending = false;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setState) {
              return FileSendDialog(
                file: file,
                args: widget.args,
                currentUserId: _currentUserId!,
                isLoading: isSending,
                onSend: () async {
                  setState(() => isSending = true);

                  try {
                    // Read file bytes (mobile)
                    final fileBytes = await File(
                      file.path!,
                    ).readAsBytes();

                    // Skip file encryption - send filename directly without encryption
                    context.read<ChatDetailBloc>().add(
                      SendFileMessageEvent(
                        iv: '', // No IV needed since no encryption
                        isGroup: widget.args.isGroup,
                        groupId: widget.args.id,
                        fileBytes: fileBytes,
                        fileName: file.name,
                        fileType: file.extension ?? '',
                        currentUserId: _currentUserId!,
                        encryptedGroupKey:
                            widget.args.encryptedGroupKey!,
                        version: widget.args.version ?? 0,
                        fileSize: fileBytes.length.toString(),
                        filePages: 1,
                        content: file.name, // Send filename as plain text
                      ),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    setState(() => isSending = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to read file: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      );
    }
  }

  void _sendMessage(String content) {
    // Get the cached group key from the bloc
    final bloc = context.read<ChatDetailBloc>();
    final groupKey = bloc.cachedGroupKey ?? widget.args.decryptGroupKey;

    if (groupKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to send message. Please wait for chat to load.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final encryptedMessage = CryptoService.encryptGroupMessage(
      groupKey,
      content,
    );
    final cipherText = encryptedMessage['cipherText'];
    final iv = encryptedMessage['iv'];
    bloc.add(
      SendMessageEvent(
        isGroup: widget.args.isGroup,
        id: widget.args.id,
        content: cipherText!,
        iv: iv!,
        currentUserId: _currentUserId!,
        encryptedGroupKey: widget.args.encryptedGroupKey!,
        version: widget.args.version ?? 0,
      ),
    );

    _textController.clear();
    _hasEmittedTyping = false;
    _focusNode.requestFocus();
  }

  void _showImagePickerSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neural300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                const Text(
                  'Select Image',
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 24),
                // Camera option
                _buildImagePickerOption(
                  icon: Icons.camera_alt_outlined,
                  title: 'Camera',
                  subtitle: 'Take a photo',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 12),
                // Gallery option
                _buildImagePickerOption(
                  icon: Icons.photo_library_outlined,
                  title: 'Gallery',
                  subtitle: 'Choose from your photos',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF25253D),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF666666),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF666666),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final fileBytes = await file.readAsBytes();
      final fileName = pickedFile.name;
      final fileExtension = fileName.split('.').last.toLowerCase();

      // Validate file type
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(fileExtension)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unsupported image format. Please select a JPG, PNG, GIF, or WebP image.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show file send dialog
      if (!mounted || _currentUserId == null) return;

      var isSending = false;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setState) {
              return FileSendDialog(
                file: PlatformFile(
                  name: fileName,
                  size: fileBytes.length,
                  path: pickedFile.path,
                  bytes: fileBytes,
                ),
                args: widget.args,
                currentUserId: _currentUserId!,
                isLoading: isSending,
                onSend: () async {
                  setState(() => isSending = true);

                  try {
                    context.read<ChatDetailBloc>().add(
                      SendFileMessageEvent(
                        iv: '',
                        isGroup: widget.args.isGroup,
                        groupId: widget.args.id,
                        fileBytes: fileBytes,
                        fileName: fileName,
                        fileType: fileExtension,
                        currentUserId: _currentUserId!,
                        encryptedGroupKey: widget.args.encryptedGroupKey!,
                        version: widget.args.version ?? 0,
                        fileSize: fileBytes.length.toString(),
                        filePages: 1,
                        content: fileName,
                      ),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    setState(() => isSending = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to send image: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
