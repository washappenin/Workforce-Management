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
  const runStaging = bool.fromEnvironment('QA_RUN_STAGING_FE5G');

  testWidgets('FE5G admin billing self-view passes against staging',
      (tester) async {
    if (!runStaging || adminEmail.isEmpty || adminPassword.isEmpty) {
      return;
    }

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

    await _scrollTapKey(tester, 'admin.hub./admin/subscription');
    await _pumpUntil(tester, find.text('Billing'),
        timeout: const Duration(seconds: 35));
    await _pumpUntilAny(
      tester,
      {
        'subscription': find.byKey(
          const ValueKey('admin.billing.subscription.card'),
        ),
        'empty': find.text('No subscription found'),
      },
      timeout: const Duration(seconds: 35),
    );

    await _tapKey(tester, 'admin.billing.tab.payments');
    await _pumpUntilAny(
      tester,
      {
        'payments': _findKeyPrefix('admin.billing.payment.'),
        'empty': find.text('No payment records'),
      },
      timeout: const Duration(seconds: 35),
    );

    await _expectBillingApis(
      email: adminEmail,
      password: adminPassword,
    );
  });
}

Future<void> _expectBillingApis({
  required String email,
  required String password,
}) async {
  final dio = Dio(BaseOptions(baseUrl: _baseUrl));
  final token = await _loginToken(dio, email, password);
  final headers = {'Authorization': 'Bearer $token'};

  final subscription = await dio.get<Map<String, Object?>>(
    '/api/admin/subscription',
    options: Options(headers: headers),
  );
  expect(subscription.statusCode, 200);
  expect(subscription.data!['data'], isA<Map>());

  final payments = await dio.get<Map<String, Object?>>(
    '/api/admin/payment-records',
    options: Options(headers: headers),
  );
  expect(payments.statusCode, 200);
  final data = Map<String, Object?>.from(payments.data!['data'] as Map);
  final records = (data['paymentRecords'] as List? ?? const [])
      .whereType<Map>()
      .map((item) => Map<String, Object?>.from(item));
  for (final record in records) {
    expect(record.containsKey('providerReference'), isFalse);
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

Future<void> _tapKey(WidgetTester tester, String key) async {
  await _tapFinder(tester, find.byKey(ValueKey(key)));
}

Finder _findKeyPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith(prefix);
  });
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

Future<void> _boundedPump(WidgetTester tester) async {
  for (var i = 0; i < 8; i += 1) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}
