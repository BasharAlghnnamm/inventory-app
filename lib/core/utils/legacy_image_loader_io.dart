import 'dart:io';
import 'dart:typed_data';

/// Loads image bytes from a plain file path (rows written by older
/// desktop builds that stored local paths instead of data URIs).
Future<Uint8List?> loadLegacyImage(String path) async {
  final file = File(path);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}