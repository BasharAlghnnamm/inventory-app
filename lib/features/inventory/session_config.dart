import 'dart:convert';

/// Identity of a configurable inventory column.
enum ColumnKey {
  productId('productId'),
  name('name'),
  image('image'),
  barcode('barcode'),
  sellingPrice('sellingPrice'),
  costPrice('costPrice'),
  batchNo('batchNo'),
  note('note'),
  expirationDate('expirationDate'),
  color('color'),
  custom1('custom1'),
  custom2('custom2'),
  custom3('custom3'),
  custom4('custom4'),
  custom5('custom5');

  const ColumnKey(this.value);
  final String value;

  static ColumnKey? fromValue(String v) =>
      values.firstWhereOrNull((k) => k.value == v);
}

/// Parses / serializes the `column_config` JSON of an inventory session.
///
/// Product name and barcode are always active. The database primary key
/// [ColumnKey.productId] is never part of the display config — it exists only
/// for SQL tracking. At most [ColumnKey.values.length] columns may be
/// displayed. Custom fields (`custom1`..`custom5`) carry a user-provided
/// label; an empty label means the custom field is hidden.
class SessionConfig {
  SessionConfig({
    this.active = const {ColumnKey.name, ColumnKey.barcode},
    this.customLabels = const ['', '', '', '', ''],
  })  : assert(customLabels.length == 5),
        assert(active.contains(ColumnKey.name)),
        assert(active.contains(ColumnKey.barcode));

  final Set<ColumnKey> active;

  /// User-renamed labels for custom1..custom5. Empty string hides the field.
  final List<String> customLabels;

  static const int maxCustom = 5;

  bool get showName => active.contains(ColumnKey.name);
  bool get showImage => active.contains(ColumnKey.image);
  bool get showBarcode => active.contains(ColumnKey.barcode);
  bool get showSelling => active.contains(ColumnKey.sellingPrice);
  bool get showCost => active.contains(ColumnKey.costPrice);
  bool get showBatch => active.contains(ColumnKey.batchNo);
  bool get showNote => active.contains(ColumnKey.note);
  bool get showExpiry => active.contains(ColumnKey.expirationDate);
  bool get showColor => active.contains(ColumnKey.color);

  String labelFor(ColumnKey key) {
    final idx = key.index - ColumnKey.custom1.index;
    if (idx < 0 || idx >= maxCustom) return '';
    return customLabels[idx];
  }

  /// Ordered list of columns that should be rendered/exported. Name and barcode
  /// are always included; the SQL-only product id never appears.
  List<ColumnKey> get orderedKeys {
    final keys = <ColumnKey>[];
    void add(ColumnKey k) {
      if (active.contains(k)) keys.add(k);
    }

    add(ColumnKey.name);
    add(ColumnKey.image);
    add(ColumnKey.barcode);
    add(ColumnKey.sellingPrice);
    add(ColumnKey.costPrice);
    add(ColumnKey.batchNo);
    add(ColumnKey.note);
    add(ColumnKey.expirationDate);
    add(ColumnKey.color);
    for (var i = 0; i < maxCustom; i++) {
      final k = ColumnKey.values[ColumnKey.custom1.index + i];
      if (active.contains(k) && customLabels[i].isNotEmpty) keys.add(k);
    }
    return keys;
  }

  /// Max number of concurrently selectable columns (UI performance cap).
  static const int maxActive = 10;

  Map<String, dynamic> toJson() => {
        'active': active.map((k) => k.value).toList(),
        'customLabels': List<String>.unmodifiable(customLabels),
      };

  String encode() => jsonEncode(toJson());

  factory SessionConfig.decode(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final activeList = (map['active'] as List)
          .map((e) => ColumnKey.fromValue(e as String))
          .whereType<ColumnKey>()
          .toSet()
        ..remove(ColumnKey.productId)
        ..addAll({ColumnKey.name, ColumnKey.barcode});
      final labels = (map['customLabels'] as List? ?? [])
          .map((e) => e as String)
          .toList();
      while (labels.length < maxCustom) {
        labels.add('');
      }
      return SessionConfig(
        active: Set<ColumnKey>.from(activeList),
        customLabels: labels.sublist(0, maxCustom),
      );
    } catch (_) {
      return SessionConfig();
    }
  }

  factory SessionConfig.empty() => SessionConfig();

  SessionConfig copyWith({
    Set<ColumnKey>? active,
    List<String>? customLabels,
  }) {
    return SessionConfig(
      active: active ?? this.active,
      customLabels: customLabels ?? this.customLabels,
    );
  }
}

extension _FirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
