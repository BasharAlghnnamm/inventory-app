import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/save_file.dart';
import '../../core/widgets/product_image.dart';

import '../../core/utils/export_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../products/new_product_sheet.dart';
import '../scanner/scanner_notifier.dart';
import 'column_config_sheet.dart';
import 'inventory_item.dart';
import 'inventory_session.dart';
import 'session_config.dart';
import 'state.dart';

enum _RowAction { decrease, edit, delete }

class MainInventoryScreen extends ConsumerStatefulWidget {
  const MainInventoryScreen({super.key});

  @override
  ConsumerState<MainInventoryScreen> createState() =>
      _MainInventoryScreenState();
}

class _MainInventoryScreenState extends ConsumerState<MainInventoryScreen> {
  final ExportService _exports = ExportService();
  bool _busy = false;

  ScannerNotifier? _scanner;

  @override
  void initState() {
    super.initState();
    _scanner = ref.read(scannerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanner?.bind();
    });
  }

  @override
  void dispose() {
    _scanner?.unbind();
    super.dispose();
  }

  double get _totalCost {
    final items = ref.read(activeItemsProvider).value ?? [];
    return items.fold(0, (s, i) => s + i.subtotalCost);
  }

  double get _totalSales {
    final items = ref.read(activeItemsProvider).value ?? [];
    return items.fold(0, (s, i) => s + i.subtotalSales);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final itemsAsync = ref.watch(activeItemsProvider);
    final config = ref.watch(activeConfigProvider);

    ref.listen(scannerProvider, (prev, next) {
      if (next is AsyncData<ScanResult?> &&
          next.value == ScanResult.unknown &&
          !ref.read(scannerProvider.notifier).paused) {
        ref.read(scannerProvider.notifier).resetResult();
        ProductSheet.show(context);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_session?.name ?? l10n.inventoryReport),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(activeSessionIdProvider.notifier).close();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            tooltip: l10n.configureColumns,
            onPressed: _busy ? null : () => _configureColumns(context),
            icon: const Icon(Icons.view_column_outlined),
          ),
          IconButton(
            tooltip: l10n.delete,
            onPressed: _busy ? null : () => _deleteSession(context),
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: l10n.exportExcel,
            onPressed: _busy ? null : () => _exportExcel(context),
            icon: const Icon(Icons.table_chart),
          ),
          IconButton(
            tooltip: l10n.exportPdf,
            onPressed: _busy ? null : () => _exportPdf(context),
            icon: const Icon(Icons.picture_as_pdf),
          ),
          IconButton(
            tooltip: l10n.printReport,
            onPressed: _busy ? null : () => _print(context),
            icon: const Icon(Icons.print),
          ),
        ],
      ),
      body: Column(
        children: [
          _TotalsBar(
            l10n: l10n,
            totalCost: _totalCost,
            totalSales: _totalSales,
          ),
          const Divider(height: 1),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code_scanner, size: 64),
                        const SizedBox(height: 12),
                        Text(l10n.continueScanning,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
                return _DataTable(
                  items: items,
                  config: config,
                  l10n: l10n,
                  onDecrease: (item) => _decreaseItem(item),
                  onEdit: (item) => _editItem(context, item),
                  onDelete: (item) => _removeItem(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  InventorySession? get _session {
    final sessionId = ref.read(activeSessionIdProvider);
    final sessions = ref.read(sessionsProvider).value ?? [];
    for (final s in sessions) {
      if (s.id == sessionId) return s;
    }
    return null;
  }

  Future<void> _decreaseItem(InventoryItem item) async {
    final sessionId = ref.read(activeSessionIdProvider);
    if (sessionId == null) return;
    await ref
        .read(activeItemsProvider.notifier)
        .decrease(sessionId, item.productId);
  }

  Future<void> _editItem(BuildContext context, InventoryItem item) async {
    await ProductSheet.show(context, existing: item.product);
  }

  Future<void> _removeItem(BuildContext context, InventoryItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final sessionId = ref.read(activeSessionIdProvider);
    if (sessionId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteItemTitle),
        content: Text(l10n.deleteItemMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(activeItemsProvider.notifier)
          .remove(sessionId, item.productId);
    }
  }

  Future<void> _configureColumns(BuildContext context) async {
    final session = _session;
    if (session == null) return;

    final config = await showColumnConfig(context, session.config);
    if (config == null || !context.mounted) return;

    await ref.read(sessionsProvider.notifier).updateConfig(session.id, config);
  }

  Future<void> _deleteSession(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final session = _session;
    if (session == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSessionTitle),
        content: Text(l10n.deleteSessionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    ref.read(activeSessionIdProvider.notifier).close();
    Navigator.pop(context);
    await ref.read(sessionsProvider.notifier).delete(session.id);
  }

  Future<void> _exportExcel(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.read(activeItemsProvider).value ?? [];
    final session = _session;
    if (session == null || items.isEmpty) return;

    setState(() => _busy = true);
    try {
      final bytes = await _exports.buildExcelBytes(
        session,
        session.config,
        items,
        l10n,
      );
      await _saveFile('${session.name}.xlsx', bytes, 'xlsx');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.excelExported)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.read(activeItemsProvider).value ?? [];
    final session = _session;
    if (session == null || items.isEmpty) return;

    setState(() => _busy = true);
    try {
      final bytes = await _exports.buildPdfBytes(
        session,
        session.config,
        items,
        l10n,
      );
      await _saveFile('${session.name}.pdf', bytes, 'pdf');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.pdfExported)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.read(activeItemsProvider).value ?? [];
    final session = _session;
    if (session == null || items.isEmpty) return;

    setState(() => _busy = true);
    try {
      final bytes = await _exports.buildPdfBytes(
        session,
        session.config,
        items,
        l10n,
      );
      await _saveFile('${session.name}_report', bytes, 'pdf');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.pdfExported)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveFile(
    String name,
    Uint8List bytes,
    String ext,
  ) {
    return saveFileDialog('$name.$ext', bytes, ext);
  }
}

class _TotalsBar extends StatelessWidget {
  const _TotalsBar({
    required this.l10n,
    required this.totalCost,
    required this.totalSales,
  });

  final AppLocalizations l10n;
  final double totalCost;
  final double totalSales;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Total(
            label: l10n.totalCost,
            value: totalCost,
            onPrimaryContainer: scheme.onPrimaryContainer,
          ),
          _Total(
            label: l10n.totalSales,
            value: totalSales,
            onPrimaryContainer: scheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.value,
    required this.onPrimaryContainer,
  });

  final String label;
  final double value;
  final Color onPrimaryContainer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _DataTable extends StatelessWidget {
  const _DataTable({
    required this.items,
    required this.config,
    required this.l10n,
    required this.onDecrease,
    required this.onEdit,
    required this.onDelete,
  });

  final List<InventoryItem> items;
  final SessionConfig config;
  final AppLocalizations l10n;
  final void Function(InventoryItem) onDecrease;
  final void Function(InventoryItem) onEdit;
  final void Function(InventoryItem) onDelete;

  @override
  Widget build(BuildContext context) {
    final headers = <String>[];
    final cols = <ColumnKey>[];
    for (final key in config.orderedKeys) {
      final label = config.labelFor(key).isNotEmpty &&
              key.name.startsWith('custom')
          ? config.labelFor(key)
          : _labelFor(key, l10n);
      headers.add(label);
      cols.add(key);
    }
    // Quantity + subtotals always appended.
    headers.add(l10n.quantity);
    if (config.showCost) headers.add(l10n.subtotalCost);
    if (config.showSelling) headers.add(l10n.subtotalSales);
    headers.add(l10n.actions);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
        rows: items.map<DataRow>((item) {
          final cells = <DataCell>[];
          for (final key in cols) {
            if (key == ColumnKey.image && item.product.imagePath != null) {
              cells.add(_imageCell(item.product.imagePath!));
            } else {
              cells.add(DataCell(Text(_valueFor(key, item))));
            }
          }
          cells.add(DataCell(Text('${item.quantity}')));
          if (config.showCost) {
            cells.add(DataCell(Text(item.subtotalCost.toStringAsFixed(2))));
          }
          if (config.showSelling) {
            cells.add(DataCell(Text(item.subtotalSales.toStringAsFixed(2))));
          }
          cells.add(DataCell(_actionsCell(item)));
          return DataRow(cells: cells);
        }).toList(),
      ),
    );
  }

  Widget _actionsCell(InventoryItem item) {
    return PopupMenuButton<_RowAction>(
      tooltip: l10n.actions,
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case _RowAction.decrease:
            onDecrease(item);
          case _RowAction.edit:
            onEdit(item);
          case _RowAction.delete:
            onDelete(item);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _RowAction.decrease,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.remove_circle_outline),
            title: Text(l10n.decrease),
          ),
        ),
        PopupMenuItem(
          value: _RowAction.edit,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit),
            title: Text(l10n.edit),
          ),
        ),
        PopupMenuItem(
          value: _RowAction.delete,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete,
                color: Theme.of(context).colorScheme.error),
            title: Text(l10n.delete,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ),
      ],
    );
  }

  DataCell _imageCell(String path) {
    return DataCell(
      SizedBox(
        width: 48,
        height: 48,
        child: path.isEmpty
            ? const Icon(Icons.image_not_supported)
            : ProductImage(value: path),
      ),
    );
  }

  String _valueFor(ColumnKey key, InventoryItem item) {
    switch (key) {
      case ColumnKey.name:
        return item.product.name;
      case ColumnKey.image:
        return '';
      case ColumnKey.barcode:
        return item.product.barcode;
      case ColumnKey.sellingPrice:
        return _fmt(item.product.sellingPrice);
      case ColumnKey.costPrice:
        return _fmt(item.product.costPrice);
      case ColumnKey.batchNo:
        return item.product.batchNo ?? '';
      case ColumnKey.note:
        return item.product.note ?? '';
      case ColumnKey.expirationDate:
        return item.product.expirationDate ?? '';
      case ColumnKey.color:
        return item.product.color ?? '';
      case ColumnKey.custom1:
      case ColumnKey.custom2:
      case ColumnKey.custom3:
      case ColumnKey.custom4:
      case ColumnKey.custom5:
        return item.product
            .customs[key.index - ColumnKey.custom1.index];
      case ColumnKey.productId:
        return '';
    }
  }

  String _labelFor(ColumnKey key, AppLocalizations l10n) {
    switch (key) {
      case ColumnKey.name:
        return l10n.productName;
      case ColumnKey.image:
        return l10n.image;
      case ColumnKey.barcode:
        return l10n.barcode;
      case ColumnKey.sellingPrice:
        return l10n.sellingPrice;
      case ColumnKey.costPrice:
        return l10n.costPrice;
      case ColumnKey.batchNo:
        return l10n.batchNo;
      case ColumnKey.note:
        return l10n.note;
      case ColumnKey.expirationDate:
        return l10n.expirationDate;
      case ColumnKey.color:
        return l10n.color;
      default:
        return '';
    }
  }
}

String _fmt(double? v) => v == null ? '' : v.toStringAsFixed(2);
