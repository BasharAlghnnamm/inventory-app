import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../scanner/scanner_notifier.dart';
import 'inventory_item.dart';
import 'inventory_session.dart';
import 'session_config.dart';

/// List of all inventory sessions.
final sessionsProvider =
    AsyncNotifierProvider<SessionsNotifier, List<InventorySession>>(() {
  return SessionsNotifier();
});

class SessionsNotifier extends AsyncNotifier<List<InventorySession>> {
  @override
  Future<List<InventorySession>> build() {
    return ref.watch(repositoryProvider).getSessions();
  }

  Future<InventorySession> create(String name, SessionConfig config) async {
    final repo = ref.read(repositoryProvider);
    final id = await repo.createSession(name, config);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repo.getSessions());
    final sessions = state.value ?? [];
    return sessions.isNotEmpty
        ? sessions.first
        : InventorySession(
            id: id,
            name: name,
            createdAt: DateTime.now(),
            config: config,
          );
  }

  Future<void> delete(int id) async {
    final repo = ref.read(repositoryProvider);
    await repo.deleteSession(id);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repo.getSessions());
  }

  Future<void> updateConfig(int id, SessionConfig config) async {
    final repo = ref.read(repositoryProvider);
    await repo.updateSessionConfig(id, config);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repo.getSessions());
  }
}

/// The ID of the currently open inventory session (null when on home page).
final activeSessionIdProvider =
    NotifierProvider<ActiveSessionNotifier, int?>(() => ActiveSessionNotifier());

class ActiveSessionNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void open(int id) => state = id;

  void close() => state = null;
}

/// Column configuration of the active session.
final activeConfigProvider = Provider<SessionConfig>((ref) {
  final sessionId = ref.watch(activeSessionIdProvider);
  if (sessionId == null) return SessionConfig.empty();
  final sessions = ref.watch(sessionsProvider).value ?? [];
  for (final s in sessions) {
    if (s.id == sessionId) return s.config;
  }
  return SessionConfig.empty();
});

/// Items of the active session.
final activeItemsProvider =
    AsyncNotifierProvider<ActiveItemsNotifier, List<InventoryItem>>(() {
  return ActiveItemsNotifier();
});

class ActiveItemsNotifier extends AsyncNotifier<List<InventoryItem>> {
  @override
  Future<List<InventoryItem>> build() async {
    final sessionId = ref.watch(activeSessionIdProvider);
    if (sessionId == null) return [];
    return ref.watch(repositoryProvider).getItems(sessionId);
  }

  /// Decreases quantity by one; reloads the list afterwards.
  Future<void> decrease(int sessionId, int productId) async {
    final repo = ref.read(repositoryProvider);
    await repo.decrementItem(sessionId, productId);
    ref.invalidateSelf();
  }

  /// Removes the product from the session; reloads the list afterwards.
  Future<void> remove(int sessionId, int productId) async {
    final repo = ref.read(repositoryProvider);
    await repo.deleteItem(sessionId, productId);
    ref.invalidateSelf();
  }
}

/// Barcode that triggered the unknown-product flow, to prefill the modal.
final pendingBarcodeProvider =
    NotifierProvider<PendingBarcodeNotifier, String?>(() => PendingBarcodeNotifier());

class PendingBarcodeNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;

  void clear() => state = null;
}

/// Scanner state.
final scannerProvider =
    AsyncNotifierProvider<ScannerNotifier, ScanResult?>(() => ScannerNotifier());
