import 'package:aurelia_mobile/app.dart';
import 'package:aurelia_mobile/core/config/app_flavor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('renders the Aurelia app shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AureliaApp()));
    await tester.pump();

    expect(find.text('Loading...'), findsOneWidget);
  });

  testWidgets('uses the provided flavor app title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flavorConfigProvider.overrideWithValue(employeeFlavorConfig),
        ],
        child: const AureliaApp(),
      ),
    );
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'Aurelia Employee');
  });
}
