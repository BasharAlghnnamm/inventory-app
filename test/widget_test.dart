import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_app/main.dart';

void main() {
  testWidgets('App boots and shows home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: InventoryApp()));
    await tester.pump();

    // The home screen AppBar and FAB render immediately.
    expect(find.text('Inventory Sessions'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
