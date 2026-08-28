import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

/// Shows the native save dialog and writes [bytes] to the chosen location.
Future<void> saveFileDialog(String suggestedName, Uint8List bytes, String ext) {
  const typeGroups = [
    XTypeGroup(label: 'Excel', extensions: ['xlsx']),
    XTypeGroup(label: 'PDF', extensions: ['pdf']),
  ];
  return _write(suggestedName, bytes, ext, typeGroups);
}

Future<void> _write(
  String suggestedName,
  Uint8List bytes,
  String ext,
  List<XTypeGroup> typeGroups,
) async {
  final groups =
      typeGroups.where((g) => (g.extensions ?? const []).contains(ext)).toList();
  final location = await getSaveLocation(
    suggestedName: suggestedName,
    acceptedTypeGroups: groups,
  );
  if (location == null) return;
  await File(location.path).writeAsBytes(bytes);
}