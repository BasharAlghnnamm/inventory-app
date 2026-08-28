import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Prepares the global SQLite factory for io platforms (desktop + mobile).
Future<void> bootstrapDatabaseFactory() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}