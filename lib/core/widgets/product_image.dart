import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../utils/image_store.dart';
import '../utils/legacy_image_loader.dart';

/// Renders a stored product image, whether it is a `data:` URI (current
/// storage) or a plain file path (rows written by older desktop builds).
class ProductImage extends StatefulWidget {
  const ProductImage({super.key, required this.value, this.fit = BoxFit.cover});

  final String value;
  final BoxFit fit;

  @override
  State<ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<ProductImage> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant ProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _resolve();
  }

  Future<void> _resolve() async {
    final value = widget.value;
    final bytes = ImageStore.isDataUri(value)
        ? ImageStore.decode(value)
        : await loadLegacyImage(value);
    if (mounted) setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) {
      return const Icon(Icons.image_not_supported);
    }
    return Image.memory(
      bytes,
      fit: widget.fit,
      errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
    );
  }
}