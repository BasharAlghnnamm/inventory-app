/// A registered product known to the system.
class Product {
  const Product({
    this.id,
    required this.barcode,
    required this.name,
    this.imagePath,
    this.costPrice,
    this.sellingPrice,
    this.batchNo,
    this.note,
    this.expirationDate,
    this.color,
    this.customs = const ['', '', '', '', ''],
  }) : assert(customs.length == 5);

  final int? id;
  final String barcode;
  final String name;
  final String? imagePath;
  final double? costPrice;
  final double? sellingPrice;
  final String? batchNo;
  final String? note;
  final String? expirationDate;
  final String? color;

  /// Values for custom1..custom5.
  final List<String> customs;

  factory Product.fromMap(Map<String, Object?> map) => Product(
        id: map['id'] as int?,
        barcode: map['barcode'] as String,
        name: map['name'] as String,
        imagePath: map['image_path'] as String?,
        costPrice: (map['cost_price'] as num?)?.toDouble(),
        sellingPrice: (map['selling_price'] as num?)?.toDouble(),
        batchNo: map['batch_no'] as String?,
        note: map['note'] as String?,
        expirationDate: map['expiration_date'] as String?,
        color: map['color'] as String?,
        customs: [
          map['other_1'] as String? ?? '',
          map['other_2'] as String? ?? '',
          map['other_3'] as String? ?? '',
          map['other_4'] as String? ?? '',
          map['other_5'] as String? ?? '',
        ],
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'barcode': barcode,
        'name': name,
        'image_path': imagePath,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'batch_no': batchNo,
        'note': note,
        'expiration_date': expirationDate,
        'color': color,
        'other_1': customs[0],
        'other_2': customs[1],
        'other_3': customs[2],
        'other_4': customs[3],
        'other_5': customs[4],
      };
}
