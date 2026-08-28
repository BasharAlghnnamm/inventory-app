import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'session_config.dart';

/// Modal for choosing which columns a new session tracks. Returns the final
/// [SessionConfig] or null if cancelled.
Future<SessionConfig?> showColumnConfig(
  BuildContext context,
  SessionConfig initial,
) {
  return showDialog<SessionConfig>(
    context: context,
    builder: (_) => _ColumnConfigDialog(initial: initial),
  );
}

class _ColumnConfigDialog extends StatefulWidget {
  const _ColumnConfigDialog({required this.initial});

  final SessionConfig initial;

  @override
  State<_ColumnConfigDialog> createState() => _ColumnConfigDialogState();
}

class _ColumnConfigDialogState extends State<_ColumnConfigDialog> {
  late SessionConfig _cfg = widget.initial;
  late final List<TextEditingController> _customControllers = List.generate(
    SessionConfig.maxCustom,
    (i) => TextEditingController(text: widget.initial.customLabels[i]),
  );

  @override
  void dispose() {
    for (final c in _customControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggle(ColumnKey key, bool value) {
    setState(() {
      final active = Set<ColumnKey>.from(_cfg.active);
      if (value) {
        if (!active.contains(key)) {
          if ((active.length >= SessionConfig.maxActive) && _countCustoms(active) == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maximum of 10 columns reached.')),
            );
            return;
          }
          active.add(key);
        }
      } else {
        active.remove(key);
      }
      _cfg = _cfg.copyWith(active: active);
    });
  }

  int _countCustoms(Set<ColumnKey> active) =>
      active.where((k) => k.name.startsWith('custom')).length;

  void _toggleCustom(int index, bool value) {
    setState(() {
      final active = Set<ColumnKey>.from(_cfg.active);
      final key = ColumnKey.values[ColumnKey.custom1.index + index];
      if (value) {
        if (!active.contains(key)) {
          if (active.length >= SessionConfig.maxActive) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maximum of 10 columns reached.')),
            );
            return;
          }
          active.add(key);
        }
      } else {
        active.remove(key);
      }
      _cfg = _cfg.copyWith(active: active);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.productName,
      l10n.image,
      l10n.barcode,
      l10n.sellingPrice,
      l10n.costPrice,
      l10n.batchNo,
      l10n.note,
      l10n.expirationDate,
      l10n.color,
    ];

    const keys = [
      ColumnKey.name,
      ColumnKey.image,
      ColumnKey.barcode,
      ColumnKey.sellingPrice,
      ColumnKey.costPrice,
      ColumnKey.batchNo,
      ColumnKey.note,
      ColumnKey.expirationDate,
      ColumnKey.color,
    ];

    return AlertDialog(
      title: Text(l10n.configureColumns),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420, maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.configureColumnsHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < keys.length; i++)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _cfg.active.contains(keys[i]),
                  enabled: !(keys[i] == ColumnKey.name ||
                      keys[i] == ColumnKey.barcode),
                  onChanged: keys[i] == ColumnKey.name ||
                          keys[i] == ColumnKey.barcode
                      ? null
                      : (v) => _toggle(keys[i], v ?? false),
                  title: Text(labels[i]),
                ),
              const Divider(),
              Text(l10n.customFields,
                  style: Theme.of(context).textTheme.titleSmall),
              for (var i = 0; i < SessionConfig.maxCustom; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _cfg.active.contains(ColumnKey
                            .values[ColumnKey.custom1.index + i]),
                        onChanged: (v) => _toggleCustom(i, v ?? false),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _customControllers[i],
                          enabled: _cfg.active.contains(ColumnKey
                              .values[ColumnKey.custom1.index + i]),
                          decoration: InputDecoration(
                            labelText:
                                '${l10n.otherField} ${i + 1}',
                            isDense: true,
                          ),
                          onChanged: (v) {
                            final labels = List<String>.from(_cfg.customLabels);
                            labels[i] = v.trim();
                            _cfg = _cfg.copyWith(customLabels: labels);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final labels = List<String>.generate(
              SessionConfig.maxCustom,
              (i) => _customControllers[i].text.trim(),
            );
            Navigator.pop(
              context,
              _cfg.copyWith(customLabels: labels),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
