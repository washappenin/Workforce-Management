import 'package:aurelia_mobile/app.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _baseUrl = 'https://workforce-management-production.up.railway.app';
const _frontendOrigin = 'https://exact-render-route.lovable.app';
const _tokenKey = 'aurelia.accessToken';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const employeeEmail = String.fromEnvironment('QA_EMPLOYEE_EMAIL');
  const employeePassword = String.fromEnvironment('QA_EMPLOYEE_PASSWORD');
  const companyAdminEmail = String.fromEnvironment('QA_COMPANY_ADMIN_EMAIL');
  const companyAdminPassword =
      String.fromEnvironment('QA_COMPANY_ADMIN_PASSWORD');
  const hrAdminEmail = String.fromEnvironment('QA_HR_ADMIN_EMAIL');
  const hrAdminPassword = String.fromEnvironment('QA_HR_ADMIN_PASSWORD');
  const managerEmail = String.fromEnvironment('QA_MANAGER_EMAIL');
  const managerPassword = String.fromEnvironment('QA_MANAGER_PASSWORD');
  const superAdminEmail = String.fromEnvironment('QA_SUPER_ADMIN_EMAIL');
  const superAdminPassword = String.fromEnvironment('QA_SUPER_ADMIN_PASSWORD');
  const runStaging = bool.fromEnvironment('QA_RUN_STAGING_FE9');

  testWidgets('FE9 backend launch-gate checks pass against staging',
      (tester) async {
    if (!runStaging || employeeEmail.isEmpty || employeePassword.isEmpty) {
      return;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    final health = await dio.get<Map<String, Object?>>('/health');
    expect(health.statusCode, 200);

    final ready = await dio.get<Map<String, Object?>>('/ready');
    expect(ready.statusCode, 200);

    final preflight = await dio.request<void>(
      '/api/auth/login',
      options: Options(
        method: 'OPTIONS',
        headers: {
          'Origin': _frontendOrigin,
          'Access-Control-Request-Method': 'POST',
          'Access-Control-Request-Headers': 'content-type,authorization',
        },
      ),
    );
    expect(preflight.statusCode, isIn(<int>{200, 204}));
    expect(
      preflight.headers.value('access-control-allow-origin'),
      _frontendOrigin,
    );

    final invalidLogin = await dio.post<Map<String, Object?>>(
      '/api/auth/login',
      data: {'email': employeeEmail, 'password': 'definitely-not-valid'},
    );
    expect(invalidLogin.statusCode, 401);

    final validation = await dio.post<Map<String, Object?>>(
      '/api/auth/login',
      data: {'email': '', 'password': ''},
    );
    expect(validation.statusCode, isIn(<int>{400, 422}));

    final employeeToken = await _loginToken(
      dio,
      employeeEmail,
      employeePassword,
    );
    final employeeHeaders = {'Authorization': 'Bearer $employeeToken'};

    final forbidden = await dio.get<Map<String, Object?>>(
      '/api/admin/reports/dashboard',
      options: Options(headers: employeeHeaders),
    );
    expect(forbidden.statusCode, 403);

    final notFound = await dio.get<Map<String, Object?>>(
      '/api/not-a-real-route',
      options: Options(headers: employeeHeaders),
    );
    expect(notFound.statusCode, 404);
  });

  testWidgets('FE9 employee visible navigation passes', (tester) async {
    if (!runStaging || employeeEmail.isEmpty || employeePassword.isEmpty) {
      return;
    }
    await _loginAndVisitNav(
      tester,
      email: employeeEmail,
      password: employeePassword,
      landingText: 'Self-service',
      navChecks: const [
        ('Home', 'Self-service'),
        ('Time', 'Your clock session history'),
        ('Leave', 'Balances and requests'),
        ('OKRs', 'Objectives and progress'),
        ('Account', 'Account'),
      ],
    );
  });

  testWidgets('FE9 company-admin visible navigation passes', (tester) async {
    if (!runStaging ||
        companyAdminEmail.isEmpty ||
        companyAdminPassword.isEmpty) {
      return;
    }
    await _loginAndVisitNav(
      tester,
      email: companyAdminEmail,
      password: companyAdminPassword,
      landingText: 'Admin setup',
      navChecks: const [
        ('Admin', 'Company dashboard'),
        ('People', 'Staff records, roles, managers, and status.'),
        ('Geo', 'Circular worksites for attendance validation.'),
        ('Time', 'Company clock sessions and verification status.'),
        ('Account', 'Account'),
      ],
    );
  });

  testWidgets('FE9 HR-admin visible navigation passes', (tester) async {
    if (!runStaging || hrAdminEmail.isEmpty || hrAdminPassword.isEmpty) {
      return;
    }
    await _loginAndVisitNav(
      tester,
      email: hrAdminEmail,
      password: hrAdminPassword,
      landingText: 'Admin setup',
      navChecks: const [
        ('Admin', 'Company dashboard'),
        ('People', 'Staff records, roles, managers, and status.'),
        ('Geo', 'Circular worksites for attendance validation.'),
        ('Time', 'Company clock sessions and verification status.'),
        ('Account', 'Account'),
      ],
    );
  });

  testWidgets('FE9 manager visible navigation passes', (tester) async {
    if (!runStaging || managerEmail.isEmpty || managerPassword.isEmpty) {
      return;
    }
    await _loginAndVisitNav(
      tester,
      email: managerEmail,
      password: managerPassword,
      landingText: 'Team command',
      navChecks: const [
        ('Team', 'Team command'),
        ('Leave', 'Direct-report requests'),
        ('OKRs', 'Direct-report objectives'),
        ('Reviews', 'Direct-report performance'),
        ('Reports', 'Direct-report summaries'),
      ],
    );
  });

  testWidgets('FE9 super-admin visible navigation passes', (tester) async {
    if (!runStaging || superAdminEmail.isEmpty || superAdminPassword.isEmpty) {
      return;
    }
    await _loginAndVisitNav(
      tester,
      email: superAdminEmail,
      password: superAdminPassword,
      landingText: 'Platform command',
      navChecks: const [
        ('Platform', 'Platform command'),
        ('Companies', 'Onboarding, profile, and lifecycle status.'),
        ('Plans', 'Subscription plan records and status.'),
        ('Billing', 'Company plan assignment and billing status.'),
        ('Reports', 'Platform dashboard and company rollups.'),
      ],
    );
  });
}

Future<void> _loginAndVisitNav(
  WidgetTester tester, {
  required String email,
  required String password,
  required String landingText,
  required List<(String, String)> navChecks,
}) async {
  await _clearStoredToken();
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(const ProviderScope(child: AureliaApp()));

  await _pumpUntil(tester, find.text('Email'),
      timeout: const Duration(seconds: 45));
  await _enterField(tester, 'Email', email);
  await _enterField(tester, 'Password', password);
  await tester.tap(find.text('Sign in'));
  await _pumpUntil(tester, find.text(landingText),
      timeout: const Duration(seconds: 55));

  for (final check in navChecks) {
    await _tapBottomDestination(tester, check.$1);
    await _pumpUntil(tester, find.text(check.$2),
        timeout: const Duration(seconds: 45));
  }
}

Future<void> _clearStoredToken() async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  await storage.delete(key: _tokenKey);
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

Future<void> _tapBottomDestination(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await _pumpUntil(tester, finder);
  await tester.tap(finder.last, warnIfMissed: false);
  await tester.pump();
}

Future<void> _boundedPump(WidgetTester tester) async {
  for (var i = 0; i < 8; i += 1) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}
