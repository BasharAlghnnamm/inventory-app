import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Resolves the SQLite file path for io platforms (desktop + mobile).
Future<String> resolveDbPath() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'inventory.db');
  }
  return p.join(await getDatabasesPath(), 'inventory.db');
}