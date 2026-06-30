import 'package:aurelia_mobile/app.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _baseUrl = 'https://workforce-management-production.up.railway.app';
const _tokenKey = 'aurelia.accessToken';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const companyAdminEmail = String.fromEnvironment('QA_COMPANY_ADMIN_EMAIL');
  const companyAdminPassword =
      String.fromEnvironment('QA_COMPANY_ADMIN_PASSWORD');
  const managerEmail = String.fromEnvironment('QA_MANAGER_EMAIL');
  const managerPassword = String.fromEnvironment('QA_MANAGER_PASSWORD');
  const employeeEmail = String.fromEnvironment('QA_EMPLOYEE_EMAIL');
  const employeePassword = String.fromEnvironment('QA_EMPLOYEE_PASSWORD');
  const superAdminEmail = String.fromEnvironment('QA_SUPER_ADMIN_EMAIL');
  const superAdminPassword = String.fromEnvironment('QA_SUPER_ADMIN_PASSWORD');
  const runStaging = bool.fromEnvironment('QA_RUN_STAGING_FE8');

  testWidgets('FE8 reports render and endpoints pass against staging',
      (tester) async {
    if (!runStaging ||
        companyAdminEmail.isEmpty ||
        companyAdminPassword.isEmpty) {
      return;
    }

    await _clearStoredToken();
    await tester.pumpWidget(const ProviderScope(child: AureliaApp()));

    await _pumpUntil(tester, find.text('Email'),
        timeout: const Duration(seconds: 45));
    await _enterField(tester, 'Email', companyAdminEmail);
    await _enterField(tester, 'Password', companyAdminPassword);
    await tester.tap(find.text('Sign in'));
    await _pumpUntil(tester, find.text('Admin setup'),
        timeout: const Duration(seconds: 45));
    await _pumpUntil(tester, find.text('Company dashboard'),
        timeout: const Duration(seconds: 45));

    await _scrollTapKey(tester, 'admin.hub./admin/reports');
    await _pumpUntil(tester, find.text('Reports'),
        timeout: const Duration(seconds: 35));
    await _pumpUntil(tester, find.text('Dashboard'),
        timeout: const Duration(seconds: 35));
    await _pumpUntil(tester, find.text('Attendance'),
        timeout: const Duration(seconds: 35));
    await _scrollUntilText(tester, 'Leave',
        timeout: const Duration(seconds: 35));
    await _scrollUntilText(tester, 'OKRs',
        timeout: const Duration(seconds: 35));
    await _scrollUntilText(tester, 'Performance',
        timeout: const Duration(seconds: 35));

    await _expectAdminReports(
      email: companyAdminEmail,
      password: companyAdminPassword,
    );

    if (managerEmail.isNotEmpty && managerPassword.isNotEmpty) {
      await _expectManagerReports(
        email: managerEmail,
        password: managerPassword,
      );
    }
    if (employeeEmail.isNotEmpty && employeePassword.isNotEmpty) {
      await _expectEmployeeReports(
        email: employeeEmail,
        password: employeePassword,
      );
    }
    if (superAdminEmail.isNotEmpty && superAdminPassword.isNotEmpty) {
      await _expectSuperAdminReports(
        email: superAdminEmail,
        password: superAdminPassword,
      );
    }
  });
}

Future<void> _clearStoredToken() async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  await storage.delete(key: _tokenKey);
}

Future<void> _expectAdminReports({
  required String email,
  required String password,
}) async {
  final dio = Dio(BaseOptions(baseUrl: _baseUrl));
  final token = await _loginToken(dio, email, password);
  final headers = {'Authorization': 'Bearer $token'};
  for (final path in [
    '/api/admin/reports/dashboard',
    '/api/admin/reports/attendance',
    '/api/admin/reports/leave',
    '/api/admin/reports/okrs',
    '/api/admin/reports/performance',
  ]) {
    final response = await dio.get<Map<String, Object?>>(
      path,
      options: Options(headers: headers),
    );
    expect(response.statusCode, 200);
  }
}

Future<void> _expectManagerReports({
  required String email,
  required String password,
}) async {
  final dio = Dio(BaseOptions(baseUrl: _baseUrl));
  final token = await _loginToken(dio, email, password);
  final headers = {'Authorization': 'Bearer $token'};
  for (final path in [
    '/api/reports/team/dashboard',
    '/api/reports/team/attendance',
    '/api/reports/team/leave',
    '/api/reports/team/okrs',
    '/api/reports/team/performance',
  ]) {
    final response = await dio.get<Map<String, Object?>>(
      path,
      options: Options(headers: headers),
    );
    expect(response.statusCode, 200);
  }
}

Future<void> _expectEmployeeReports({
  required String email,
  required String password,
}) async {
  final dio = Dio(BaseOptions(baseUrl: _baseUrl));
  final token = await _loginToken(dio, email, password);
  final response = await dio.get<Map<String, Object?>>(
    '/api/reports/me/dashboard',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  expect(response.statusCode, 200);
}

Future<void> _expectSuperAdminReports({
  required String email,
  required String password,
}) async {
  final dio = Dio(BaseOptions(baseUrl: _baseUrl));
  final token = await _loginToken(dio, email, password);
  final headers = {'Authorization': 'Bearer $token'};
  for (final path in [
    '/api/super-admin/reports/dashboard',
    '/api/super-admin/reports/companies',
  ]) {
    final response = await dio.get<Map<String, Object?>>(
      path,
      options: Options(headers: headers),
    );
    expect(response.statusCode, 200);
  }
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

Future<void> _scrollTapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  final end = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder.first);
      await _boundedPump(tester);
      await tester.tap(finder.first, warnIfMissed: false);
      await tester.pump();
      return;
    }
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      await tester.drag(scrollables.first, const Offset(0, -260));
    }
  }
  throw TestFailure('Timed out scrolling for $finder');
}

Future<void> _scrollUntilText(
  WidgetTester tester,
  String text, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final finder = find.text(text);
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder.first);
      await _boundedPump(tester);
      return;
    }
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      await tester.drag(scrollables.first, const Offset(0, -260));
    }
  }
  throw TestFailure('Timed out scrolling for text $text');
}

Future<void> _boundedPump(WidgetTester tester) async {
  for (var i = 0; i < 8; i += 1) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}
