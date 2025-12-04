// This is a stub for dart:html for non-web platforms.
// It provides dummy classes and methods to avoid compilation errors.

class Blob {
  Blob(List<dynamic> blobParts, [String? type, String? endings]);
}

class Url {
  static String createObjectUrlFromBlob(dynamic blob) {
    throw UnsupportedError('HTML is not supported on this platform.');
  }

  static void revokeObjectUrl(String url) {
    throw UnsupportedError('HTML is not supported on this platform.');
  }
}

class AnchorElement {
  String? download;
  String? href;
  String? target;

  // FIX: style should always exist
  Map<String, String> style = {};

  AnchorElement({this.href});

  void setAttribute(String key, String value) {
    style[key] = value;
  }

  void click() {
    throw UnsupportedError('HTML is not supported on this platform.');
  }

  void remove() {}
}

// Add minimal document + body support
class DocumentBody {
  void append(dynamic element) {}
}

class Document {
  DocumentBody? body = DocumentBody();
}

final document = Document();
