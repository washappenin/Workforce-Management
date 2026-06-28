import 'package:aurelia_mobile/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = String.fromEnvironment('QA_COMPANY_ADMIN_EMAIL');
  const password = String.fromEnvironment('QA_COMPANY_ADMIN_PASSWORD');
  const runStaging = bool.fromEnvironment('QA_RUN_STAGING_FE5B');

  testWidgets('FE5B admin shifts and assignments pass against staging',
      (tester) async {
    if (!runStaging || email.isEmpty || password.isEmpty) {
      return;
    }

    final stamp = DateTime.now().millisecondsSinceEpoch.remainder(100000000);
    final name = 'FE5B Shift $stamp';
    final editedName = 'FE5B Shift Edited $stamp';
    final startsOn = _todayDate();
    final endsOn = _offsetDate(days: 7);

    await tester.pumpWidget(const ProviderScope(child: AureliaApp()));

    await _pumpUntil(tester, find.text('Email'));
    await _enterField(tester, 'Email', email);
    await _enterField(tester, 'Password', password);
    await tester.tap(find.text('Sign in'));

    await _pumpUntil(tester, find.text('Admin setup'),
        timeout: const Duration(seconds: 35));

    await _scrollTapKey(tester, 'admin.hub./admin/shifts');
    await _pumpUntil(tester, find.text('Shifts'),
        timeout: const Duration(seconds: 35));

    await _tapKey(tester, 'admin.shift.create');
    await _pumpUntil(tester, find.text('New shift'));
    await _enterField(tester, 'Name', name);
    await _enterField(tester, 'Start time', '09:15');
    await _enterField(tester, 'End time', '17:45');
    await _pressButtonKey(tester, 'admin.shift.save');
    await _pumpUntil(tester, find.text('Shift saved.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Save shift'),
        timeout: const Duration(seconds: 10));
    await _pumpUntil(tester, find.text(name),
        timeout: const Duration(seconds: 35));

    await tester.tap(find.text(name).first);
    await _pumpUntil(tester, find.text('Edit shift'),
        timeout: const Duration(seconds: 35));

    await _tapKey(tester, 'admin.shift.edit');
    await _pumpUntil(tester, find.text('Edit shift'));
    await _enterField(tester, 'Name', editedName);
    await _enterField(tester, 'Start time', '08:30');
    await _enterField(tester, 'End time', '16:30');
    await _pressButtonKey(tester, 'admin.shift.save');
    await _pumpUntil(tester, find.text('Shift saved.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Save shift'),
        timeout: const Duration(seconds: 10));
    await _pumpUntil(tester, find.text(editedName),
        timeout: const Duration(seconds: 35));
    await _pumpUntil(tester, find.text('08:30'),
        timeout: const Duration(seconds: 35));

    await _tapKey(tester, 'admin.shift.assign');
    await _pumpUntil(tester, find.text('Assign employee'));
    await _selectFirstDropdownOption(tester, 'admin.shiftAssignment.employee');
    await _enterField(tester, 'Starts on', startsOn);
    await _pressButtonKey(tester, 'admin.shiftAssignment.save');
    await _pumpUntil(tester, find.text('Shift assigned.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Save assignment'),
        timeout: const Duration(seconds: 10));
    await _scrollUntil(tester, find.text(startsOn),
        timeout: const Duration(seconds: 35));

    await _scrollTapFinder(tester, find.byTooltip('Edit assignment'));
    await _pumpUntil(tester, find.text('Edit assignment'));
    await _enterField(tester, 'Ends on optional', endsOn);
    await _pressButtonKey(tester, 'admin.shiftAssignment.save');
    await _pumpUntil(tester, find.text('Assignment saved.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Save assignment'),
        timeout: const Duration(seconds: 10));
    await _scrollUntil(tester, find.text(endsOn),
        timeout: const Duration(seconds: 35));

    await _scrollTapFinder(tester, find.byTooltip('Remove assignment'));
    await _pumpUntil(tester, find.text('Remove assignment?'));
    await tester.tap(find.text('Remove').last);
    await _pumpUntil(tester, find.text('Assignment removed.'),
        timeout: const Duration(seconds: 35));
    await _scrollUntil(tester, find.text('No employees assigned'),
        timeout: const Duration(seconds: 35));

    await _scrollToTop(tester);
    await _tapKey(tester, 'admin.shift.toggleStatus');
    await _pumpUntil(tester, find.text('Deactivate shift?'));
    await tester.tap(find.text('Deactivate').last);
    await _pumpUntil(tester, find.text('Shift status updated.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntil(tester, find.text('INACTIVE'),
        timeout: const Duration(seconds: 35));
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

Future<void> _selectFirstDropdownOption(
  WidgetTester tester,
  String key,
) async {
  final dropdown = find.byKey(ValueKey(key));
  await _pumpUntil(tester, dropdown);
  await tester.ensureVisible(dropdown.first);
  await _boundedPump(tester);
  await tester.tap(dropdown.first, warnIfMissed: false);
  await tester.pumpAndSettle();
  final option = find.descendant(
    of: find.byType(DropdownMenuItem<String>),
    matching: find.textContaining('@'),
  );
  await _pumpUntil(tester, option);
  await tester.tap(option.first, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await _tapFinder(tester, find.byKey(ValueKey(key)));
}

Future<void> _scrollTapKey(WidgetTester tester, String key) async {
  await _scrollTapFinder(tester, find.byKey(ValueKey(key)));
}

Future<void> _scrollTapFinder(WidgetTester tester, Finder finder) async {
  await _scrollUntil(tester, finder);
  await _tapFinder(tester, finder);
}

Future<void> _scrollUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -260));
  }
  throw TestFailure('Timed out scrolling for $finder');
}

Future<void> _tapFinder(WidgetTester tester, Finder finder) async {
  await _pumpUntil(tester, finder);
  await tester.ensureVisible(finder.first);
  await _boundedPump(tester);
  await tester.tap(finder.first, warnIfMissed: false);
  await tester.pump();
}

Future<void> _scrollToTop(WidgetTester tester) async {
  for (var i = 0; i < 8; i += 1) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 320));
    await tester.pump(const Duration(milliseconds: 150));
  }
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

String _todayDate() {
  final now = DateTime.now();
  return _date(now);
}

String _offsetDate({required int days}) {
  return _date(DateTime.now().add(Duration(days: days)));
}

String _date(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
