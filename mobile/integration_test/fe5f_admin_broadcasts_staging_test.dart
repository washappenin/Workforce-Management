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
  const runStaging = bool.fromEnvironment('QA_RUN_STAGING_FE5F');

  testWidgets('FE5F admin notification broadcast passes against staging',
      (tester) async {
    if (!runStaging ||
        adminEmail.isEmpty ||
        adminPassword.isEmpty ||
        employeeEmail.isEmpty ||
        employeePassword.isEmpty) {
      return;
    }

    final stamp = DateTime.now().millisecondsSinceEpoch.remainder(100000000);
    final title = 'FE5F Broadcast $stamp';
    final message = 'FE5F targeted staging announcement $stamp';

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

    await _scrollTapKey(tester, 'admin.hub./admin/notifications/broadcast');
    await _pumpUntil(tester, find.text('Broadcasts'),
        timeout: const Duration(seconds: 35));

    await _enterFieldByKey(tester, 'admin.broadcast.title', title);
    await _enterFieldByKey(tester, 'admin.broadcast.message', message);
    await _selectDropdownOption(tester, 'admin.broadcast.type', 'OKR');
    await _selectDropdownOption(
      tester,
      'admin.broadcast.targetRole',
      'EMPLOYEE',
    );
    await _enterFieldByKey(
      tester,
      'admin.broadcast.employee.search',
      employeeEmail,
    );
    await _tapTextContaining(tester, employeeEmail);
    await _pressButtonKey(tester, 'admin.broadcast.send');
    await _pumpUntil(tester, find.text('1 notifications sent.'),
        timeout: const Duration(seconds: 35));
    await _scrollUntil(tester, find.text('Broadcast sent'),
        timeout: const Duration(seconds: 20));

    await _expectEmployeeNotification(
      email: employeeEmail,
      password: employeePassword,
      title: title,
      message: message,
    );
  });
}

Future<void> _expectEmployeeNotification({
  required String email,
  required String password,
  required String title,
  required String message,
}) async {
  final dio = Dio(BaseOptions(baseUrl: _baseUrl));
  final token = await _loginToken(dio, email, password);
  final response = await dio.get<Map<String, Object?>>(
    '/api/notifications/me',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  expect(response.statusCode, 200);
  final data = Map<String, Object?>.from(response.data!['data'] as Map);
  final notifications = (data['notifications'] as List)
      .whereType<Map>()
      .map((item) => Map<String, Object?>.from(item))
      .toList(growable: false);
  expect(
    notifications.any(
      (notification) =>
          notification['title'] == title &&
          notification['message'] == message &&
          notification['type'] == 'OKR' &&
          notification['status'] == 'UNREAD',
    ),
    isTrue,
  );
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
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      await tester.drag(scrollables.last, const Offset(0, -260));
    }
  }
  throw TestFailure('Timed out scrolling for $finder');
}

Future<void> _tapTextContaining(WidgetTester tester, String text) async {
  await _tapFinder(tester, find.textContaining(text).last);
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
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      await tester.drag(scrollables.first, const Offset(0, -260));
    }
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
  await _scrollUntil(tester, dropdown);
  await tester.tap(dropdown.first, warnIfMissed: false);
  await tester.pumpAndSettle();
  final option = find.text(optionText);
  await _pumpUntil(tester, option);
  await tester.tap(option.last, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _pressButtonKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await _scrollUntil(tester, finder);
  await tester.ensureVisible(finder.last);
  await _boundedPump(tester);
  final widget = tester.widget(finder.last);
  if (widget is ButtonStyleButton && widget.onPressed != null) {
    widget.onPressed!();
  } else {
    await tester.tap(finder.last, warnIfMissed: false);
  }
  await tester.pump();
}

Future<void> _boundedPump(WidgetTester tester) async {
  for (var i = 0; i < 8; i += 1) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}
