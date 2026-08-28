import 'dart:typed_data';

/// The browser cannot read local file paths; legacy paths render as missing.
Future<Uint8List?> loadLegacyImage(String path) async => null;