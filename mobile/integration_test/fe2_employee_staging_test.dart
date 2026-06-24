import 'package:aurelia_mobile/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = String.fromEnvironment('QA_EMPLOYEE_EMAIL');
  const password = String.fromEnvironment('QA_EMPLOYEE_PASSWORD');
  const runStaging = bool.fromEnvironment('QA_RUN_STAGING_FE2');

  testWidgets('FE2 employee self-service routes pass against staging',
      (tester) async {
    if (!runStaging || email.isEmpty || password.isEmpty) {
      return;
    }

    await tester.pumpWidget(const ProviderScope(child: AureliaApp()));

    await _pumpUntilAny(
        tester,
        [
          find.text('Email'),
          find.text('Dashboard'),
        ],
        timeout: const Duration(seconds: 35));

    if (find.text('Email').evaluate().isNotEmpty) {
      await _enterField(tester, 'Email', email);
      await _enterField(tester, 'Password', password);
      await tester.tap(find.text('Sign in'));
    }

    await _pumpUntil(tester, find.text('Dashboard'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilNoLoading(tester, timeout: const Duration(seconds: 35));
    _expectHealthyPage();

    await _goBottom(tester, 'Time', 'Attendance');
    await _goBottom(tester, 'Leave', 'Leave');
    await _trySubmitLeave(tester);

    await _goBottom(tester, 'OKRs', 'OKRs');
    await _tryUpdateOkr(tester);
    await _tryApproveOkr(tester);

    await _goBottom(tester, 'Home', 'Dashboard');
    await _tapText(tester, 'My shifts');
    await _pumpUntil(tester, find.text('My shifts'));
    _expectHealthyPage();

    await _goBottom(tester, 'Home', 'Dashboard');
    await _tapText(tester, 'Reviews');
    await _pumpUntil(tester, find.text('Reviews'));
    _expectHealthyPage();

    await _goBottom(tester, 'Home', 'Dashboard');
    await _tapText(tester, 'Notifications');
    await _pumpUntil(tester, find.text('Notifications'));
    _expectHealthyPage();
    await _tryMarkNotificationRead(tester);

    await _goBottom(tester, 'Home', 'Dashboard');
    await _tapText(tester, 'Attendance history');
    await _pumpUntil(tester, find.text('Attendance'));
    _expectHealthyPage();
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

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await _pumpUntil(tester, finder);
  await tester.ensureVisible(finder.last);
  await tester.pumpAndSettle();
  await tester.tap(finder.last, warnIfMissed: false);
  await tester.pump();
}

Future<void> _goBottom(
  WidgetTester tester,
  String label,
  String expectedTitle,
) async {
  await _tapText(tester, label);
  await _pumpUntil(tester, find.text(expectedTitle),
      timeout: const Duration(seconds: 25));
  await _pumpUntilNoLoading(tester, timeout: const Duration(seconds: 35));
  _expectHealthyPage();
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

Future<void> _trySubmitLeave(WidgetTester tester) async {
  final requestButton =
      find.byKey(const ValueKey('employee.leave.requestButton'));
  if (requestButton.evaluate().isEmpty) {
    debugPrint('FE2_QA_LEAVE_SKIPPED: no leave entitlement request button');
    return;
  }
  final button = tester.widget<ButtonStyleButton>(requestButton.first);
  if (button.onPressed == null) {
    debugPrint('FE2_QA_LEAVE_SKIPPED: leave request disabled');
    return;
  }

  button.onPressed!();
  await tester.pump();
  await _pumpUntil(tester, find.text('Request leave'));

  final stamp = DateTime.now().millisecondsSinceEpoch;
  final year = DateTime.now().toUtc().year;
  final day = 1 + stamp.remainder(20);
  final date = '$year-12-${day.toString().padLeft(2, '0')}';

  await _enterField(tester, 'Start date', date);
  await _enterField(tester, 'End date', date);
  await _enterField(tester, 'Reason', 'FE2 staging QA leave request');
  await _pressButtonKey(tester, 'employee.leave.submit');
  await _pumpUntil(tester, find.text('Leave request submitted.'),
      timeout: const Duration(seconds: 35));
}

Future<void> _tryUpdateOkr(WidgetTester tester) async {
  final button = _buttonKeyPrefix('employee.okr.progress.');
  if (button.evaluate().isEmpty) {
    debugPrint('FE2_QA_OKR_PROGRESS_SKIPPED: no OKR available');
    return;
  }

  await _tapFinder(tester, button.first);
  await _pumpUntil(tester, find.text('Update progress'));
  await _enterField(tester, 'Progress percent', '100');
  await _enterField(tester, 'Progress note', 'FE2 staging QA progress');
  await _pressButtonKey(tester, 'employee.okr.submitProgress');
  await _pumpUntil(tester, find.text('Progress updated.'),
      timeout: const Duration(seconds: 35));
  await _pumpUntilNoLoading(tester, timeout: const Duration(seconds: 35));
}

Future<void> _tryApproveOkr(WidgetTester tester) async {
  await _pumpUntilNoLoading(tester, timeout: const Duration(seconds: 35));
  final buttons = _buttonKeyPrefix('employee.okr.approve.');
  if (buttons.evaluate().isEmpty) {
    debugPrint('FE2_QA_OKR_APPROVAL_SKIPPED: no OKR available');
    return;
  }

  final enabled = _firstEnabledButton(tester, buttons);
  if (enabled == null) {
    debugPrint('FE2_QA_OKR_APPROVAL_SKIPPED: OKR already employee-approved');
    return;
  }

  final button = tester.widget<ButtonStyleButton>(enabled);
  button.onPressed!();
  await tester.pump();
  await _pumpUntil(tester, find.text('Approve OKR'));
  await _enterPlainField(tester, 'Comment', 'FE2 staging QA approval');
  await _pressButtonKey(tester, 'employee.okr.submitApproval');
  await _pumpUntil(tester, find.text('OKR approved.'),
      timeout: const Duration(seconds: 35));
}

Future<void> _tryMarkNotificationRead(WidgetTester tester) async {
  final markAll = find.byKey(const ValueKey('notifications.markAllRead'));
  await _pumpUntilAny(
      tester,
      [
        markAll,
        find.text('No notifications'),
      ],
      timeout: const Duration(seconds: 35));
  if (markAll.evaluate().isNotEmpty) {
    final button = tester.widget<ButtonStyleButton>(markAll.first);
    if (button.onPressed != null) {
      button.onPressed!();
      await tester.pump();
      await _pumpUntil(
          tester, find.textContaining('notifications marked read.'),
          timeout: const Duration(seconds: 35));
      return;
    }
  }

  final button = _buttonKeyPrefix('notifications.markRead.');
  if (button.evaluate().isEmpty) {
    debugPrint('FE2_QA_NOTIFICATION_SKIPPED: no unread notification');
    return;
  }
  await _tapFinder(tester, button.first);
  await _pumpUntil(tester, find.text('Notification marked read.'),
      timeout: const Duration(seconds: 35));
}

Finder _buttonKeyPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey && key.value.toString().startsWith(prefix);
  });
}

Finder? _firstEnabledButton(WidgetTester tester, Finder finder) {
  for (final element in finder.evaluate()) {
    final widget = element.widget;
    if (widget is ButtonStyleButton && widget.onPressed != null) {
      return find.byWidget(widget);
    }
  }
  return null;
}

Future<void> _tapFinder(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder, warnIfMissed: false);
  await tester.pump();
}

Future<void> _pressButtonKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await _pumpUntil(tester, finder);
  final button = tester.widget<ButtonStyleButton>(finder.first);
  if (button.onPressed == null) {
    throw TestFailure('Button $key is disabled');
  }
  button.onPressed!();
  await tester.pump();
}

Future<void> _enterPlainField(
  WidgetTester tester,
  String label,
  String value,
) async {
  final field = find.ancestor(
    of: find.text(label),
    matching: find.byType(TextField),
  );
  await _pumpUntil(tester, field);
  await tester.enterText(field.first, value);
  await tester.pump();
}

void _expectHealthyPage() {
  expect(find.text('Not found'), findsNothing);
  expect(find.text('Access denied'), findsNothing);
  expect(find.text('Could not load'), findsNothing);
  expect(find.text('Connection problem'), findsNothing);
}
