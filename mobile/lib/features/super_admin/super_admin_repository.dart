import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import 'super_admin_models.dart';

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  return SuperAdminRepository(ref.watch(apiClientProvider));
});

final superAdminDashboardProvider =
    FutureProvider.autoDispose<SuperAdminDashboard>((ref) {
  return ref.watch(superAdminRepositoryProvider).getDashboard();
});

final superAdminCompaniesProvider =
    FutureProvider.autoDispose<List<SuperAdminCompany>>((ref) {
  return ref.watch(superAdminRepositoryProvider).listCompanies();
});

final superAdminCompanyProvider =
    FutureProvider.autoDispose.family<SuperAdminCompany, String>((ref, id) {
  return ref.watch(superAdminRepositoryProvider).getCompany(id);
});

final superAdminPlansProvider =
    FutureProvider.autoDispose<List<SuperAdminSubscriptionPlan>>((ref) {
  return ref.watch(superAdminRepositoryProvider).listPlans();
});

final superAdminSubscriptionsProvider = FutureProvider.autoDispose
    .family<List<SuperAdminCompanySubscription>, String?>((ref, companyId) {
  return ref.watch(superAdminRepositoryProvider).listSubscriptions(
        companyId: companyId,
      );
});

final superAdminCompanySubscriptionProvider = FutureProvider.autoDispose
    .family<SuperAdminCompanySubscription?, String>((ref, companyId) {
  return ref.watch(superAdminRepositoryProvider).getCompanySubscription(
        companyId,
      );
});

final superAdminPaymentRecordsProvider = FutureProvider.autoDispose
    .family<List<SuperAdminPaymentRecord>, String?>((ref, companyId) {
  if (companyId != null && companyId.trim().isNotEmpty) {
    return ref.watch(superAdminRepositoryProvider).listCompanyPaymentRecords(
          companyId,
        );
  }
  return ref.watch(superAdminRepositoryProvider).listPaymentRecords();
});

final superAdminCompanyRollupsProvider =
    FutureProvider.autoDispose<List<SuperAdminCompanyRollup>>((ref) {
  return ref.watch(superAdminRepositoryProvider).getCompanyRollups();
});

final superAdminReportsBundleProvider =
    FutureProvider.autoDispose<SuperAdminReportsBundle>((ref) async {
  final repo = ref.watch(superAdminRepositoryProvider);
  final results = await Future.wait<Object>([
    repo.getDashboard(),
    repo.getCompanyRollups(),
  ]);
  return SuperAdminReportsBundle(
    dashboard: results[0] as SuperAdminDashboard,
    rollups: results[1] as List<SuperAdminCompanyRollup>,
  );
});

class SuperAdminRepository {
  const SuperAdminRepository(this._api);

  final ApiClient _api;

  Future<List<SuperAdminCompany>> listCompanies() async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/super-admin/companies',
    );
    return listValue(data['companies'])
        .map(SuperAdminCompany.fromJson)
        .toList(growable: false);
  }

  Future<SuperAdminCompany> getCompany(String companyId) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/super-admin/companies/$companyId',
    );
    return SuperAdminCompany.fromJson(_object(data, 'company'));
  }

  Future<SuperAdminCompany> createCompany({
    required String name,
    required String status,
    String? contactEmail,
    String? contactPhone,
    String? billingEmail,
    String? address,
    String? country,
    String? timezone,
  }) async {
    final data = await _api.post<Map<String, Object?>>(
      '/api/super-admin/companies',
      body: {
        'name': name.trim(),
        'status': status,
        if (_hasText(contactEmail))
          'contactEmail': contactEmail!.trim().toLowerCase(),
        if (_hasText(contactPhone)) 'contactPhone': contactPhone!.trim(),
        if (_hasText(billingEmail))
          'billingEmail': billingEmail!.trim().toLowerCase(),
        if (_hasText(address)) 'address': address!.trim(),
        if (_hasText(country)) 'country': country!.trim(),
        if (_hasText(timezone)) 'timezone': timezone!.trim(),
      },
    );
    return SuperAdminCompany.fromJson(_object(data, 'company'));
  }

  Future<SuperAdminCompany> updateCompany(
    String companyId, {
    required String name,
    required String? contactEmail,
    required String? contactPhone,
    required String? billingEmail,
    required String? address,
    required String? country,
    required String? timezone,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/super-admin/companies/$companyId',
      body: {
        'name': name.trim(),
        'contactEmail':
            _hasText(contactEmail) ? contactEmail!.trim().toLowerCase() : null,
        'contactPhone': _hasText(contactPhone) ? contactPhone!.trim() : null,
        'billingEmail':
            _hasText(billingEmail) ? billingEmail!.trim().toLowerCase() : null,
        'address': _hasText(address) ? address!.trim() : null,
        'country': _hasText(country) ? country!.trim() : null,
        'timezone': _hasText(timezone) ? timezone!.trim() : null,
      },
    );
    return SuperAdminCompany.fromJson(_object(data, 'company'));
  }

  Future<SuperAdminCompany> updateCompanyStatus(
    String companyId, {
    required String status,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/super-admin/companies/$companyId/status',
      body: {'status': status},
    );
    return SuperAdminCompany.fromJson(_object(data, 'company'));
  }

  Future<List<SuperAdminSubscriptionPlan>> listPlans({
    String? type,
    bool? isActive,
  }) async {
    final query = <String, Object?>{
      if (_hasText(type)) 'type': type,
      if (isActive != null) 'isActive': isActive,
    };
    final data = await _api.get<Map<String, Object?>>(
      '/api/super-admin/plans',
      query: query.isEmpty ? null : query,
    );
    return listValue(data['plans'])
        .map(SuperAdminSubscriptionPlan.fromJson)
        .toList(growable: false);
  }

  Future<SuperAdminSubscriptionPlan> createPlan({
    required String name,
    required String type,
    required double pricePerEmployee,
    required String currency,
    required bool isActive,
  }) async {
    final data = await _api.post<Map<String, Object?>>(
      '/api/super-admin/plans',
      body: {
        'name': name.trim(),
        'type': type,
        'pricePerEmployee': pricePerEmployee,
        'currency': currency.trim().toUpperCase(),
        'isActive': isActive,
      },
    );
    return SuperAdminSubscriptionPlan.fromJson(_object(data, 'plan'));
  }

  Future<SuperAdminSubscriptionPlan> updatePlan(
    String planId, {
    required String name,
    required String type,
    required double pricePerEmployee,
    required String currency,
    required bool isActive,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/super-admin/plans/$planId',
      body: {
        'name': name.trim(),
        'type': type,
        'pricePerEmployee': pricePerEmployee,
        'currency': currency.trim().toUpperCase(),
        'isActive': isActive,
      },
    );
    return SuperAdminSubscriptionPlan.fromJson(_object(data, 'plan'));
  }

  Future<SuperAdminSubscriptionPlan> updatePlanStatus(
    String planId, {
    required bool isActive,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/super-admin/plans/$planId/status',
      body: {'isActive': isActive},
    );
    return SuperAdminSubscriptionPlan.fromJson(_object(data, 'plan'));
  }

  Future<SuperAdminCompanySubscription> createCompanySubscription({
    required String companyId,
    required String planId,
    required String startsAt,
    required String status,
    String? endsAt,
  }) async {
    final data = await _api.post<Map<String, Object?>>(
      '/api/super-admin/companies/$companyId/subscription',
      body: {
        'planId': planId,
        'startsAt': startsAt,
        'endsAt': _hasText(endsAt) ? endsAt!.trim() : null,
        'status': status,
      },
    );
    return SuperAdminCompanySubscription.fromJson(
      _object(data, 'subscription'),
    );
  }

  Future<List<SuperAdminCompanySubscription>> listSubscriptions({
    String? companyId,
    String? planId,
    String? status,
  }) async {
    final query = <String, Object?>{
      if (_hasText(companyId)) 'companyId': companyId,
      if (_hasText(planId)) 'planId': planId,
      if (_hasText(status)) 'status': status,
    };
    final data = await _api.get<Map<String, Object?>>(
      '/api/super-admin/subscriptions',
      query: query.isEmpty ? null : query,
    );
    return listValue(data['subscriptions'])
        .map(SuperAdminCompanySubscription.fromJson)
        .toList(growable: false);
  }

  Future<SuperAdminCompanySubscription?> getCompanySubscription(
    String companyId,
  ) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/super-admin/companies/$companyId/subscription',
    );
    final value = data['subscription'];
    if (value == null) return null;
    return SuperAdminCompanySubscription.fromJson(
      Map<String, Object?>.from(value as Map),
    );
  }

  Future<SuperAdminCompanySubscription> updateSubscriptionStatus(
    String subscriptionId, {
    required String status,
    String? endsAt,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/super-admin/subscriptions/$subscriptionId/status',
      body: {
        'status': status,
        'endsAt': _hasText(endsAt) ? endsAt!.trim() : null,
      },
    );
    return SuperAdminCompanySubscription.fromJson(
      _object(data, 'subscription'),
    );
  }

  Future<SuperAdminPaymentRecord> createPaymentRecord({
    required String companyId,
    required double amount,
    required String currency,
    required String status,
    String? subscriptionId,
    String? provider,
    String? providerReference,
    String? paidAt,
  }) async {
    final data = await _api.post<Map<String, Object?>>(
      '/api/super-admin/payment-records',
      body: {
        'companyId': companyId,
        'subscriptionId': _hasText(subscriptionId) ? subscriptionId : null,
        'amount': amount,
        'currency': currency.trim().toUpperCase(),
        'status': status,
        'provider': _hasText(provider) ? provider!.trim() : null,
        'providerReference':
            _hasText(providerReference) ? providerReference!.trim() : null,
        'paidAt': _hasText(paidAt) ? paidAt!.trim() : null,
      },
    );
    return SuperAdminPaymentRecord.fromJson(_object(data, 'paymentRecord'));
  }

  Future<List<SuperAdminPaymentRecord>> listPaymentRecords({
    String? companyId,
    String? status,
    String? provider,
    String? from,
    String? to,
  }) async {
    final query = <String, Object?>{
      if (_hasText(companyId)) 'companyId': companyId,
      if (_hasText(status)) 'status': status,
      if (_hasText(provider)) 'provider': provider,
      if (_hasText(from)) 'from': from,
      if (_hasText(to)) 'to': to,
    };
    final data = await _api.get<Map<String, Object?>>(
      '/api/super-admin/payment-records',
      query: query.isEmpty ? null : query,
    );
    return listValue(data['paymentRecords'])
        .map(SuperAdminPaymentRecord.fromJson)
        .toList(growable: false);
  }

  Future<List<SuperAdminPaymentRecord>> listCompanyPaymentRecords(
    String companyId,
  ) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/super-admin/companies/$companyId/payment-records',
    );
    return listValue(data['paymentRecords'])
        .map(SuperAdminPaymentRecord.fromJson)
        .toList(growable: false);
  }

  Future<SuperAdminDashboard> getDashboard() async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/super-admin/reports/dashboard',
    );
    return SuperAdminDashboard.fromJson(_object(data, 'dashboard'));
  }

  Future<List<SuperAdminCompanyRollup>> getCompanyRollups() async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/super-admin/reports/companies',
    );
    return listValue(data['companies'])
        .map(SuperAdminCompanyRollup.fromJson)
        .toList(growable: false);
  }
}

Map<String, Object?> _object(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is Map) return Map<String, Object?>.from(value);
  return data;
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
