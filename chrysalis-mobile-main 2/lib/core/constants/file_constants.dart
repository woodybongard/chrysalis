/// File constants for the application
class FileConstants {
  // Private constructor to prevent instantiation
  FileConstants._();

  /// List of allowed file extensions for upload
  static const List<String> allowedFileExtensions = [
    'pdf',
    'dcm',
    'doc', 
    'docx',
    'exe',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'heic',
  ];

  /// Maximum file size in bytes (1 GB)
  static const int maxFileSize = 1024 * 1024 * 1024;

  /// Get user-friendly message for allowed formats
  static String get allowedFormatsMessage {
    return 'Allowed formats: ${allowedFileExtensions.map((e) => '.$e').join(', ')}';
  }

  /// Check if file extension is allowed
  static bool isFileTypeAllowed(String? fileName) {
    if (fileName == null || fileName.isEmpty) return false;
    
    final extension = fileName.split('.').last.toLowerCase();
    return allowedFileExtensions.contains(extension);
  }

  /// Check if file size is within limit
  static bool isFileSizeAllowed(int sizeInBytes) {
    return sizeInBytes <= maxFileSize;
  }

  /// Get formatted file size string
  static String getFormattedFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}