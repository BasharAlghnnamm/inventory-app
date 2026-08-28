import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/utils/image_store.dart';
import '../inventory/state.dart';
import 'product.dart';

/// Handles registering a new product and adding it to the active session.
final productsControllerProvider =
    Provider<ProductsController>((ref) => ProductsController(ref));

class ProductsController {
  ProductsController(this._ref);

  final Ref _ref;

  /// Persists an image inline (data URI) if provided, stores the new product,
  /// then adds one unit to the active session. Returns the new product id.
  Future<int> register(
    Product product, {
    Uint8List? imageBytes,
    String? extension,
  }) async {
    final repo = _ref.read(repositoryProvider);
    final sessionId = _ref.read(activeSessionIdProvider);

    String? imagePath = product.imagePath;
    if (imageBytes != null) {
      imagePath = ImageStore.encode(imageBytes, extension: extension);
    }

    final id = await repo.insertProduct(
      Product(
        id: null,
        barcode: product.barcode,
        name: product.name,
        imagePath: imagePath,
        costPrice: product.costPrice,
        sellingPrice: product.sellingPrice,
        batchNo: product.batchNo,
        note: product.note,
        expirationDate: product.expirationDate,
        color: product.color,
        customs: product.customs,
      ),
    );

    if (sessionId != null) {
      await repo.addItem(sessionId, id);
      _ref.invalidate(activeItemsProvider);
    }

    _ref.read(pendingBarcodeProvider.notifier).clear();
    return id;
  }

  /// Persists changes to an existing product (e.g. adding an image later).
  Future<void> update(Product product) async {
    final repo = _ref.read(repositoryProvider);
    await repo.updateProduct(product);
    _ref.invalidate(activeItemsProvider);
  }
}
