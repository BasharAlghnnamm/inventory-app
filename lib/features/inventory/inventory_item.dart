import '../products/product.dart';

/// A row joining an inventory session item with its product details.
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.sessionId,
    required this.productId,
    required this.quantity,
    required this.product,
  });

  final int id;
  final int sessionId;
  final int productId;
  final int quantity;
  final Product product;

  /// Total cost = cost price * quantity.
  double get subtotalCost => (product.costPrice ?? 0) * quantity;

  /// Total sales = selling price * quantity.
  double get subtotalSales => (product.sellingPrice ?? 0) * quantity;
}
