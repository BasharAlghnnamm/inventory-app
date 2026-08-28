import 'package:sqflite_common/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Prepares the global SQLite factory for the web (IndexedDB backed wasm).
Future<void> bootstrapDatabaseFactory() async {
  databaseFactory = databaseFactoryFfiWeb;
}