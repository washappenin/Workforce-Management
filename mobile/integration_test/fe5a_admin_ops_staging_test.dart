import 'package:aurelia_mobile/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = String.fromEnvironment('QA_COMPANY_ADMIN_EMAIL');
  const password = String.fromEnvironment('QA_COMPANY_ADMIN_PASSWORD');
  const runStaging = bool.fromEnvironment('QA_RUN_STAGING_FE5A');

  testWidgets('FE5A admin geofences and attendance pass against staging',
      (tester) async {
    if (!runStaging || email.isEmpty || password.isEmpty) {
      return;
    }

    final stamp = DateTime.now().millisecondsSinceEpoch.remainder(100000000);
    final name = 'FE5A Geofence $stamp';
    final editedName = 'FE5A Geofence Edited $stamp';

    await tester.pumpWidget(const ProviderScope(child: AureliaApp()));

    await _pumpUntil(tester, find.text('Email'));
    await _enterField(tester, 'Email', email);
    await _enterField(tester, 'Password', password);
    await tester.tap(find.text('Sign in'));

    await _pumpUntil(tester, find.text('Admin setup'),
        timeout: const Duration(seconds: 35));

    await tester.tap(find.text('Geo'));
    await _pumpUntil(tester, find.text('Geofences'),
        timeout: const Duration(seconds: 35));

    await _tapKey(tester, 'admin.geofence.create');
    await _pumpUntil(tester, find.text('New geofence'));
    await _enterField(tester, 'Name', name);
    await _enterField(tester, 'Latitude', '9.0301');
    await _enterField(tester, 'Longitude', '38.7400');
    await _enterField(tester, 'Radius meters', '200');
    await _pressButtonKey(tester, 'admin.geofence.save');
    await _pumpUntil(tester, find.text('Geofence saved.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Save geofence'),
        timeout: const Duration(seconds: 10));
    await _pumpUntil(tester, find.text(name),
        timeout: const Duration(seconds: 35));

    await tester.tap(find.text(name).first);
    await _pumpUntil(tester, find.text('Edit geofence'),
        timeout: const Duration(seconds: 35));

    await _tapKey(tester, 'admin.geofence.edit');
    await _pumpUntil(tester, find.text('Edit geofence'));
    await _enterField(tester, 'Name', editedName);
    await _enterField(tester, 'Radius meters', '250');
    await _pressButtonKey(tester, 'admin.geofence.save');
    await _pumpUntil(tester, find.text('Geofence saved.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Save geofence'),
        timeout: const Duration(seconds: 10));
    await _pumpUntil(tester, find.text(editedName),
        timeout: const Duration(seconds: 35));
    await _pumpUntil(tester, find.text('250 m'),
        timeout: const Duration(seconds: 35));

    await _tapKey(tester, 'admin.geofence.toggleStatus');
    await _pumpUntil(tester, find.text('Deactivate geofence?'));
    await tester.tap(find.text('Deactivate').last);
    await _pumpUntil(tester, find.text('Geofence status updated.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntil(tester, find.text('INACTIVE'),
        timeout: const Duration(seconds: 35));

    await tester.tap(find.text('Time'));
    await _pumpUntil(tester, find.text('Attendance'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilAny(
      tester,
      [find.textContaining('Session '), find.text('No attendance records')],
      timeout: const Duration(seconds: 35),
    );
  });
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _pumpUntilAny(
  WidgetTester tester,
  List<Finder> finders, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    for (final finder in finders) {
      if (finder.evaluate().isNotEmpty) return;
    }
  }
  throw TestFailure('Timed out waiting for any finder');
}

Future<void> _pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder to disappear');
}

Future<void> _enterField(
  WidgetTester tester,
  String label,
  String value,
) async {
  final field = find.ancestor(
    of: find.text(label),
    matching: find.byType(TextFormField),
  );
  await _pumpUntil(tester, field);
  await tester.ensureVisible(field.first);
  await _boundedPump(tester);
  await tester.enterText(field.first, value);
  await tester.pump();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await _pumpUntil(tester, finder);
  await tester.ensureVisible(finder.first);
  await _boundedPump(tester);
  await tester.tap(finder.first, warnIfMissed: false);
  await tester.pump();
}

Future<void> _pressButtonKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await _pumpUntil(tester, finder);
  await tester.ensureVisible(finder.first);
  await _boundedPump(tester);
  final button = tester.widget<ButtonStyleButton>(finder.first);
  if (button.onPressed == null) {
    throw TestFailure('Button $key is disabled');
  }
  button.onPressed!();
  await tester.pump();
}

Future<void> _boundedPump(WidgetTester tester) async {
  for (var i = 0; i < 8; i += 1) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}
