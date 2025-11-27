import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:chrysalis_mobile/core/constants/app_keys.dart';
import 'package:chrysalis_mobile/core/local_storage/local_storage.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/message_entity.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/bloc/chat_detail_bloc.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/widgets/message_bubble.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/widgets/emoji_reaction_overlay.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/widgets/message_reactions.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class MessageBubbleWrapper extends StatefulWidget {
  const MessageBubbleWrapper({
    required this.message,
    required this.isMine,
    required this.showSenderName,
    required this.senderKey,
    required this.iv,
    required this.chatId,
    required this.isGroup,
    super.key,
    this.showSender = true,
    this.isSameSender = false,
    this.showTimeOnWeb = true,
    this.onRetry,
  });

  final MessageEntity message;
  final bool isMine;
  final bool showSender;
  final bool showSenderName;
  final bool? isSameSender;
  final bool showTimeOnWeb;
  final MessageRetryCallback? onRetry;
  final String iv;
  final encrypt.Key senderKey;
  final String chatId;
  final bool isGroup;

  @override
  State<MessageBubbleWrapper> createState() => _MessageBubbleWrapperState();
}

class _MessageBubbleWrapperState extends State<MessageBubbleWrapper> {
  OverlayEntry? _overlayEntry;
  bool _showingOverlay = false;
  List<String> _recentEmojis = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadRecentEmojis();
  }

  Future<void> _loadCurrentUser() async {
    final userId = await LocalStorage().read(key: AppKeys.userID);
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  Future<void> _loadRecentEmojis() async {
    // Load recent emojis from local storage
    final recentEmojisString = await LocalStorage().read(key: 'recent_reaction_emojis');
    if (recentEmojisString != null && recentEmojisString.isNotEmpty) {
      setState(() {
        _recentEmojis = recentEmojisString.split(',').take(5).toList();
      });
    }
  }

  Future<void> _saveRecentEmoji(String emoji) async {
    final updatedEmojis = [emoji, ..._recentEmojis.where((e) => e != emoji)].take(5).toList();
    await LocalStorage().write(key: 'recent_reaction_emojis', value: updatedEmojis.join(','));
    setState(() {
      _recentEmojis = updatedEmojis;
    });
  }

  void _showEmojiOverlay(BuildContext context, Offset tapPosition) {
    if (_showingOverlay) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final globalPosition = renderBox.localToGlobal(tapPosition);
    
    // Get screen size for boundary checking
    final screenSize = MediaQuery.of(context).size;
    final overlayWidth = 280.0; // Approximate width of emoji overlay
    
    // Calculate optimal position
    double left = globalPosition.dx - (overlayWidth / 2);
    double top = globalPosition.dy - 80; // Show above the tap point
    
    // Ensure overlay stays within screen bounds
    if (left < 16) left = 16;
    if (left + overlayWidth > screenSize.width - 16) {
      left = screenSize.width - overlayWidth - 16;
    }
    if (top < 60) {
      top = globalPosition.dy + 20; // Show below if not enough space above
    }
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: top,
        left: left,
        child: Material(
          color: Colors.transparent,
          child: EmojiReactionOverlay(
            onEmojiSelected: _onEmojiSelected,
            onPlusPressed: _onPlusPressed,
            recentEmojis: _recentEmojis,
            currentUserReactions: _getCurrentUserReactions(),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() {
      _showingOverlay = true;
    });

    // Auto-hide after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _hideOverlay();
    });
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    if (mounted) {
      setState(() {
        _showingOverlay = false;
      });
    }
  }

  List<String> _getCurrentUserReactions() {
    if (_currentUserId == null) return [];
    return widget.message.reactions
        .where((r) => r.userId == _currentUserId)
        .map((r) => r.emoji)
        .toList();
  }

  void _onEmojiSelected(String emoji) {
    _hideOverlay();
    _saveRecentEmoji(emoji);

    if (_currentUserId == null) return;

    // Check if user already reacted with this emoji
    final hasReaction = widget.message.reactions
        .any((r) => r.userId == _currentUserId && r.emoji == emoji);

    if (hasReaction) {
      // Remove reaction
      context.read<ChatDetailBloc>().add(
        RemoveReactionEvent(
          messageId: widget.message.id,
          chatId: widget.chatId,
          isGroup: widget.isGroup,
        ),
      );
    } else {
      // Add reaction
      context.read<ChatDetailBloc>().add(
        AddReactionEvent(
          messageId: widget.message.id,
          emoji: emoji,
          chatId: widget.chatId,
          isGroup: widget.isGroup,
        ),
      );
    }
  }

  void _onPlusPressed() {
    _hideOverlay();
    _showEmojiKeyboard(context);
  }

  void _showEmojiKeyboard(BuildContext context) {
    if (kIsWeb) {
      _showWebEmojiKeyboard(context);
    } else {
      _showMobileEmojiKeyboard(context);
    }
  }

  void _showWebEmojiKeyboard(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Align(
        alignment: Alignment.bottomRight,
        child: Container(
          width: 400,
          height: 300,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.textBackground,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose an emoji',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: emoji.EmojiPicker(
                  onEmojiSelected: (category, emojiObject) {
                    Navigator.pop(context);
                    _onEmojiSelected(emojiObject.emoji);
                  },
                  config: const emoji.Config(
                    emojiViewConfig: emoji.EmojiViewConfig(
                      emojiSizeMax: 24.0,
                      backgroundColor: AppColors.white,
                    ),
                    categoryViewConfig: emoji.CategoryViewConfig(
                      backgroundColor: AppColors.white,
                      iconColor: AppColors.neural400,
                      iconColorSelected: AppColors.textBackground,
                      indicatorColor: AppColors.textBackground,
                    ),
                    searchViewConfig: emoji.SearchViewConfig(
                      backgroundColor: AppColors.white,
                      buttonIconColor: AppColors.textBackground,
                    ),
                    bottomActionBarConfig: emoji.BottomActionBarConfig(
                      backgroundColor: AppColors.textBackground,
                      buttonColor: AppColors.textBackground,
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

  void _showMobileEmojiKeyboard(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neural300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: emoji.EmojiPicker(
                  onEmojiSelected: (category, emojiObject) {
                    Navigator.pop(context);
                    _onEmojiSelected(emojiObject.emoji);
                  },
                  config: const emoji.Config(
                    emojiViewConfig: emoji.EmojiViewConfig(
                      emojiSizeMax: 32.0,
                      backgroundColor: AppColors.white,
                    ),
                    categoryViewConfig: emoji.CategoryViewConfig(
                      backgroundColor: AppColors.white,
                      iconColor: AppColors.neural400,
                      iconColorSelected: AppColors.textBackground,
                      indicatorColor: AppColors.textBackground,
                    ),
                    searchViewConfig: emoji.SearchViewConfig(
                      backgroundColor: AppColors.white,
                      buttonIconColor: AppColors.textBackground,
                    ),
                    bottomActionBarConfig: emoji.BottomActionBarConfig(
                      backgroundColor: AppColors.white,
                      buttonColor: AppColors.textBackground,
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

  void _onReactionTap(String emoji) {
    if (_currentUserId == null) return;

    // Check if user already reacted with this emoji
    final hasReaction = widget.message.reactions
        .any((r) => r.userId == _currentUserId && r.emoji == emoji);

    if (hasReaction) {
      // Remove reaction
      context.read<ChatDetailBloc>().add(
        RemoveReactionEvent(
          messageId: widget.message.id,
          chatId: widget.chatId,
          isGroup: widget.isGroup,
        ),
      );
    } else {
      // Add reaction
      context.read<ChatDetailBloc>().add(
        AddReactionEvent(
          messageId: widget.message.id,
          emoji: emoji,
          chatId: widget.chatId,
          isGroup: widget.isGroup,
        ),
      );
    }
  }

  /// Calculate the left offset for reactions to account for avatar space
  double _getReactionLeftOffset() {
    if (kIsWeb) {
      // Web: avatar (24 units) + spacing (12 units) + message padding = ~48 units
      return 48;
    } else {
      // Mobile: avatar (24 units) + spacing (6 units) + message padding = ~42 units  
      return 42;
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Add bottom padding when message has reactions to prevent overlap
      margin: EdgeInsets.only(
        bottom: widget.message.reactions.isNotEmpty ? 16.0 : 0.0,
      ),
      child: GestureDetector(
        onTap: () {
          if (_showingOverlay) {
            _hideOverlay();
          }
        },
        onLongPressStart: (details) {
          _showEmojiOverlay(context, details.localPosition);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main message bubble
            MessageBubble(
              message: widget.message,
              isMine: widget.isMine,
              showSender: widget.showSender,
              showSenderName: widget.showSenderName,
              isSameSender: widget.isSameSender,
              showTimeOnWeb: widget.showTimeOnWeb,
              onRetry: widget.onRetry,
              iv: widget.iv,
              senderKey: widget.senderKey,
            ),
            // Reactions overlay positioned on the message
            if (widget.message.reactions.isNotEmpty && _currentUserId != null)
              Positioned(
                bottom: -8, // Slightly overlapping the message bubble
                left: widget.isMine ? null : _getReactionLeftOffset(),
                right: widget.isMine ? 12 : null,
                child: MessageReactions(
                  reactions: widget.message.reactions,
                  currentUserId: _currentUserId!,
                  onReactionTap: _onReactionTap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}