import 'package:aurelia_mobile/app.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _baseUrl = 'https://workforce-management-production.up.railway.app';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const managerEmail = String.fromEnvironment('QA_MANAGER_EMAIL');
  const managerPassword = String.fromEnvironment('QA_MANAGER_PASSWORD');
  const employeeEmail = String.fromEnvironment('QA_EMPLOYEE_EMAIL');
  const employeePassword = String.fromEnvironment('QA_EMPLOYEE_PASSWORD');
  const runStaging = bool.fromEnvironment('QA_RUN_STAGING_FE6');

  testWidgets('FE6 manager workflows pass against staging', (tester) async {
    if (!runStaging || managerEmail.isEmpty || managerPassword.isEmpty) {
      return;
    }

    await tester.pumpWidget(const ProviderScope(child: AureliaApp()));

    final startup = await _pumpUntilAny(
      tester,
      {
        'login': find.text('Email'),
        'manager': find.text('Team command'),
      },
      timeout: const Duration(seconds: 60),
    );
    if (startup == 'login') {
      await _enterField(tester, 'Email', managerEmail);
      await _enterField(tester, 'Password', managerPassword);
      await tester.tap(find.text('Sign in'));
      await _pumpUntil(tester, find.text('Team command'),
          timeout: const Duration(seconds: 45));
    }

    await _scrollTapKey(tester, 'manager.hub./manager/attendance');
    await _pumpUntil(tester, find.text('Attendance'),
        timeout: const Duration(seconds: 35));
    await _tapBottomDestination(tester, 'Leave');
    await _pumpUntil(tester, find.text('Leave'),
        timeout: const Duration(seconds: 35));
    await _tapBottomDestination(tester, 'OKRs');
    await _pumpUntil(tester, find.text('OKRs'),
        timeout: const Duration(seconds: 35));
    await _tapBottomDestination(tester, 'Reviews');
    await _pumpUntil(tester, find.text('Reviews'),
        timeout: const Duration(seconds: 35));
    await _tapBottomDestination(tester, 'Reports');
    await _pumpUntil(tester, find.text('Reports'),
        timeout: const Duration(seconds: 35));

    await _expectManagerApis(
      managerEmail: managerEmail,
      managerPassword: managerPassword,
      employeeEmail: employeeEmail,
      employeePassword: employeePassword,
    );
  });
}

Future<void> _expectManagerApis({
  required String managerEmail,
  required String managerPassword,
  required String employeeEmail,
  required String employeePassword,
}) async {
  final dio = Dio(BaseOptions(baseUrl: _baseUrl));
  final token = await _loginToken(dio, managerEmail, managerPassword);
  final headers = {'Authorization': 'Bearer $token'};

  final dashboard = await dio.get<Map<String, Object?>>(
    '/api/reports/team/dashboard',
    options: Options(headers: headers),
  );
  expect(dashboard.statusCode, 200);

  final attendance = await dio.get<Map<String, Object?>>(
    '/api/reports/team/attendance',
    options: Options(headers: headers),
  );
  expect(attendance.statusCode, 200);

  final leaveReport = await dio.get<Map<String, Object?>>(
    '/api/reports/team/leave',
    options: Options(headers: headers),
  );
  expect(leaveReport.statusCode, 200);

  final okrReport = await dio.get<Map<String, Object?>>(
    '/api/reports/team/okrs',
    options: Options(headers: headers),
  );
  expect(okrReport.statusCode, 200);

  final performanceReport = await dio.get<Map<String, Object?>>(
    '/api/reports/team/performance',
    options: Options(headers: headers),
  );
  expect(performanceReport.statusCode, 200);

  final unread = await dio.get<Map<String, Object?>>(
    '/api/notifications/me/unread-count',
    options: Options(headers: headers),
  );
  expect(unread.statusCode, 200);

  final notifications = await dio.get<Map<String, Object?>>(
    '/api/notifications/me',
    options: Options(headers: headers),
  );
  expect(notifications.statusCode, 200);

  final leave = await dio.get<Map<String, Object?>>(
    '/api/leave/team',
    options: Options(headers: headers),
  );
  expect(leave.statusCode, 200);
  final leaveRequests = _list(leave.data!, 'leaveRequests');

  final okrs = await dio.get<Map<String, Object?>>(
    '/api/okrs/team',
    options: Options(headers: headers),
  );
  expect(okrs.statusCode, 200);
  final okrItems = _list(okrs.data!, 'okrs');

  final reviews = await dio.get<Map<String, Object?>>(
    '/api/reviews/team',
    options: Options(headers: headers),
  );
  expect(reviews.statusCode, 200);
  final reviewItems = _list(reviews.data!, 'reviews');

  final employeeId = _firstEmployeeId(leaveRequests, okrItems, reviewItems);
  if (employeeId != null) {
    final stamp = DateTime.now().millisecondsSinceEpoch.remainder(100000000);
    final createdOkr = await dio.post<Map<String, Object?>>(
      '/api/okrs',
      data: {
        'employeeId': employeeId,
        'title': 'FE6 manager OKR $stamp',
        'description': 'FE6 staging manager assignment $stamp',
        'dueDate': '2026-12-20',
      },
      options: Options(headers: headers),
    );
    expect(createdOkr.statusCode, 201);
    final okr = Map<String, Object?>.from(
      (createdOkr.data!['data'] as Map)['okr'] as Map,
    );
    final okrId = okr['id'] as String;

    final status = await dio.patch<Map<String, Object?>>(
      '/api/okrs/$okrId/status',
      data: {'status': 'IN_PROGRESS'},
      options: Options(headers: headers),
    );
    expect(status.statusCode, 200);

    final approved = await dio.patch<Map<String, Object?>>(
      '/api/okrs/$okrId/manager-approve',
      data: {'comment': 'FE6 manager approval'},
      options: Options(headers: headers),
    );
    expect(approved.statusCode, 200);
  }

  final editableReview = reviewItems.cast<Map<String, Object?>>().firstWhere(
        (review) =>
            review['status'] != 'ACKNOWLEDGED' &&
            review['status'] != 'ARCHIVED',
        orElse: () => const {},
      );
  if (editableReview.isNotEmpty) {
    final reviewId = editableReview['id'] as String;
    final updated = await dio.patch<Map<String, Object?>>(
      '/api/reviews/$reviewId',
      data: {
        'summary':
            'FE6 manager review verification ${DateTime.now().millisecondsSinceEpoch}',
        'rating': 4,
      },
      options: Options(headers: headers),
    );
    expect(updated.statusCode, 200);

    final status = await dio.patch<Map<String, Object?>>(
      '/api/reviews/$reviewId/status',
      data: {'status': 'SUBMITTED'},
      options: Options(headers: headers),
    );
    expect(status.statusCode, 200);
  }

  if (employeeEmail.isNotEmpty && employeePassword.isNotEmpty) {
    await _tryCreateAndApproveLeave(
      dio: dio,
      managerHeaders: headers,
      employeeEmail: employeeEmail,
      employeePassword: employeePassword,
    );
  }
}

Future<void> _tryCreateAndApproveLeave({
  required Dio dio,
  required Map<String, String> managerHeaders,
  required String employeeEmail,
  required String employeePassword,
}) async {
  final employeeToken = await _loginToken(dio, employeeEmail, employeePassword);
  final employeeHeaders = {'Authorization': 'Bearer $employeeToken'};
  final mine = await dio.get<Map<String, Object?>>(
    '/api/leave/me',
    options: Options(headers: employeeHeaders),
  );
  final data = Map<String, Object?>.from(mine.data!['data'] as Map);
  final entitlements = (data['entitlements'] as List? ?? const [])
      .whereType<Map>()
      .map((item) => Map<String, Object?>.from(item))
      .where((item) => ((item['remainingDays'] as num?) ?? 0) >= 1)
      .toList(growable: false);
  if (entitlements.isEmpty) return;

  final leaveTypeId = entitlements.first['leaveTypeId'] as String;
  final day = 1 + DateTime.now().millisecondsSinceEpoch.remainder(20);
  final date = '2026-11-${day.toString().padLeft(2, '0')}';
  try {
    final created = await dio.post<Map<String, Object?>>(
      '/api/leave/request',
      data: {
        'leaveTypeId': leaveTypeId,
        'startDate': date,
        'endDate': date,
        'reason': 'FE6 manager approval verification',
      },
      options: Options(headers: employeeHeaders),
    );
    expect(created.statusCode, 201);
    final leaveRequest = Map<String, Object?>.from(
      (created.data!['data'] as Map)['leaveRequest'] as Map,
    );
    final leaveRequestId = leaveRequest['id'] as String;
    final approved = await dio.patch<Map<String, Object?>>(
      '/api/leave/$leaveRequestId/approve',
      data: {'comment': 'FE6 approval'},
      options: Options(headers: managerHeaders),
    );
    expect(approved.statusCode, 200);
  } on DioException catch (error) {
    if (error.response?.statusCode != 400 &&
        error.response?.statusCode != 409) {
      rethrow;
    }
  }
}

String? _firstEmployeeId(
  List<Map<String, Object?>> leave,
  List<Map<String, Object?>> okrs,
  List<Map<String, Object?>> reviews,
) {
  for (final source in [leave, okrs, reviews]) {
    for (final item in source) {
      final employeeId = item['employeeId'] as String?;
      if (employeeId != null && employeeId.isNotEmpty) return employeeId;
    }
  }
  return null;
}

List<Map<String, Object?>> _list(Map<String, Object?> response, String key) {
  final data = Map<String, Object?>.from(response['data'] as Map);
  return (data[key] as List? ?? const [])
      .whereType<Map>()
      .map((item) => Map<String, Object?>.from(item))
      .toList(growable: false);
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
