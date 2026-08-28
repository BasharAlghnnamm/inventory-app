import 'dart:convert';
import 'dart:typed_data';

/// Product images are stored inline as `data:` URIs so the same rows work on
/// every platform, including the browser (which has no local filesystem).
class ImageStore {
  ImageStore._();

  static String encode(Uint8List bytes, {String? extension}) {
    final ext = (extension ?? 'png').toLowerCase();
    final mime = switch (ext) {
      'jpg' || 'jpeg' => 'jpeg',
      'gif' => 'gif',
      'webp' => 'webp',
      _ => 'png',
    };
    return 'data:image/$mime;base64,${base64Encode(bytes)}';
  }

  static bool isDataUri(String value) => value.startsWith('data:image/');

  static Uint8List decode(String value) {
    final comma = value.indexOf(',');
    return base64Decode(value.substring(comma + 1));
  }
}