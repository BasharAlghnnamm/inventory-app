import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Triggers a browser download instead of a native file dialog.
Future<void> saveFileDialog(
  String suggestedName,
  Uint8List bytes,
  String ext,
) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/octet-stream'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = suggestedName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}