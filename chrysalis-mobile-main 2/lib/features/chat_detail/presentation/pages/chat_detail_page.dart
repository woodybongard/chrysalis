import 'dart:io';

import 'package:chrysalis_mobile/core/constants/app_assets.dart';
import 'package:chrysalis_mobile/core/constants/app_keys.dart';
import 'package:chrysalis_mobile/core/constants/file_constants.dart';
import 'package:chrysalis_mobile/core/crypto_services/crypto_service.dart';
import 'package:chrysalis_mobile/core/local_storage/chat_file_database.dart';
import 'package:chrysalis_mobile/core/local_storage/local_storage.dart';
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
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({required this.args, super.key});

  final ChatDetailArgs args;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final ValueNotifier<String?> _typingNameNotifier = ValueNotifier<String?>(
    null,
  );
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  String? _currentUserId;
  final ChatListHelper _joinRoomHelper = ChatListHelper();
  bool _hasEmittedTyping = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    if (widget.args.unReadMessage! > 0) {
      context.read<HomeBloc>().add(
        MarkAllAsReadEvent(type: widget.args.type, chatId: widget.args.id),
      );
    }
    _loadUserId();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadChats();
    });
    _joinRoomHelper
      ..listenForChatMessages((groupEntity) {
        if (mounted) {
          context.read<ChatDetailBloc>().add(
            PrependNewMessageEvent(groupEntity),
          );
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
      });
    _textController.addListener(_handleTyping);
  }

  Future<void> loadChats() async {
    await ChatFileDatabase().getAllFiles();
    if (!mounted) return;
    context.read<ChatDetailBloc>().add(
      LoadChatMessagesEvent(
        type: widget.args.type,
        id: widget.args.id,
        decryptGroupKey: widget.args.decryptGroupKey,
      ),
    );
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

  @override
  void dispose() {
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
            : PreferredSize(
                preferredSize: Size.fromHeight(60 * scaleHeight),
                child: AppBar(
                  leadingWidth: double.maxFinite,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  centerTitle: false,
                  leading: Padding(
                    padding: EdgeInsets.only(left: 10 * scaleWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: AppColors.black,
                            size: 24 * scaleWidth,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        CircleAvatar(
                          backgroundImage:
                              widget.args.avatar != null &&
                                  widget.args.avatar!.isNotEmpty
                              ? NetworkImage(widget.args.avatar!)
                              : const AssetImage(AppAssets.appLogo)
                                    as ImageProvider,
                          radius: 20 * scaleWidth,
                          backgroundColor: Colors.transparent,
                        ),
                        SizedBox(width: 8 * scaleWidth),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: MediaQuery.sizeOf(context).width * 0.6,
                              child: Text(
                                widget.args.title,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.p2SemiBold(context),
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(height: scaleHeight * 4),
                            ValueListenableBuilder<String?>(
                              valueListenable: _typingNameNotifier,
                              builder: (context, typingName, _) {
                                if (typingName != null) {
                                  return Row(
                                    children: [
                                      Text(
                                        '$typingName is typing',
                                        style: AppTextStyles.captionSemibold13(
                                          context,
                                        ).copyWith(color: Colors.grey[700]),
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
                                  return Text(
                                    widget.args.isGroup
                                        ? 'Group'
                                        : 'Conversation',
                                    style: AppTextStyles.captionSemibold13(
                                      context,
                                    ).copyWith(color: Colors.grey),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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
              child: BlocBuilder<ChatDetailBloc, ChatDetailState>(
                builder: (context, state) {
                  if (state is ChatDetailLoading) {
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
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: 20 * scaleHeight,
                                  ),
                                  child: _EncryptionBanner(
                                    scaleHeight: scaleHeight,
                                    scaleWidth: scaleWidth,
                                  ),
                                );
                              }
                              final item = items[index];

                              if (item.type == _ChatListItemType.header) {
                                return Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom: scaleWidth * 20.0,
                                    ),
                                    child: Text(
                                      item.header!,
                                      style:
                                          AppTextStyles.captionRegular(
                                            context,
                                          ).copyWith(
                                            color: AppColors.neural502,
                                            fontSize: kIsWeb ? 12 : null,
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

                                return widget.args.decryptGroupKey != null
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
  const _EncryptionBanner({
    required this.scaleHeight,
    required this.scaleWidth,
  });

  final double scaleHeight;
  final double scaleWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 10 * scaleHeight, bottom: 8 * scaleHeight),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppAssets.lockIcon,
            width: kIsWeb ? 14 : 12 * scaleWidth,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
          SizedBox(width: 6 * scaleWidth),
          Text(
            'Messages are end-to-end encrypted.',
            style: AppTextStyles.captionRegular(context).copyWith(
              color: AppColors.black,
              fontSize: kIsWeb ? 14 : 12 * scaleHeight,
            ),
          ),
        ],
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

  String? lastDateKey = ordered.isNotEmpty
      ? _formatDateHeader(DateTime.parse(ordered.first.createdAt).toLocal())
      : '';
  for (var i = 0; i < ordered.length; i++) {
    final msg = ordered[i];

    final msgDate = DateTime.parse(msg.createdAt).toLocal();
    items.add(
      _ChatListItem.message(
        msg,
        showSender: msg.showAvatarImage,
        showSenderName: msg.showSenderName,
        time: _formatTime(msgDate),
      ),
    );

    final dateKey = _formatDateHeader(msgDate);

    if (dateKey != lastDateKey) {
      // remove last message temporarily

      final lastMessage = items.removeLast();

      // add header first
      items
        ..add(_ChatListItem.header(lastDateKey!))
        ..add(lastMessage);
      // then re-add the last message

      lastDateKey = dateKey;
    }
    if (i == ordered.length - 1) {
      // add header first
      items.add(_ChatListItem.header(lastDateKey!));
      lastDateKey = dateKey;
    }
  }
  return items;
}

String _formatDateHeader(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final msgDate = DateTime(dt.year, dt.month, dt.day);

  if (msgDate == today) return 'Today';
  if (msgDate == yesterday) return 'Yesterday';

  return '${dt.day} ${_monthName(dt.month)} ${dt.year}';
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
    // Keep existing mobile input exactly as it was
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 17 * scaleWidth,
        vertical: 8 * scaleHeight,
      ),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          GestureDetector(
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
            },
            child: SvgPicture.asset(
              AppAssets.attachFileIcon,
              width: 24 * scaleWidth,
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
            ),
          ),
          SizedBox(width: 12 * scaleWidth),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 100),
              child: Scrollbar(
                child: TextField(
                  focusNode: _focusNode,
                  controller: _textController,
                  cursorColor: const Color(0xFF23223A),
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Send a message...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: isLoadingMore
                ? null
                : () {
                    final content = _textController.text.trim();
                    if (content.isEmpty || _currentUserId == null) {
                      return;
                    }
                    _sendMessage(content);
                  },
            child: Text(
              'Send',
              style: AppTextStyles.p2SemiBold(context).copyWith(
                color: isLoadingMore
                    ? AppColors.greyBorder
                    : AppColors.textBackground,
                fontSize: 16 * scaleHeight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String content) {
    final encryptedMessage = CryptoService.encryptGroupMessage(
      widget.args.decryptGroupKey!,
      content,
    );
    final cipherText = encryptedMessage['cipherText'];
    final iv = encryptedMessage['iv'];
    context.read<ChatDetailBloc>().add(
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
}
