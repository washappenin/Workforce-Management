import 'package:aurelia_mobile/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = String.fromEnvironment('QA_COMPANY_ADMIN_EMAIL');
  const password = String.fromEnvironment('QA_COMPANY_ADMIN_PASSWORD');
  const runStaging = bool.fromEnvironment('QA_RUN_STAGING_FE4');

  testWidgets('FE4 admin employee workflow passes against staging',
      (tester) async {
    if (!runStaging || email.isEmpty || password.isEmpty) {
      return;
    }

    final stamp = DateTime.now().millisecondsSinceEpoch.remainder(100000000);
    const firstName = 'FE4';
    final lastName = 'Ui$stamp';
    const editedFirstName = 'FE4Edit';
    final editedLastName = 'Ui$stamp';
    final employeeCode = 'FE4UI$stamp';
    final editedCode = 'FE4UE$stamp';
    final employeeEmail = 'fe4ui$stamp@example.test';
    const temporaryPassword = 'Password123456789';

    await tester.pumpWidget(const ProviderScope(child: AureliaApp()));

    await _pumpUntil(tester, find.text('Email'));
    await _enterField(tester, 'Email', email);
    await _enterField(tester, 'Password', password);
    await tester.tap(find.text('Sign in'));

    await _pumpUntil(tester, find.text('Admin setup'),
        timeout: const Duration(seconds: 35));

    await tester.tap(find.text('People'));
    await _pumpUntil(tester, find.text('Employees'));

    await _tapKey(tester, 'admin.newEmployee');
    await _pumpUntil(tester, find.text('New employee'));

    await _enterField(tester, 'Email', employeeEmail);
    await _enterField(tester, 'Temporary password', temporaryPassword);
    await _enterField(tester, 'First name', firstName);
    await _enterField(tester, 'Last name', lastName);
    await _enterField(tester, 'Employee code', employeeCode);
    await _enterField(tester, 'Phone optional', '555010$stamp');
    await _tapKey(tester, 'admin.employeeForm.save');

    await _pumpUntil(tester, find.text('Employee saved.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntil(tester, find.textContaining(employeeCode),
        timeout: const Duration(seconds: 35));

    await tester.tap(find.textContaining(employeeCode).first);
    await _pumpUntil(tester, find.text('Edit profile'));

    await _tapKey(tester, 'admin.employeeDetail.editProfile');
    await _pumpUntil(tester, find.text('Edit employee'));
    await _enterField(tester, 'First name', editedFirstName);
    await _enterField(tester, 'Last name', editedLastName);
    await _enterField(tester, 'Employee code', editedCode);
    await _tapKey(tester, 'admin.employeeForm.save');
    await _pumpUntil(tester, find.text('Employee saved.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Edit employee'),
        timeout: const Duration(seconds: 10));
    await _pumpUntil(tester, find.text(editedCode),
        timeout: const Duration(seconds: 35));
    await _pumpUntil(tester, find.text('Edit profile'),
        timeout: const Duration(seconds: 35));

    await _tapKey(tester, 'admin.employeeDetail.changeStatus');
    await _pumpUntil(tester, find.text('Save status'));
    await _selectDropdownValue(
      tester,
      'ON_LEAVE',
      dropdownKey: 'admin.employeeStatus.dropdown',
    );
    await _pressButtonKey(tester, 'admin.employeeStatus.save');
    await _pumpUntil(tester, find.text('Employee status updated.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntil(tester, find.text('ON_LEAVE'),
        timeout: const Duration(seconds: 35));

    await _tapKey(tester, 'admin.employeeDetail.assignManager');
    await _pumpUntil(tester, find.text('Save manager'));
    await _selectDropdownValue(
      tester,
      'Staging Manager',
      dropdownKey: 'admin.employeeManager.dropdown',
    );
    await _pressButtonKey(tester, 'admin.employeeManager.save');
    await _pumpUntil(tester, find.text('Manager assignment updated.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntil(tester, find.text('Staging Manager'),
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
  await tester.enterText(field.first, value);
  await tester.pump();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await _pumpUntil(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first, warnIfMissed: false);
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

Future<void> _selectDropdownValue(
  WidgetTester tester,
  String value, {
  String? dropdownKey,
}) async {
  final dropdown = dropdownKey == null
      ? find.byWidgetPredicate(
          (widget) =>
              widget is DropdownButtonFormField<String> ||
              widget is DropdownButtonFormField<String?>,
        )
      : find.byKey(ValueKey(dropdownKey));
  await _pumpUntil(tester, dropdown);
  await tester.tap(dropdown.last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}
