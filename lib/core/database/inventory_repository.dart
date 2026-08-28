import 'package:sqflite_common/sqflite.dart';

import '../../features/inventory/inventory_item.dart';
import '../../features/inventory/inventory_session.dart';
import '../../features/inventory/session_config.dart';
import '../../features/products/product.dart';
import 'database_service.dart';

/// Data access layer for all SQLite operations.
///
/// All queries run on a single connection; writes are serialized in
/// transactions to avoid locking issues.
class InventoryRepository {
  InventoryRepository(this._db);

  final DatabaseService _db;

  Future<Database> get _database => _db.database;

  // /-------------------------  Sessions  ------------------------------/

  Future<int> createSession(String name, SessionConfig config) async {
    final db = await _database;
    return db.insert('Inventory_Sessions', {
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
      'column_config': config.encode(),
    });
  }

  Future<void> updateSessionConfig(int id, SessionConfig config) async {
    final db = await _database;
    await db.update(
      'Inventory_Sessions',
      {'column_config': config.encode()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<InventorySession>> getSessions() async {
    final db = await _database;
    final rows = await db.query(
      'Inventory_Sessions',
      orderBy: 'created_at DESC',
    );
    return rows.map(InventorySession.fromMap).toList();
  }

  Future<void> deleteSession(int id) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete(
        'Inventory_Items',
        where: 'session_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'Inventory_Sessions',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // /-------------------------  Products  ------------------------------/

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await _database;
    final rows = await db.query(
      'Products',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<int> insertProduct(Product product) async {
    final db = await _database;
    return db.insert('Products', product.toMap());
  }

  // /---------------------  Inventory Items  ---------------------------/

  /// Adds one unit of [productId] to [sessionId]. If it already exists in the
  /// session, increments its quantity; otherwise inserts a new row.
  Future<void> addItem(int sessionId, int productId) async {
    final db = await _database;
    await db.transaction((txn) async {
      final existing = await txn.query(
        'Inventory_Items',
        where: 'session_id = ? AND product_id = ?',
        whereArgs: [sessionId, productId],
        limit: 1,
      );
      if (existing.isEmpty) {
        await txn.insert('Inventory_Items', {
          'session_id': sessionId,
          'product_id': productId,
          'quantity': 1,
        });
      } else {
        final id = existing.first['id'] as int;
        await txn.rawUpdate(
          'UPDATE Inventory_Items SET quantity = quantity + 1 WHERE id = ?',
          [id],
        );
      }
    });
  }

  /// Returns all items for a session, joined with product details.
  Future<List<InventoryItem>> getItems(int sessionId) async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT ii.id, ii.session_id, ii.product_id, ii.quantity,
             p.barcode, p.name, p.image_path, p.cost_price, p.selling_price,
             p.batch_no, p.note, p.expiration_date, p.color,
             p.other_1, p.other_2, p.other_3, p.other_4, p.other_5
      FROM Inventory_Items ii
      INNER JOIN Products p ON p.id = ii.product_id
      WHERE ii.session_id = ?
      ORDER BY ii.id
    ''', [sessionId]);

    final productRows = rows.map((r) {
      final map = Map<String, Object?>.from(r);
      // Build a product map from the joined columns.
      return {
        'id': map['product_id'],
        'barcode': map['barcode'],
        'name': map['name'],
        'image_path': map['image_path'],
        'cost_price': map['cost_price'],
        'selling_price': map['selling_price'],
        'batch_no': map['batch_no'],
        'note': map['note'],
        'expiration_date': map['expiration_date'],
        'color': map['color'],
        'other_1': map['other_1'],
        'other_2': map['other_2'],
        'other_3': map['other_3'],
        'other_4': map['other_4'],
        'other_5': map['other_5'],
      };
    }).toList();

    final items = <InventoryItem>[];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      items.add(InventoryItem(
        id: r['id'] as int,
        sessionId: r['session_id'] as int,
        productId: r['product_id'] as int,
        quantity: r['quantity'] as int,
        product: Product.fromMap(productRows[i]),
      ));
    }
    return items;
  }

  Future<int> itemCount(int sessionId) async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM Inventory_Items WHERE session_id = ?',
      [sessionId],
    );
    return result.first['c'] as int;
  }

  /// Decreases an item's quantity by one. Removes the row entirely when the
  /// quantity would drop to zero.
  Future<void> decrementItem(int sessionId, int productId) async {
    final db = await _database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'Inventory_Items',
        columns: ['id', 'quantity'],
        where: 'session_id = ? AND product_id = ?',
        whereArgs: [sessionId, productId],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final id = rows.first['id'] as int;
      final qty = rows.first['quantity'] as int;
      if (qty <= 1) {
        await txn.delete('Inventory_Items', where: 'id = ?', whereArgs: [id]);
      } else {
        await txn.rawUpdate(
          'UPDATE Inventory_Items SET quantity = quantity - 1 WHERE id = ?',
          [id],
        );
      }
    });
  }

  /// Removes a product from the session regardless of quantity.
  Future<void> deleteItem(int sessionId, int productId) async {
    final db = await _database;
    await db.delete(
      'Inventory_Items',
      where: 'session_id = ? AND product_id = ?',
      whereArgs: [sessionId, productId],
    );
  }

  Future<void> updateProduct(Product product) async {
    final db = await _database;
    if (product.id == null) return;
    final values = Map<String, Object?>.from(product.toMap())..remove('id');
    await db.update(
      'Products',
      values,
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }
}
