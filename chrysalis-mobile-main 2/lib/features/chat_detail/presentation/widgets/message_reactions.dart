import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/reaction_entity.dart';

class MessageReactions extends StatelessWidget {
  const MessageReactions({
    required this.reactions,
    required this.currentUserId,
    required this.onReactionTap,
    super.key,
  });

  final List<ReactionEntity> reactions;
  final String currentUserId;
  final Function(String emoji) onReactionTap;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    final scaleWidth = context.scaleWidth;
    final scaleHeight = context.scaleHeight;

    final groupedReactions = _groupReactionsByEmoji(reactions);

    // Group all reactions in a single container
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8 * scaleWidth,
        vertical: 4 * scaleHeight,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryTint1,
        borderRadius: BorderRadius.circular(kIsWeb ? 16.0 : 20 * scaleWidth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: groupedReactions.entries.toList().asMap().entries.map((indexedEntry) {
          final index = indexedEntry.key;
          final entry = indexedEntry.value;
          final emoji = entry.key;
          final reactionList = entry.value;
          final count = reactionList.length;
          final hasUserReaction = reactionList.any((r) => r.userId == currentUserId);

          return _buildReactionItem(
            emoji: emoji,
            count: count,
            hasUserReaction: hasUserReaction,
            scaleWidth: scaleWidth,
            scaleHeight: scaleHeight,
            context: context,
            isLastItem: index == groupedReactions.length - 1,
          );
        }).toList(),
      ),
    );
  }

  Map<String, List<ReactionEntity>> _groupReactionsByEmoji(List<ReactionEntity> reactions) {
    final Map<String, List<ReactionEntity>> grouped = {};
    for (final reaction in reactions) {
      grouped.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }
    return grouped;
  }

  Widget _buildReactionItem({
    required String emoji,
    required int count,
    required bool hasUserReaction,
    required double scaleWidth,
    required double scaleHeight,
    required BuildContext context,
    required bool isLastItem,
  }) {
    // Web-specific adjustments
    const isWeb = kIsWeb;
    final emojiSize = isWeb ? 14.0 : 15 * scaleHeight;
    final spacing = isWeb ? 6.0 : 4 * scaleWidth;
    
    return GestureDetector(
      onTap: () => onReactionTap(emoji),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: emojiSize),
          ),
          if (count > 1) ...[
            SizedBox(width: 2 * scaleWidth),
            Text(
              count.toString(),
              style: AppTextStyles.captionRegular(context).copyWith(
                fontSize: isWeb ? 11.0 : 9 * scaleHeight,
                color: hasUserReaction
                    ? AppColors.textBackground
                    : AppColors.neural502,
                fontWeight: isWeb ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
          // Add spacing between reactions except for the last item
          if (!isLastItem)
            SizedBox(width: spacing),
        ],
      ),
    );
  }
}