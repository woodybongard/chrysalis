import 'package:chrysalis_mobile/features/chat_detail/domain/entity/reaction_entity.dart';

class ReactionModel extends ReactionEntity {
  const ReactionModel({
    required super.id,
    required super.emoji,
    required super.userId,
    required super.createdAt,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      id: json['id'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emoji': emoji,
      'userId': userId,
      'createdAt': createdAt,
    };
  }

  static List<ReactionModel> listFromJson(dynamic jsonList) {
    if (jsonList is List) {
      return jsonList
          .whereType<Map<String, dynamic>>()
          .map(ReactionModel.fromJson)
          .toList();
    }
    return [];
  }
}