import 'package:aurelia_mobile/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('renders the Aurelia app shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AureliaApp()));
    await tester.pump();

    expect(find.text('Loading...'), findsOneWidget);
  });
}
