import 'dart:io' show Directory, File, Platform;

import 'package:chrysalis_mobile/core/local_storage/chat_file_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ChatFileStorage {
  factory ChatFileStorage() => _instance;

  ChatFileStorage._internal();

  static final ChatFileStorage _instance = ChatFileStorage._internal();

  /// Base directory (user-visible in Android)

  Future<Directory> _getBaseDir() async {
    if (kIsWeb) {
      // Web doesn't support file system operations
      throw UnsupportedError(
        'File operations are not supported on web platform',
      );
    }

    Directory dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory())!;
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final base = Directory('${dir.path}/ChrysalisFiles');
    if (!base.existsSync()) {
      base.createSync(recursive: true);
    }
    return base;
  }

  /// Save a file in sent/received folder without overwriting existing files
  Future<String> saveFile({
    required File file,
    String? groupId,
    String? conversationId,
    bool isSent = false,
  }) async {
    try {
      final base = await _getBaseDir();
      final subFolder = isSent ? 'sent' : 'received';

      // folder per group or conversation
      final folder = groupId != null
          ? Directory(p.join(base.path, subFolder, 'group', groupId))
          : Directory(
              p.join(base.path, subFolder, 'conversation', conversationId),
            );

      if (!folder.existsSync()) {
        folder.createSync(recursive: true);
      }

      final fileName = p.basename(file.path);
      var destPath = p.join(folder.path, fileName);

      // ✅ Avoid overwriting: if file exists, add (1), (2), etc.
      destPath = await _getUniquePath(destPath);

      await file.copy(destPath);

      // save metadata in DB
      await ChatFileDatabase().insertFile({
        'fileName': p.basename(destPath),
        'filePath': destPath,
        'groupId': groupId,
        'conversationId': conversationId,
        'createdAt': DateTime.now().toIso8601String(),
      });

      return destPath;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  /// Ensure file is unique (no overwrite)
  Future<String> _getUniquePath(String path) async {
    var file = File(path);
    if (!file.existsSync()) return path;

    final dir = p.dirname(path);
    final name = p.basenameWithoutExtension(path);
    final ext = p.extension(path);

    var count = 1;
    String newPath;
    do {
      newPath = p.join(dir, '$name($count)$ext');
      file = File(newPath);
      count++;
    } while (file.existsSync());

    return newPath;
  }

  /// Search by groupId & conversationId (both optional)
  Future<List<String>> searchFiles({
    String? groupId,
    String? conversationId,
  }) async {
    try {
      final results = await ChatFileDatabase().searchFiles(
        groupId: groupId,
        conversationId: conversationId,
      );
      return results.map((row) => row['filePath'] as String).toList();
    } catch (e) {
      throw Exception('Failed to search files: $e');
    }
  }

  /// Clear all files and DB cache
  Future<void> clearAll() async {
    try {
      final base = await _getBaseDir();
      if (base.existsSync()) {
        base.deleteSync(recursive: true);
      }
      base.createSync(recursive: true);
      await ChatFileDatabase().clearAll();
    } catch (e) {
      throw Exception('Failed to clear files: $e');
    }
  }

  /// 🆕 Update temp conversationId → real one (after server confirms)
  Future<int> updateConversationId(
    String oldConversationId,
    String newConversationId,
  ) async {
    return ChatFileDatabase().updateConversationId(
      oldConversationId,
      newConversationId,
    );
  }
}
