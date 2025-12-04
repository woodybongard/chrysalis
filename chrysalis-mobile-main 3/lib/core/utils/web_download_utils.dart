import 'package:flutter/foundation.dart';

import 'html_proxy.dart' as html;

// Simple web download utility using dart:html (Flutter web best practice)
class WebDownloadUtils {
  static Future<void> downloadFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (!kIsWeb) {
      throw UnsupportedError('Web download is only supported on web platform');
    }

    try {
      // Use dart:html approach - simple and reliable
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create anchor element and trigger download
      final anchor = html.AnchorElement(href: url)
        ..download = fileName
        ..click();

      // Clean up the blob URL to prevent memory leaks
      html.Url.revokeObjectUrl(url);

      debugPrint('✅ Web download completed for: $fileName');
    } catch (e) {
      debugPrint('❌ Web download error: $e');
      throw Exception('Failed to download file: $e');
    }
  }

  /// Download a file directly from a URL (when file is already hosted)
  static void downloadFromUrl({required String url, required String fileName}) {
    if (!kIsWeb) {
      throw UnsupportedError('Web download is only supported on web platform');
    }

    try {
      final anchor = html.AnchorElement(href: url)
        ..download = fileName
        ..target = '_blank'
        ..setAttribute('style', 'display:none'); // FIXED

      html.document.body!.append(anchor);
      anchor..click()
      ..remove();

      debugPrint('✅ Forced URL download triggered for: $fileName');
    } catch (e) {
      debugPrint('❌ Direct URL download error: $e');
      throw Exception('Failed to download from URL: $e');
    }
  }
}
