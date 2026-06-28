import 'package:aurelia_mobile/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = String.fromEnvironment('QA_EMPLOYEE_EMAIL');
  const password = String.fromEnvironment('QA_EMPLOYEE_PASSWORD');
  const runStaging = bool.fromEnvironment('QA_RUN_STAGING_FE3');
  const latitude = String.fromEnvironment('QA_DEVICE_LATITUDE');
  const longitude = String.fromEnvironment('QA_DEVICE_LONGITUDE');

  testWidgets('FE3 face and GPS attendance passes against staging',
      (tester) async {
    if (!runStaging ||
        email.isEmpty ||
        password.isEmpty ||
        latitude.isEmpty ||
        longitude.isEmpty) {
      return;
    }

    _step('boot');
    await tester.pumpWidget(const ProviderScope(child: AureliaApp()));

    await _pumpUntilAny(
        tester,
        [
          find.text('Email'),
          find.text('Dashboard'),
        ],
        timeout: const Duration(seconds: 35));

    if (find.text('Email').evaluate().isNotEmpty) {
      _step('login');
      await _enterField(tester, 'Email', email);
      await _enterField(tester, 'Password', password);
      await tester.tap(find.text('Sign in'));
    }

    _step('dashboard');
    await _pumpUntil(tester, find.text('Dashboard'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilNoLoading(tester, timeout: const Duration(seconds: 35));

    _step('clock-in route');
    _goToRoute(tester, '/employee/attendance/clock-in');
    await _pumpRouteTransition(tester);
    await _pumpUntil(tester, find.text('Clock in'));
    _step('clock-in submit');
    await _tapKey(tester, 'employee.clockIn.submit');
    await _pumpUntil(tester, find.text('Clocked in.'),
        timeout: const Duration(seconds: 60));
    await _pumpUntil(tester, find.text('Attendance recorded'),
        timeout: const Duration(seconds: 20));

    _step('home route');
    _goToRoute(tester, '/employee');
    await _pumpRouteTransition(tester);
    await _pumpUntil(tester, find.text('Dashboard'));
    await _pumpUntilNoLoading(tester, timeout: const Duration(seconds: 35));

    _step('clock-out route');
    _goToRoute(tester, '/employee/attendance/clock-out');
    await _pumpRouteTransition(tester);
    await _pumpUntil(tester, find.text('Clock out'));
    _step('clock-out submit');
    await _tapKey(tester, 'employee.clockOut.submit');
    await _pumpUntil(tester, find.text('Clocked out.'),
        timeout: const Duration(seconds: 60));
    await _pumpUntil(tester, find.text('Attendance recorded'),
        timeout: const Duration(seconds: 20));
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

Future<void> _pumpUntilNoLoading(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.textContaining('Loading').evaluate().isEmpty) return;
  }
  throw TestFailure('Timed out waiting for page loading to finish');
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
  await tester.enterText(field.first, value);
  await tester.pump();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await _pumpUntil(tester, finder);
  await tester.ensureVisible(finder.first);
  await _pumpRouteTransition(tester);
  await tester.tap(finder.first, warnIfMissed: false);
  await tester.pump();
}

Future<void> _pumpRouteTransition(WidgetTester tester) async {
  for (var i = 0; i < 8; i += 1) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void _goToRoute(WidgetTester tester, String route) {
  final context = tester.element(find.byType(Scaffold).last);
  GoRouter.of(context).go(route);
}

void _step(String label) {
  debugPrint('FE3_QA_STEP $label');
}
