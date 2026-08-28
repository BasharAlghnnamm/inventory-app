import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../inventory/state.dart';

/// State result of a single scan attempt.
enum ScanResult {
  /// Product exists and quantity incremented.
  added,

  /// Product not found; caller should open the "New Product" flow.
  unknown,
}

/// Buffers raw hardware-keyboard input and parses it into a full barcode when
/// the `Enter` (carriage return) key is pressed. USB scanners behave exactly
/// like a keyboard, so this needs no special driver.
class ScannerNotifier extends AsyncNotifier<ScanResult?> {
  final StringBuffer _buffer = StringBuffer();
  Timer? _flushTimer;
  static const _idleTimeout = Duration(milliseconds: 300);

  /// True while a modal (e.g. New Product sheet) is open; keyboard input is
  /// ignored so typing into the modal cannot trigger more scans.
  bool _paused = false;
  bool get paused => _paused;

  @override
  Future<ScanResult?> build() async => null;

  /// Pauses/resumes barcode capture. Call while a modal consumes keyboard
  /// input and resume when it closes.
  void setPaused(bool value) => _paused = value;

  /// Registers the global keyboard listener. Call exactly once per page.
  void bind() {
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  void unbind() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _flushTimer?.cancel();
  }

  /// Clears the last scan result (used after handling an unknown barcode).
  void resetResult() {
    state = const AsyncData(null);
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (_paused) return false;

    final key = event.logicalKey;
    // Restart idle debounce on every keystroke.
    _flushTimer?.cancel();
    _flushTimer = Timer(_idleTimeout, _flushStale);

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _handleComplete();
      return true;
    }

    // Only accept printable text.
    final text = event.character;
    if (text != null && text.isNotEmpty) {
      _buffer.write(text);
    }
    return true;
  }

  void _handleComplete() {
    _flushTimer?.cancel();
    final code = _buffer.toString().trim();
    _buffer.clear();
    if (code.isEmpty) return;
    _process(code);
  }

  void _flushStale() {
    if (_buffer.length == 0) return;
    final code = _buffer.toString().trim();
    _buffer.clear();
    if (code.isNotEmpty) _process(code);
  }

  Future<void> _process(String code) async {
    if (_paused) return;
    final repo = ref.read(repositoryProvider);
    final sessionId = ref.read(activeSessionIdProvider);
    if (sessionId == null) {
      state = const AsyncData(null);
      return;
    }

    final product = await repo.getProductByBarcode(code);
    if (product == null) {
      state = AsyncData(ScanResult.unknown);
      // Keep the raw barcode accessible for the registration modal.
      ref.read(pendingBarcodeProvider.notifier).set(code);
      return;
    }

    if (product.id != null) {
      await repo.addItem(sessionId, product.id!);
    }
    // Refresh the active session item list.
    ref.invalidate(activeItemsProvider);
    state = const AsyncData(ScanResult.added);
  }
}
