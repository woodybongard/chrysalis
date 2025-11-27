import 'dart:convert';

class GroupMessageEntity {
  GroupMessageEntity({
    required this.isGroup,
    required this.groupId,
    required this.content,
    required this.encryptedGroupKey,
    required this.version,
    this.iv,
    this.type,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.filePath,
    this.filePages,
  });
  final bool isGroup;
  final String groupId; // conversationId / groupId
  final String content; // cipher text (base64)
  final String? iv; // AES IV (base64)
  final String
  encryptedGroupKey; // group sender key encrypted with recipient’s RSA
  final String? fileName;
  final String? type;
  final String? fileType;
  final String? fileSize;
  final String? filePath;
  final int? filePages;
  final int version;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'isGroup': isGroup,
      'id': groupId,
      'content': content,
      'iv': iv,
      'encryptedGroupKey': encryptedGroupKey,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'filePages': filePages,
      'file': filePath,
      'version': version,
    };
  }

  /// For debugging
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
