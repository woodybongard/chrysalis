import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';

class EmojiReactionOverlay extends StatefulWidget {
  const EmojiReactionOverlay({
    required this.onEmojiSelected,
    required this.onPlusPressed,
    required this.recentEmojis,
    required this.currentUserReactions,
    super.key,
  });

  final Function(String emoji) onEmojiSelected;
  final VoidCallback onPlusPressed;
  final List<String> recentEmojis;
  final List<String> currentUserReactions;

  @override
  State<EmojiReactionOverlay> createState() => _EmojiReactionOverlayState();
}

class _EmojiReactionOverlayState extends State<EmojiReactionOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  static const List<String> _defaultEmojis = ['👍', '❤️', '😂', '😮', '😢'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<String> get _displayEmojis {
    final List<String> displayList = [];
    
    // Add recent emojis first (up to 5)
    displayList.addAll(widget.recentEmojis.take(5));
    
    // Fill remaining slots with default emojis that aren't already in the list
    for (final defaultEmoji in _defaultEmojis) {
      if (displayList.length >= 5) break;
      if (!displayList.contains(defaultEmoji)) {
        displayList.add(defaultEmoji);
      }
    }
    
    // Ensure we always have exactly 5 emojis
    while (displayList.length < 5) {
      // If we still need more emojis, add more defaults
      const moreEmojis = ['🔥', '💯', '😍', '😭', '🎉'];
      for (final emoji in moreEmojis) {
        if (displayList.length >= 5) break;
        if (!displayList.contains(emoji)) {
          displayList.add(emoji);
        }
      }
    }
    
    return displayList.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scaleWidth = context.scaleWidth;
    final scaleHeight = context.scaleHeight;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scaleWidth,
                vertical: 8 * scaleHeight,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25 * scaleWidth),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10 * scaleWidth,
                    offset: Offset(0, 2 * scaleHeight),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._displayEmojis.asMap().entries.map((entry) {
                    final emoji = entry.value;
                    final isSelected = widget.currentUserReactions.contains(emoji);
                    return _buildEmojiButton(
                      emoji,
                      isSelected,
                      scaleWidth,
                      scaleHeight,
                    );
                  }),
                  SizedBox(width: 4 * scaleWidth),
                  _buildPlusButton(scaleWidth, scaleHeight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmojiButton(
    String emoji,
    bool isSelected,
    double scaleWidth,
    double scaleHeight,
  ) {
    // Make buttons perfectly circular with fixed size
    final buttonSize = kIsWeb ? 36.0 : 32 * scaleWidth;
    final emojiSize = kIsWeb ? 22.0 : 20 * scaleHeight;
    
    return GestureDetector(
      onTap: () => widget.onEmojiSelected(emoji),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        margin: EdgeInsets.symmetric(horizontal: 2 * scaleWidth),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.textBackground.withValues(alpha: 0.2)
              : Colors.transparent,
          shape: BoxShape.circle, // Perfect circle
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(
              fontSize: emojiSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlusButton(double scaleWidth, double scaleHeight) {
    return GestureDetector(
      onTap: widget.onPlusPressed,
      child: Container(
        padding: EdgeInsets.all(5 * scaleWidth),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(20 * scaleWidth),
        ),
        child: Icon(
          Icons.add,
          size: 20 * scaleHeight,
          color: AppColors.neural502,
        ),
      ),
    );
  }
}
