import 'dart:typed_data';

import 'package:excel/excel.dart' as exc;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/inventory/column_render.dart';
import '../../features/inventory/inventory_item.dart';
import '../../features/inventory/inventory_session.dart';
import '../../features/inventory/session_config.dart';
import '../../l10n/generated/app_localizations.dart';

/// Generates Excel and PDF exports / print jobs for an inventory session
/// honoring the session's dynamic column configuration.
///
/// Layout (both formats):
///   Row 1: Total Cost: [V] | Total Sales: [V]
///   Row 2: (empty)
///   Row 3: table headers
///   Row 4+: data rows
class ExportService {
  pw.Font? _arNormal;
  pw.Font? _arBold;

  Future<pw.Font> _font() async =>
      _arNormal ??= pw.Font.ttf(
        await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
      );

  Future<pw.Font> _boldFont() async =>
      _arBold ??= pw.Font.ttf(
        await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
      );

  /// Builds an Excel `.xlsx` byte array.
  Future<Uint8List> buildExcelBytes(
    InventorySession session,
    SessionConfig config,
    List<InventoryItem> items,
    AppLocalizations l10n,
  ) async {
    final totalCost = _sumCost(items);
    final totalSales = _sumSales(items);
    final excel = exc.Excel.createExcel();
    final sheet = excel['Report'];

    // Row 1: totals (0-indexed row 0).
    sheet.appendRow([
      exc.TextCellValue('${l10n.totalCost}: ${totalCost.toStringAsFixed(2)}'),
      exc.TextCellValue(
          '${l10n.totalSales}: ${totalSales.toStringAsFixed(2)}'),
    ]);
    for (final i in [0, 1]) {
      sheet
          .cell(exc.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .cellStyle = exc.CellStyle(bold: true);
    }

    // Row 2: blank.
    sheet.appendRow([exc.TextCellValue('')]);

    // Row 3: headers.
    final headers = _headerLabels(config, l10n);
    sheet.appendRow(headers.map((h) => exc.TextCellValue(h)).toList());
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(exc.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2))
          .cellStyle = exc.CellStyle(bold: true);
    }

    // Row 4+: data.
    for (final item in items) {
      sheet.appendRow(_rowValues(config, item, l10n));
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Builds a printable PDF document using the bundled Cairo font (renders
  /// Arabic correctly).
  Future<Uint8List> buildPdfBytes(
    InventorySession session,
    SessionConfig config,
    List<InventoryItem> items,
    AppLocalizations l10n,
  ) async {
    final normal = await _font();
    final bold = await _boldFont();
    final totalCost = _sumCost(items);
    final totalSales = _sumSales(items);

    final doc = pw.Document(title: l10n.inventoryReport);

    final data = <List<String>>[];
    for (final item in items) {
      final row = <String>[];
      for (final r in renderColumns(config, item, l10n)) {
        row.add(r.text);
      }
      row.add('${item.quantity}');
      if (config.showCost) row.add(item.subtotalCost.toStringAsFixed(2));
      if (config.showSelling) row.add(item.subtotalSales.toStringAsFixed(2));
      data.add(row);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(base: normal, bold: bold),
        header: (context) => pw.Center(
          child: pw.Text(
            l10n.inventoryReport,
            style: pw.TextStyle(font: bold, fontSize: 18),
          ),
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${l10n.totalCost}: ${totalCost.toStringAsFixed(2)}',
                style: pw.TextStyle(font: bold, fontSize: 13),
              ),
              pw.Text(
                '${l10n.totalSales}: ${totalSales.toStringAsFixed(2)}',
                style: pw.TextStyle(font: bold, fontSize: 13),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: _headerLabels(config, l10n),
            data: data,
            headerDecoration:
                pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E88E5)),
            headerStyle: pw.TextStyle(
              color: PdfColor.fromInt(0xFFFFFFFF),
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: pw.TextStyle(fontSize: 9),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFCCCCCC)),
          ),
        ],
      ),
    );
    return doc.save();
  }

  List<String> _headerLabels(SessionConfig config, AppLocalizations l10n) {
    final labels = <String>[];
    for (final key in config.orderedKeys) {
      labels.add(_columnLabel(key, config, l10n));
    }
    labels.add(l10n.quantity);
    if (config.showCost) labels.add(l10n.subtotalCost);
    if (config.showSelling) labels.add(l10n.subtotalSales);
    return labels;
  }

  List<exc.TextCellValue> _rowValues(
    SessionConfig config,
    InventoryItem item,
    AppLocalizations l10n,
  ) {
    final cells = <String>[];
    for (final r in renderColumns(config, item, l10n)) {
      cells.add(r.text);
    }
    cells.add('${item.quantity}');
    if (config.showCost) cells.add(item.subtotalCost.toStringAsFixed(2));
    if (config.showSelling) cells.add(item.subtotalSales.toStringAsFixed(2));
    return cells.map((c) => exc.TextCellValue(c)).toList();
  }

  String _columnLabel(ColumnKey key, SessionConfig config, AppLocalizations l10n) {
    if (key.name.startsWith('custom')) {
      return config.labelFor(key);
    }
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
      case ColumnKey.productId:
        return '';
      default:
        return '';
    }
  }
}

double _sumCost(List<InventoryItem> items) =>
    items.fold(0, (s, i) => s + i.subtotalCost);

double _sumSales(List<InventoryItem> items) =>
    items.fold(0, (s, i) => s + i.subtotalSales);
