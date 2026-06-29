import 'package:aurelia_mobile/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const adminEmail = String.fromEnvironment('QA_COMPANY_ADMIN_EMAIL');
  const adminPassword = String.fromEnvironment('QA_COMPANY_ADMIN_PASSWORD');
  const employeeEmail = String.fromEnvironment('QA_EMPLOYEE_EMAIL');
  const runStaging = bool.fromEnvironment('QA_RUN_STAGING_FE5E');

  testWidgets('FE5E admin review operations pass against staging',
      (tester) async {
    if (!runStaging ||
        adminEmail.isEmpty ||
        adminPassword.isEmpty ||
        employeeEmail.isEmpty) {
      return;
    }

    final stamp = DateTime.now().millisecondsSinceEpoch.remainder(100000000);
    final cycleName = 'FE5E Cycle $stamp';
    final startDate = _stagingDate(stamp);
    final endDate = _stagingDate(stamp + 31);
    final summary = 'FE5E staging review summary $stamp';
    final editedSummary = 'FE5E staging review summary edited $stamp';

    await tester.pumpWidget(const ProviderScope(child: AureliaApp()));

    final startup = await _pumpUntilAny(
      tester,
      {
        'login': find.text('Email'),
        'admin': find.text('Admin setup'),
      },
      timeout: const Duration(seconds: 60),
    );
    if (startup == 'login') {
      await _enterField(tester, 'Email', adminEmail);
      await _enterField(tester, 'Password', adminPassword);
      await tester.tap(find.text('Sign in'));

      await _pumpUntil(tester, find.text('Admin setup'),
          timeout: const Duration(seconds: 35));
    }

    await _scrollTapKey(tester, 'admin.hub./admin/reviews');
    await _pumpUntil(tester, find.text('Reviews'),
        timeout: const Duration(seconds: 35));

    await _tapKey(tester, 'admin.reviewCycle.create');
    await _pumpUntil(tester, find.text('New review cycle'));
    await _enterFieldByKey(tester, 'admin.reviewCycle.name', cycleName);
    await _enterFieldByKey(tester, 'admin.reviewCycle.startDate', startDate);
    await _enterFieldByKey(tester, 'admin.reviewCycle.endDate', endDate);
    await _scrollPressButtonKey(tester, 'admin.reviewCycle.save');
    await _pumpUntil(tester, find.text('Review cycle saved.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Save review cycle'),
        timeout: const Duration(seconds: 10));
    await _pumpUntil(tester, find.text(cycleName),
        timeout: const Duration(seconds: 35));

    await _scrollTapKey(tester, 'admin.reviewCycle.changeStatus.$cycleName');
    await _pumpUntil(tester, find.text('Change cycle status'));
    await _selectDropdownOption(tester, 'admin.reviewCycle.status', 'ACTIVE');
    await _pressButtonKey(tester, 'admin.reviewCycle.statusSave');
    await _pumpUntil(tester, find.text('Review cycle status updated.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Save status'),
        timeout: const Duration(seconds: 10));
    await _pumpUntil(tester, find.text('ACTIVE'),
        timeout: const Duration(seconds: 35));

    await _tapKey(tester, 'admin.reviews.tab.reviews');
    await _pumpUntil(tester, find.text('Submit review'));
    await _tapKey(tester, 'admin.review.create');
    await _pumpUntil(tester, find.text('Submit review'));
    await _enterFieldByKey(
        tester, 'admin.review.employee.search', employeeEmail);
    await _tapTextContaining(tester, employeeEmail);
    await _enterFieldByKey(tester, 'admin.review.cycle.search', cycleName);
    await _tapTextContaining(tester, cycleName);
    await _enterFieldByKey(tester, 'admin.review.summary', summary);
    await _enterFieldByKey(tester, 'admin.review.rating', '4');
    await _scrollPressButtonKey(tester, 'admin.review.save');
    await _pumpUntil(tester, find.text('Performance review saved.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Save review'),
        timeout: const Duration(seconds: 10));
    await _pumpUntil(tester, find.text(cycleName),
        timeout: const Duration(seconds: 35));

    await _scrollTapKey(tester, 'admin.review.edit.$cycleName');
    await _pumpUntil(tester, find.text('Edit review'));
    await _enterFieldByKey(tester, 'admin.review.summary', editedSummary);
    await _scrollPressButtonKey(tester, 'admin.review.save');
    await _pumpUntil(tester, find.text('Performance review saved.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Save review'),
        timeout: const Duration(seconds: 10));
    await _pumpUntil(tester, find.textContaining(editedSummary),
        timeout: const Duration(seconds: 35));

    await _scrollTapKey(tester, 'admin.review.changeStatus.$cycleName');
    await _pumpUntil(tester, find.text('Change status'));
    await _selectDropdownOption(tester, 'admin.review.status', 'ACKNOWLEDGED');
    await _pressButtonKey(tester, 'admin.review.statusSave');
    await _pumpUntil(tester, find.text('Performance review status updated.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Save status'),
        timeout: const Duration(seconds: 10));
    await _pumpUntil(tester, find.text('ACKNOWLEDGED'),
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

Future<String> _pumpUntilAny(
  WidgetTester tester,
  Map<String, Finder> finders, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    for (final entry in finders.entries) {
      if (entry.value.evaluate().isNotEmpty) return entry.key;
    }
  }
  throw TestFailure('Timed out waiting for any of ${finders.keys}');
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

Future<void> _enterFieldByKey(
  WidgetTester tester,
  String key,
  String value,
) async {
  final finder = find.byKey(ValueKey(key));
  final end = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder.first);
      await _boundedPump(tester);
      final editable = find.descendant(
        of: finder.first,
        matching: find.byType(EditableText),
      );
      await _pumpUntil(tester, editable);
      await tester.enterText(editable.first, value);
      await tester.pump();
      return;
    }
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -260));
  }
  throw TestFailure('Timed out scrolling for $finder');
}

Future<void> _tapTextContaining(WidgetTester tester, String text) async {
  await _tapFinder(tester, find.textContaining(text).last);
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await _tapFinder(tester, find.byKey(ValueKey(key)));
}

Future<void> _scrollTapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  final end = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) {
      await _tapFinder(tester, finder);
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

Future<void> _selectDropdownOption(
  WidgetTester tester,
  String key,
  String optionText,
) async {
  final dropdown = find.byKey(ValueKey(key));
  await _pumpUntil(tester, dropdown);
  await tester.tap(dropdown.first, warnIfMissed: false);
  await tester.pumpAndSettle();
  final option = find.text(optionText);
  await _pumpUntil(tester, option);
  await tester.tap(option.last, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _pressButtonKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await _pumpUntil(tester, finder);
  await tester.ensureVisible(finder.last);
  await _boundedPump(tester);
  final resolved = find.byKey(ValueKey(key));
  await _pumpUntil(tester, resolved);
  final widget = tester.widget(resolved.last);
  if (widget is ButtonStyleButton && widget.onPressed != null) {
    widget.onPressed!();
  } else {
    await tester.tap(resolved.last, warnIfMissed: false);
  }
  await tester.pump();
}

Future<void> _scrollPressButtonKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  final end = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) {
      await _pressButtonKey(tester, key);
      return;
    }
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -260));
  }
  throw TestFailure('Timed out scrolling for $finder');
}

Future<void> _boundedPump(WidgetTester tester) async {
  for (var i = 0; i < 8; i += 1) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

String _stagingDate(int stamp) {
  final offset = stamp.remainder(240);
  final date = DateTime.utc(2099).add(Duration(days: offset));
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
