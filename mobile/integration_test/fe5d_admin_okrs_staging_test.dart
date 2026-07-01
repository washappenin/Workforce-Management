import 'package:aurelia_mobile/app.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://workforce-management-production.up.railway.app',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const adminEmail = String.fromEnvironment('QA_COMPANY_ADMIN_EMAIL');
  const adminPassword = String.fromEnvironment('QA_COMPANY_ADMIN_PASSWORD');
  const employeeEmail = String.fromEnvironment('QA_EMPLOYEE_EMAIL');
  const employeePassword = String.fromEnvironment('QA_EMPLOYEE_PASSWORD');
  const runStaging = bool.fromEnvironment('QA_RUN_STAGING_FE5D');

  testWidgets('FE5D admin OKR operations pass against staging', (tester) async {
    if (!runStaging ||
        adminEmail.isEmpty ||
        adminPassword.isEmpty ||
        employeeEmail.isEmpty ||
        employeePassword.isEmpty) {
      return;
    }

    final stamp = DateTime.now().millisecondsSinceEpoch.remainder(100000000);
    final title = 'FE5D OKR $stamp';
    final editedTitle = 'FE5D OKR Edited $stamp';
    final dueDate = _stagingDate(stamp);

    await tester.pumpWidget(const ProviderScope(child: AureliaApp()));

    await _pumpUntil(tester, find.text('Email'));
    await _enterField(tester, 'Email', adminEmail);
    await _enterField(tester, 'Password', adminPassword);
    await tester.tap(find.text('Sign in'));

    await _pumpUntil(tester, find.text('Admin setup'),
        timeout: const Duration(seconds: 35));

    await _scrollTapKey(tester, 'admin.hub./admin/okrs');
    await _pumpUntil(tester, find.text('OKRs'),
        timeout: const Duration(seconds: 35));

    await _tapKey(tester, 'admin.okr.create');
    await _pumpUntil(tester, find.text('New OKR'));
    await _enterField(tester, 'Employee search', employeeEmail);
    await _tapTextContaining(tester, employeeEmail);
    await _enterField(tester, 'Title', title);
    await _enterField(tester, 'Description optional', 'FE5D staging OKR');
    await _enterField(tester, 'Due date optional', dueDate);
    await _scrollPressButtonKey(tester, 'admin.okr.save');
    await _pumpUntil(tester, find.text('OKR saved.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Save OKR'),
        timeout: const Duration(seconds: 10));
    await _pumpUntil(tester, find.text(title),
        timeout: const Duration(seconds: 35));

    await tester.tap(find.text(title).first);
    await _pumpUntil(tester, find.text('Edit OKR'),
        timeout: const Duration(seconds: 35));

    await _tapKey(tester, 'admin.okr.edit');
    await _pumpUntil(tester, find.text('Edit OKR'));
    await _enterField(tester, 'Title', editedTitle);
    await _enterField(
        tester, 'Description optional', 'FE5D staging OKR edited');
    await _scrollPressButtonKey(tester, 'admin.okr.save');
    await _pumpUntil(tester, find.text('OKR saved.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Save OKR'),
        timeout: const Duration(seconds: 10));
    await _pumpUntil(tester, find.text(editedTitle),
        timeout: const Duration(seconds: 35));

    await _tapKey(tester, 'admin.okr.changeStatus');
    await _pumpUntil(tester, find.text('Change status'));
    await _selectDropdownOption(tester, 'admin.okr.status', 'IN_PROGRESS');
    await _pressButtonKey(tester, 'admin.okr.statusSave');
    await _pumpUntil(tester, find.text('OKR status updated.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Save status'),
        timeout: const Duration(seconds: 10));
    await _pumpUntil(tester, find.text('IN_PROGRESS'),
        timeout: const Duration(seconds: 35));

    await _employeeProgressAndApprove(
      adminEmail: adminEmail,
      adminPassword: adminPassword,
      employeeEmail: employeeEmail,
      employeePassword: employeePassword,
      title: editedTitle,
    );
    await _pullToRefresh(tester);
    await _pumpUntil(tester, find.text('100% complete'),
        timeout: const Duration(seconds: 35));
    await _pumpUntil(tester, find.text('Approved'),
        timeout: const Duration(seconds: 35));

    await _tapKey(tester, 'admin.okr.managerApprove');
    await _pumpUntil(tester, find.text('Approve OKR?'));
    await _enterPlainField(tester, 'Comment optional', 'FE5D staging approval');
    await _pressButtonKey(tester, 'admin.okr.approvalSubmit');
    await _pumpUntil(tester, find.text('OKR approved.'),
        timeout: const Duration(seconds: 35));
  });
}

Future<void> _employeeProgressAndApprove({
  required String adminEmail,
  required String adminPassword,
  required String employeeEmail,
  required String employeePassword,
  required String title,
}) async {
  final dio = Dio(BaseOptions(baseUrl: _baseUrl));
  final adminToken = await _loginToken(dio, adminEmail, adminPassword);
  final okrsResponse = await dio.get<Map<String, Object?>>(
    '/api/admin/okrs',
    options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
  );
  final data = Map<String, Object?>.from(okrsResponse.data!['data'] as Map);
  final okr = (data['okrs'] as List)
      .whereType<Map>()
      .map((item) => Map<String, Object?>.from(item))
      .firstWhere((item) => item['title'] == title);
  final okrId = okr['id'] as String;

  final employeeToken = await _loginToken(dio, employeeEmail, employeePassword);
  final headers = {'Authorization': 'Bearer $employeeToken'};
  final progress = await dio.post<Map<String, Object?>>(
    '/api/okrs/$okrId/progress',
    data: {
      'progressPercent': 100,
      'note': 'FE5D staging progress',
    },
    options: Options(headers: headers),
  );
  expect(progress.statusCode, 201);
  final approval = await dio.patch<Map<String, Object?>>(
    '/api/okrs/$okrId/employee-approve',
    data: {'comment': 'FE5D staging employee approval'},
    options: Options(headers: headers),
  );
  expect(approval.statusCode, 200);
}

Future<String> _loginToken(Dio dio, String email, String password) async {
  final response = await dio.post<Map<String, Object?>>(
    '/api/auth/login',
    data: {'email': email, 'password': password},
  );
  expect(response.statusCode, 200);
  final data = Map<String, Object?>.from(response.data!['data'] as Map);
  return data['accessToken'] as String;
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

Future<void> _tapTextContaining(WidgetTester tester, String text) async {
  await _tapFinder(tester, find.textContaining(text).last);
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
    if (finder.evaluate().isNotEmpty) return;
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
  final option = find.descendant(
    of: find.byType(DropdownMenuItem<String>),
    matching: find.text(optionText),
  );
  await _pumpUntil(tester, option);
  await tester.tap(option.last, warnIfMissed: false);
  await tester.pumpAndSettle();
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

Future<void> _pullToRefresh(WidgetTester tester) async {
  for (var i = 0; i < 3; i += 1) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 320));
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _boundedPump(WidgetTester tester) async {
  for (var i = 0; i < 8; i += 1) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

String _stagingDate(int stamp) {
  final offset = stamp.remainder(300);
  final date = DateTime.utc(2099).add(Duration(days: offset));
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
