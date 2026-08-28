import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/utils/image_store.dart';
import '../../core/widgets/product_image.dart';
import '../../l10n/generated/app_localizations.dart';
import '../inventory/session_config.dart';
import '../inventory/state.dart';
import '../scanner/scanner_notifier.dart';
import 'product.dart';
import 'products_controller.dart';

/// Modal for registering a new product (from a scanned unknown barcode) or
/// editing an existing one ([existing] != null). Renders only the fields
/// enabled by the active session's column configuration.
class ProductSheet extends ConsumerStatefulWidget {
  const ProductSheet({super.key, this.existing});

  final Product? existing;

  static Future<void> show(BuildContext context, {Product? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ProductSheet(existing: existing),
    );
  }

  @override
  ConsumerState<ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends ConsumerState<ProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _barcode = TextEditingController();
  final _cost = TextEditingController();
  final _selling = TextEditingController();
  final _batch = TextEditingController();
  final _note = TextEditingController();
  final _expiry = TextEditingController();
  final _color = TextEditingController();
  final _customs = List.generate(5, (_) => TextEditingController());

  /// Current image to display: a `data:` URI for fresh picks or an existing
  /// stored value (data URI or legacy file path).
  String? _imageValue;

  /// Bytes of a freshly picked image, sent to the controller on save.
  Uint8List? _pickedBytes;
  String? _pickedExt;

  // Captured in initState: "ref" is unusable after dispose.
  late final ScannerNotifier _scanner;
  Product? get _existing => widget.existing;

  @override
  void initState() {
    super.initState();
    final existing = _existing;
    if (existing == null) {
      final barcode = ref.read(pendingBarcodeProvider) ?? '';
      _barcode.text = barcode;
    } else {
      _barcode.text = existing.barcode;
      _name.text = existing.name;
      _cost.text = existing.costPrice?.toString() ?? '';
      _selling.text = existing.sellingPrice?.toString() ?? '';
      _batch.text = existing.batchNo ?? '';
      _note.text = existing.note ?? '';
      _expiry.text = existing.expirationDate ?? '';
      _color.text = existing.color ?? '';
      for (var i = 0; i < 5; i++) {
        _customs[i].text = existing.customs[i];
      }
      if (existing.imagePath != null) {
        _imageValue = existing.imagePath;
      }
    }
    // Stop the global scanner from reacting to keyboard input while this
    // modal is open; resume when it closes.
    _scanner = ref.read(scannerProvider.notifier);
    _scanner.setPaused(true);
  }

  @override
  void dispose() {
    _scanner.setPaused(false);
    _name.dispose();
    _barcode.dispose();
    _cost.dispose();
    _selling.dispose();
    _batch.dispose();
    _note.dispose();
    _expiry.dispose();
    _color.dispose();
    for (final c in _customs) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    const typeGroup =
        XTypeGroup(label: 'images', extensions: ['png', 'jpg', 'jpeg']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = p.extension(file.name).replaceFirst('.', '');
    setState(() {
      _pickedBytes = bytes;
      _pickedExt = ext;
      _imageValue = ImageStore.encode(bytes, extension: ext);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final config = ref.read(activeConfigProvider);
    final existing = _existing;

    if (existing == null) {
      // Register copies the picked image itself.
      final product = Product(
        barcode: _barcode.text.trim(),
        name: _name.text.trim(),
        costPrice: config.showCost ? _parseDouble(_cost.text) : null,
        sellingPrice: config.showSelling ? _parseDouble(_selling.text) : null,
        batchNo: config.showBatch ? _batch.text.trim() : null,
        note: config.showNote ? _note.text.trim() : null,
        expirationDate: config.showExpiry ? _expiry.text.trim() : null,
        color: config.showColor ? _color.text.trim() : null,
        customs: _customValues(config),
      );
      await ref.read(productsControllerProvider).register(
            product,
            imageBytes: _pickedBytes,
            extension: _pickedExt,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.productAdded)),
      );
      return;
    }

    // Edit: copy a newly picked image; keep the stored value otherwise.
    String? imagePath = existing.imagePath;
    if (_pickedBytes != null) {
      imagePath = ImageStore.encode(_pickedBytes!, extension: _pickedExt);
    }
    final product = Product(
      id: existing.id,
      barcode: _barcode.text.trim(),
      name: _name.text.trim(),
      imagePath: imagePath,
      costPrice: config.showCost ? _parseDouble(_cost.text) : null,
      sellingPrice: config.showSelling ? _parseDouble(_selling.text) : null,
      batchNo: config.showBatch ? _batch.text.trim() : null,
      note: config.showNote ? _note.text.trim() : null,
      expirationDate: config.showExpiry ? _expiry.text.trim() : null,
      color: config.showColor ? _color.text.trim() : null,
      customs: _customValues(config),
    );
    await ref.read(productsControllerProvider).update(product);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.productUpdated)),
    );
  }

  List<String> _customValues(SessionConfig config) => [
        for (var i = 0; i < 5; i++)
          if (config.active
                  .contains(ColumnKey.values[ColumnKey.custom1.index + i]) &&
              config.customLabels[i].isNotEmpty)
            _customs[i].text.trim()
          else
            '',
      ];

  double? _parseDouble(String s) {
    final v = double.tryParse(s);
    return (v == null || s.isEmpty) ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(activeConfigProvider);
    final name = _name;
    final isEdit = _existing != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? l10n.editProduct : l10n.registerProduct,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (config.showImage) ...[
                _ImageField(
                  value: _imageValue,
                  label: l10n.image,
                  onPick: _pickImage,
                ),
                const SizedBox(height: 12),
              ],
              if (config.showBarcode)
                TextFormField(
                  controller: _barcode,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: l10n.barcode,
                    prefixIcon: const Icon(Icons.qr_code),
                  ),
                ),
              if (config.showBarcode) const SizedBox(height: 12),
              if (config.showName) ...[
                TextFormField(
                  controller: name,
                  decoration: InputDecoration(labelText: l10n.productName),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.required : null,
                ),
                const SizedBox(height: 12),
              ],
              if (config.showSelling) ...[
                _numField(
                  l10n.sellingPrice,
                  _selling,
                  l10n,
                  icon: Icons.sell,
                ),
                const SizedBox(height: 12),
              ],
              if (config.showCost) ...[
                _numField(l10n.costPrice, _cost, l10n,
                    icon: Icons.payments),
                const SizedBox(height: 12),
              ],
              if (config.showBatch) ...[
                TextFormField(
                  controller: _batch,
                  decoration: InputDecoration(labelText: l10n.batchNo),
                ),
                const SizedBox(height: 12),
              ],
              if (config.showNote) ...[
                TextFormField(
                  controller: _note,
                  decoration:
                      InputDecoration(labelText: l10n.note),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
              ],
              if (config.showExpiry) ...[
                TextFormField(
                  controller: _expiry,
                  decoration:
                      InputDecoration(labelText: l10n.expirationDate),
                  onTap: () => _pickDate(context),
                ),
                const SizedBox(height: 12),
              ],
              if (config.showColor) ...[
                TextFormField(
                  controller: _color,
                  decoration: InputDecoration(labelText: l10n.color),
                ),
                const SizedBox(height: 12),
              ],
              for (var i = 0; i < SessionConfig.maxCustom; i++)
                if (config.active.contains(
                        ColumnKey.values[ColumnKey.custom1.index + i]) &&
                    config.customLabels[i].isNotEmpty) ...[
                  TextFormField(
                    controller: _customs[i],
                    decoration: InputDecoration(
                      labelText: config.customLabels[i],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numField(
    String label,
    TextEditingController c,
    AppLocalizations l10n, {
    required IconData icon,
  }) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: (v) {
        if (v == null || v.isEmpty) return null;
        return double.tryParse(v) == null ? l10n.invalidNumber : null;
      },
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _expiry.text =
            '${picked.year.toString().padLeft(4, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }
}

class _ImageField extends StatelessWidget {
  const _ImageField({
    required this.value,
    required this.label,
    required this.onPick,
  });

  final String? value;
  final String label;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        InkWell(
          onTap: onPick,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: value == null
                ? Center(
                    child: Icon(
                      Icons.add_photo_alternate,
                      size: 32,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                : ProductImage(value: value!, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }
}