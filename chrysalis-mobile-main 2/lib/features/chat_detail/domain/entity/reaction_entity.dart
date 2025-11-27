class ReactionEntity {
  const ReactionEntity({
    required this.id,
    required this.emoji,
    required this.userId,
    required this.createdAt,
  });

  final String id;
  final String emoji;
  final String userId;
  final String createdAt;

  ReactionEntity copyWith({
    String? id,
    String? emoji,
    String? userId,
    String? createdAt,
  }) {
    return ReactionEntity(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReactionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class MessageReactionEntity {
  const MessageReactionEntity({
    required this.messageId,
    required this.reactions,
  });

  final String messageId;
  final List<ReactionEntity> reactions;

  Map<String, List<ReactionEntity>> get groupedReactions {
    final Map<String, List<ReactionEntity>> grouped = {};
    for (final reaction in reactions) {
      grouped.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }
    return grouped;
  }

  bool hasUserReaction(String userId, String emoji) {
    return reactions.any((r) => r.userId == userId && r.emoji == emoji);
  }

  int getReactionCount(String emoji) {
    return reactions.where((r) => r.emoji == emoji).length;
  }

  MessageReactionEntity copyWith({
    String? messageId,
    List<ReactionEntity>? reactions,
  }) {
    return MessageReactionEntity(
      messageId: messageId ?? this.messageId,
      reactions: reactions ?? this.reactions,
    );
  }
}