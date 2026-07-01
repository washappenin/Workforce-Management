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

  const superAdminEmail = String.fromEnvironment('QA_SUPER_ADMIN_EMAIL');
  const superAdminPassword = String.fromEnvironment('QA_SUPER_ADMIN_PASSWORD');
  const runStaging = bool.fromEnvironment('QA_RUN_STAGING_FE7');

  testWidgets('FE7 super-admin workflows pass against staging', (tester) async {
    if (!runStaging || superAdminEmail.isEmpty || superAdminPassword.isEmpty) {
      return;
    }

    await tester.pumpWidget(const ProviderScope(child: AureliaApp()));

    final startup = await _pumpUntilAny(
      tester,
      {
        'login': find.text('Email'),
        'platform': find.text('Platform command'),
      },
      timeout: const Duration(seconds: 60),
    );
    if (startup == 'login') {
      await _enterField(tester, 'Email', superAdminEmail);
      await _enterField(tester, 'Password', superAdminPassword);
      await tester.tap(find.text('Sign in'));
      await _pumpUntil(
        tester,
        find.text('Platform command'),
        timeout: const Duration(seconds: 45),
      );
    }

    await _tapBottomDestination(tester, 'Companies');
    await _pumpUntil(
      tester,
      find.text('Onboarding, profile, and lifecycle status.'),
      timeout: const Duration(seconds: 35),
    );

    await _tapBottomDestination(tester, 'Plans');
    await _pumpUntil(
      tester,
      find.text('Subscription plan records and status.'),
      timeout: const Duration(seconds: 35),
    );

    await _tapBottomDestination(tester, 'Billing');
    await _pumpUntil(
      tester,
      find.text('Company plan assignment and billing status.'),
      timeout: const Duration(seconds: 35),
    );

    await _tapBottomDestination(tester, 'Platform');
    await _pumpUntil(
      tester,
      find.text('Platform command'),
      timeout: const Duration(seconds: 35),
    );
    await _scrollTapKey(tester, 'superAdmin.hub./super-admin/payment-records');
    await _pumpUntil(
      tester,
      find.text('Manual payment records and provider references.'),
      timeout: const Duration(seconds: 35),
    );

    await _tapBottomDestination(tester, 'Reports');
    await _pumpUntil(
      tester,
      find.text('Platform dashboard and company rollups.'),
      timeout: const Duration(seconds: 35),
    );

    await _expectSuperAdminApis(
      email: superAdminEmail,
      password: superAdminPassword,
    );
  });
}

Future<void> _expectSuperAdminApis({
  required String email,
  required String password,
}) async {
  final dio = Dio(BaseOptions(baseUrl: _baseUrl));
  final token = await _loginToken(dio, email, password);
  final headers = {'Authorization': 'Bearer $token'};

  final dashboard = await dio.get<Map<String, Object?>>(
    '/api/super-admin/reports/dashboard',
    options: Options(headers: headers),
  );
  expect(dashboard.statusCode, 200);

  final companies = await dio.get<Map<String, Object?>>(
    '/api/super-admin/companies',
    options: Options(headers: headers),
  );
  expect(companies.statusCode, 200);

  final plans = await dio.get<Map<String, Object?>>(
    '/api/super-admin/plans',
    options: Options(headers: headers),
  );
  expect(plans.statusCode, 200);

  final subscriptions = await dio.get<Map<String, Object?>>(
    '/api/super-admin/subscriptions',
    options: Options(headers: headers),
  );
  expect(subscriptions.statusCode, 200);

  final payments = await dio.get<Map<String, Object?>>(
    '/api/super-admin/payment-records',
    options: Options(headers: headers),
  );
  expect(payments.statusCode, 200);

  final companyRollups = await dio.get<Map<String, Object?>>(
    '/api/super-admin/reports/companies',
    options: Options(headers: headers),
  );
  expect(companyRollups.statusCode, 200);

  final stamp = DateTime.now().millisecondsSinceEpoch;
  final company = await dio.post<Map<String, Object?>>(
    '/api/super-admin/companies',
    data: {
      'name': 'FE7 Platform Co $stamp',
      'contactEmail': 'fe7-contact-$stamp@example.test',
      'billingEmail': 'fe7-billing-$stamp@example.test',
      'country': 'US',
      'timezone': 'America/New_York',
      'status': 'ACTIVE',
    },
    options: Options(headers: headers),
  );
  expect(company.statusCode, 201);
  final companyBody = _object(company.data!, 'company');
  final companyId = companyBody['id'] as String;

  final updatedCompany = await dio.patch<Map<String, Object?>>(
    '/api/super-admin/companies/$companyId',
    data: {
      'name': 'FE7 Platform Co $stamp Updated',
      'contactPhone': '+1555000${stamp.toString().substring(7)}',
    },
    options: Options(headers: headers),
  );
  expect(updatedCompany.statusCode, 200);

  final companyStatus = await dio.patch<Map<String, Object?>>(
    '/api/super-admin/companies/$companyId/status',
    data: {'status': 'ACTIVE'},
    options: Options(headers: headers),
  );
  expect(companyStatus.statusCode, 200);

  final plan = await dio.post<Map<String, Object?>>(
    '/api/super-admin/plans',
    data: {
      'name': 'FE7 Plan $stamp',
      'type': 'BASIC',
      'pricePerEmployee': 7.25,
      'currency': 'USD',
      'isActive': true,
    },
    options: Options(headers: headers),
  );
  expect(plan.statusCode, 201);
  final planBody = _object(plan.data!, 'plan');
  final planId = planBody['id'] as String;

  final updatedPlan = await dio.patch<Map<String, Object?>>(
    '/api/super-admin/plans/$planId',
    data: {
      'name': 'FE7 Plan $stamp Updated',
      'type': 'PREMIUM',
      'pricePerEmployee': 8.5,
      'currency': 'USD',
      'isActive': true,
    },
    options: Options(headers: headers),
  );
  expect(updatedPlan.statusCode, 200);

  final planStatus = await dio.patch<Map<String, Object?>>(
    '/api/super-admin/plans/$planId/status',
    data: {'isActive': true},
    options: Options(headers: headers),
  );
  expect(planStatus.statusCode, 200);

  final subscription = await dio.post<Map<String, Object?>>(
    '/api/super-admin/companies/$companyId/subscription',
    data: {
      'planId': planId,
      'startsAt': '2026-07-01',
      'endsAt': null,
      'status': 'ACTIVE',
    },
    options: Options(headers: headers),
  );
  expect(subscription.statusCode, 201);
  final subscriptionBody = _object(subscription.data!, 'subscription');
  final subscriptionId = subscriptionBody['id'] as String;

  final companySubscription = await dio.get<Map<String, Object?>>(
    '/api/super-admin/companies/$companyId/subscription',
    options: Options(headers: headers),
  );
  expect(companySubscription.statusCode, 200);

  final subscriptionStatus = await dio.patch<Map<String, Object?>>(
    '/api/super-admin/subscriptions/$subscriptionId/status',
    data: {'status': 'PAST_DUE', 'endsAt': null},
    options: Options(headers: headers),
  );
  expect(subscriptionStatus.statusCode, 200);

  final payment = await dio.post<Map<String, Object?>>(
    '/api/super-admin/payment-records',
    data: {
      'companyId': companyId,
      'subscriptionId': subscriptionId,
      'amount': 42.75,
      'currency': 'USD',
      'status': 'PAID',
      'provider': 'Manual',
      'providerReference': 'FE7-$stamp',
      'paidAt': '2026-07-02',
    },
    options: Options(headers: headers),
  );
  expect(payment.statusCode, 201);

  final companyPayments = await dio.get<Map<String, Object?>>(
    '/api/super-admin/companies/$companyId/payment-records',
    options: Options(headers: headers),
  );
  expect(companyPayments.statusCode, 200);
  final companyPaymentItems = _list(companyPayments.data!, 'paymentRecords');
  expect(companyPaymentItems, isNotEmpty);
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

Map<String, Object?> _object(Map<String, Object?> response, String key) {
  final data = Map<String, Object?>.from(response['data'] as Map);
  return Map<String, Object?>.from(data[key] as Map);
}

List<Map<String, Object?>> _list(Map<String, Object?> response, String key) {
  final data = Map<String, Object?>.from(response['data'] as Map);
  return (data[key] as List? ?? const [])
      .whereType<Map>()
      .map((item) => Map<String, Object?>.from(item))
      .toList(growable: false);
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

Future<void> _tapBottomDestination(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await _pumpUntil(tester, finder);
  await tester.tap(finder.last, warnIfMissed: false);
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

Future<void> _boundedPump(WidgetTester tester) async {
  for (var i = 0; i < 8; i += 1) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}
