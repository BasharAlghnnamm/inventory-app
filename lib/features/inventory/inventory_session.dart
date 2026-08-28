import 'session_config.dart';

/// An inventory counting session.
class InventorySession {
  const InventorySession({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.config,
  });

  final int id;
  final String name;
  final DateTime createdAt;
  final SessionConfig config;

  factory InventorySession.fromMap(Map<String, Object?> map) => InventorySession(
        id: map['id'] as int,
        name: map['name'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        config: SessionConfig.decode(
          (map['column_config'] as String?) ?? '',
        ),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
        'column_config': config.encode(),
      };
}
