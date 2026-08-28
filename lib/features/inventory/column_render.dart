import '../../l10n/generated/app_localizations.dart';
import 'inventory_item.dart';
import 'session_config.dart';

/// A resolved value for one configured column.
class ColumnRender {
  const ColumnRender({
    required this.key,
    required this.label,
    required this.text,
    this.isImage = false,
  });

  final ColumnKey key;
  final String label;
  final String text;
  final bool isImage;
}

/// Builds the ordered list of column renders for an item, honoring the
/// session config. Quantity and the computed subtotals are appended last
/// (quantity is implied by the workflow; subtotals summarize cost/selling).
List<ColumnRender> renderColumns(
  SessionConfig config,
  InventoryItem item,
  AppLocalizations l10n,
) {
  final out = <ColumnRender>[];
  for (final key in config.orderedKeys) {
    switch (key) {
      case ColumnKey.productId:
        break;
      case ColumnKey.name:
        out.add(ColumnRender(
          key: key,
          label: l10n.productName,
          text: item.product.name,
        ));
      case ColumnKey.image:
        out.add(ColumnRender(
          key: key,
          label: l10n.image,
          text: item.product.imagePath ?? '',
          isImage: item.product.imagePath != null,
        ));
      case ColumnKey.barcode:
        out.add(ColumnRender(
          key: key,
          label: l10n.barcode,
          text: item.product.barcode,
        ));
      case ColumnKey.sellingPrice:
        out.add(ColumnRender(
          key: key,
          label: l10n.sellingPrice,
          text: _fmt(item.product.sellingPrice),
        ));
      case ColumnKey.costPrice:
        out.add(ColumnRender(
          key: key,
          label: l10n.costPrice,
          text: _fmt(item.product.costPrice),
        ));
      case ColumnKey.batchNo:
        out.add(ColumnRender(
          key: key,
          label: l10n.batchNo,
          text: item.product.batchNo ?? '',
        ));
      case ColumnKey.note:
        out.add(ColumnRender(
          key: key,
          label: l10n.note,
          text: item.product.note ?? '',
        ));
      case ColumnKey.expirationDate:
        out.add(ColumnRender(
          key: key,
          label: l10n.expirationDate,
          text: item.product.expirationDate ?? '',
        ));
      case ColumnKey.color:
        out.add(ColumnRender(
          key: key,
          label: l10n.color,
          text: item.product.color ?? '',
        ));
      case ColumnKey.custom1:
      case ColumnKey.custom2:
      case ColumnKey.custom3:
      case ColumnKey.custom4:
      case ColumnKey.custom5:
        final idx = key.index - ColumnKey.custom1.index;
        out.add(ColumnRender(
          key: key,
          label: config.customLabels[idx],
          text: item.product.customs[idx],
        ));
    }
  }
  return out;
}

/// Quantity column, always present.
ColumnRender quantityRender(AppLocalizations l10n, InventoryItem item) {
  return ColumnRender(
    key: ColumnKey.productId,
    label: l10n.quantity,
    text: item.quantity.toString(),
  );
}

ColumnRender subtotalCostRender(AppLocalizations l10n, InventoryItem item) {
  return ColumnRender(
    key: ColumnKey.costPrice,
    label: l10n.subtotalCost,
    text: item.subtotalCost.toStringAsFixed(2),
  );
}

ColumnRender subtotalSalesRender(AppLocalizations l10n, InventoryItem item) {
  return ColumnRender(
    key: ColumnKey.sellingPrice,
    label: l10n.subtotalSales,
    text: item.subtotalSales.toStringAsFixed(2),
  );
}

String _fmt(double? v) => v == null ? '' : v.toStringAsFixed(2);
