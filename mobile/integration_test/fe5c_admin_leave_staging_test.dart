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
  const runStaging = bool.fromEnvironment('QA_RUN_STAGING_FE5C');

  testWidgets('FE5C admin leave operations pass against staging',
      (tester) async {
    if (!runStaging ||
        adminEmail.isEmpty ||
        adminPassword.isEmpty ||
        employeeEmail.isEmpty ||
        employeePassword.isEmpty) {
      return;
    }

    final stamp = DateTime.now().millisecondsSinceEpoch.remainder(100000000);
    final leaveTypeName = 'FE5C Leave $stamp';
    const entitlementYear = 2099;
    final requestedDate = _stagingDate(stamp);
    final reason = 'FE5C staging request $stamp';

    await tester.pumpWidget(const ProviderScope(child: AureliaApp()));

    await _pumpUntil(tester, find.text('Email'));
    await _enterField(tester, 'Email', adminEmail);
    await _enterField(tester, 'Password', adminPassword);
    await tester.tap(find.text('Sign in'));

    await _pumpUntil(tester, find.text('Admin setup'),
        timeout: const Duration(seconds: 35));

    await _scrollTapKey(tester, 'admin.hub./admin/leave');
    await _pumpUntil(tester, find.text('Leave'),
        timeout: const Duration(seconds: 35));

    await _tapKey(tester, 'admin.leaveType.create');
    await _pumpUntil(tester, find.text('New leave type'));
    await _enterField(tester, 'Name', leaveTypeName);
    await _enterField(tester, 'Default annual allowance optional', '40');
    await _pressButtonKey(tester, 'admin.leaveType.save');
    await _pumpUntil(tester, find.text('Leave type saved.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Save leave type'),
        timeout: const Duration(seconds: 10));
    await _pumpUntil(tester, find.text(leaveTypeName),
        timeout: const Duration(seconds: 35));

    await _tapText(tester, 'Balances');
    await _pumpUntil(tester, find.text('Assign balance'),
        timeout: const Duration(seconds: 20));

    await _tapKey(tester, 'admin.leaveEntitlement.create');
    await _pumpUntil(tester, find.text('Assign leave balance'));
    await _enterField(tester, 'Employee search', employeeEmail);
    await _tapTextContaining(tester, employeeEmail);
    await _enterField(tester, 'Leave type search', leaveTypeName);
    await _tapText(tester, leaveTypeName);
    await _enterField(tester, 'Year', entitlementYear.toString());
    await _enterField(tester, 'Total days', '40');
    await _enterField(tester, 'Used days', '0');
    await _pressButtonKey(tester, 'admin.leaveEntitlement.save');
    await _pumpUntil(tester, find.text('Leave balance saved.'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilGone(tester, find.text('Save balance'),
        timeout: const Duration(seconds: 10));
    await _pumpUntil(tester, find.text(leaveTypeName),
        timeout: const Duration(seconds: 35));

    await _submitEmployeeLeaveRequest(
      adminEmail: adminEmail,
      adminPassword: adminPassword,
      employeeEmail: employeeEmail,
      employeePassword: employeePassword,
      leaveTypeName: leaveTypeName,
      date: requestedDate,
      reason: reason,
    );

    await _tapText(tester, 'Requests');
    await _pumpUntil(tester, find.text('Status filter'),
        timeout: const Duration(seconds: 20));
    await _scrollUntil(tester, find.text(reason),
        timeout: const Duration(seconds: 45));
    await _scrollTapFinder(
        tester, _buttonKeyPrefix('admin.leaveRequest.approve.'));
    await _pumpUntil(tester, find.text('Approve request?'));
    await _enterPlainField(tester, 'Comment optional', 'FE5C staging approval');
    await _pressButtonKey(tester, 'admin.leaveRequest.reviewSubmit');
    await _pumpUntil(tester, find.text('Leave request approved.'),
        timeout: const Duration(seconds: 35));
  });
}

Future<void> _submitEmployeeLeaveRequest({
  required String adminEmail,
  required String adminPassword,
  required String employeeEmail,
  required String employeePassword,
  required String leaveTypeName,
  required String date,
  required String reason,
}) async {
  final dio = Dio(BaseOptions(baseUrl: _baseUrl));
  final adminToken = await _loginToken(dio, adminEmail, adminPassword);
  final typeResponse = await dio.get<Map<String, Object?>>(
    '/api/admin/leave-types',
    options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
  );
  final data = Map<String, Object?>.from(typeResponse.data!['data'] as Map);
  final leaveTypes = (data['leaveTypes'] as List).whereType<Map>();
  final leaveType = leaveTypes
      .map((item) => Map<String, Object?>.from(item))
      .firstWhere((item) => item['name'] == leaveTypeName);
  final leaveTypeId = leaveType['id'] as String;

  final employeeToken = await _loginToken(dio, employeeEmail, employeePassword);
  final response = await dio.post<Map<String, Object?>>(
    '/api/leave/request',
    data: {
      'leaveTypeId': leaveTypeId,
      'startDate': date,
      'endDate': date,
      'reason': reason,
    },
    options: Options(headers: {'Authorization': 'Bearer $employeeToken'}),
  );
  expect(response.statusCode, 201);
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

Future<void> _tapText(WidgetTester tester, String text) async {
  await _tapFinder(tester, find.text(text).last);
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

Finder _buttonKeyPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey && key.value.toString().startsWith(prefix);
  });
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
