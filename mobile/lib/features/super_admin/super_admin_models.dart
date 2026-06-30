class SuperAdminCompany {
  const SuperAdminCompany({
    required this.id,
    required this.name,
    required this.status,
    this.contactEmail,
    this.contactPhone,
    this.billingEmail,
    this.address,
    this.country,
    this.timezone,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String status;
  final String? contactEmail;
  final String? contactPhone;
  final String? billingEmail;
  final String? address;
  final String? country;
  final String? timezone;
  final String? createdAt;
  final String? updatedAt;

  bool get isActive => status == 'ACTIVE';

  factory SuperAdminCompany.fromJson(Map<String, Object?> json) {
    return SuperAdminCompany(
      id: stringValue(json['id']),
      name: stringValue(json['name'], fallback: 'Company'),
      status: stringValue(json['status'], fallback: 'INACTIVE'),
      contactEmail: optionalString(json['contactEmail']),
      contactPhone: optionalString(json['contactPhone']),
      billingEmail: optionalString(json['billingEmail']),
      address: optionalString(json['address']),
      country: optionalString(json['country']),
      timezone: optionalString(json['timezone']),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
    );
  }
}

class SuperAdminCompanyRef {
  const SuperAdminCompanyRef({
    required this.id,
    required this.name,
    required this.status,
  });

  final String id;
  final String name;
  final String status;

  factory SuperAdminCompanyRef.fromJson(Map<String, Object?> json) {
    return SuperAdminCompanyRef(
      id: stringValue(json['id']),
      name: stringValue(json['name'], fallback: 'Company'),
      status: stringValue(json['status'], fallback: 'INACTIVE'),
    );
  }
}

class SuperAdminSubscriptionPlan {
  const SuperAdminSubscriptionPlan({
    required this.id,
    required this.name,
    required this.type,
    required this.pricePerEmployee,
    required this.currency,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String type;
  final double pricePerEmployee;
  final String currency;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  factory SuperAdminSubscriptionPlan.fromJson(Map<String, Object?> json) {
    return SuperAdminSubscriptionPlan(
      id: stringValue(json['id']),
      name: stringValue(json['name'], fallback: 'Plan'),
      type: stringValue(json['type'], fallback: 'BASIC'),
      pricePerEmployee: doubleValue(json['pricePerEmployee']),
      currency: stringValue(json['currency'], fallback: 'USD'),
      isActive: boolValue(json['isActive'], fallback: true),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
    );
  }
}

class SuperAdminCompanySubscription {
  const SuperAdminCompanySubscription({
    required this.id,
    required this.companyId,
    required this.planId,
    required this.status,
    required this.startsAt,
    this.endsAt,
    this.createdAt,
    this.updatedAt,
    this.plan,
    this.company,
  });

  final String id;
  final String companyId;
  final String planId;
  final String status;
  final String startsAt;
  final String? endsAt;
  final String? createdAt;
  final String? updatedAt;
  final SuperAdminSubscriptionPlan? plan;
  final SuperAdminCompanyRef? company;

  bool get isCurrent => status == 'ACTIVE' || status == 'TRIALING';

  factory SuperAdminCompanySubscription.fromJson(Map<String, Object?> json) {
    final plan = objectValue(json['plan']);
    final company = objectValue(json['company']);
    return SuperAdminCompanySubscription(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      planId: stringValue(json['planId']),
      status: stringValue(json['status'], fallback: 'EXPIRED'),
      startsAt: stringValue(json['startsAt']),
      endsAt: optionalString(json['endsAt']),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
      plan: plan == null ? null : SuperAdminSubscriptionPlan.fromJson(plan),
      company: company == null ? null : SuperAdminCompanyRef.fromJson(company),
    );
  }
}

class SuperAdminPaymentRecord {
  const SuperAdminPaymentRecord({
    required this.id,
    required this.companyId,
    required this.amount,
    required this.currency,
    required this.status,
    this.subscriptionId,
    this.provider,
    this.providerReference,
    this.paidAt,
    this.createdAt,
    this.updatedAt,
    this.company,
    this.subscription,
  });

  final String id;
  final String companyId;
  final String? subscriptionId;
  final double amount;
  final String currency;
  final String status;
  final String? provider;
  final String? providerReference;
  final String? paidAt;
  final String? createdAt;
  final String? updatedAt;
  final SuperAdminCompanyRef? company;
  final SuperAdminCompanySubscription? subscription;

  factory SuperAdminPaymentRecord.fromJson(Map<String, Object?> json) {
    final company = objectValue(json['company']);
    final subscription = objectValue(json['subscription']);
    return SuperAdminPaymentRecord(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      subscriptionId: optionalString(json['subscriptionId']),
      amount: doubleValue(json['amount']),
      currency: stringValue(json['currency'], fallback: 'USD'),
      status: stringValue(json['status'], fallback: 'PENDING'),
      provider: optionalString(json['provider']),
      providerReference: optionalString(json['providerReference']),
      paidAt: optionalString(json['paidAt']),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
      company: company == null ? null : SuperAdminCompanyRef.fromJson(company),
      subscription: subscription == null
          ? null
          : SuperAdminCompanySubscription.fromJson(subscription),
    );
  }
}

class SuperAdminDashboard {
  const SuperAdminDashboard({
    required this.totalCompanies,
    required this.activeCompanies,
    required this.inactiveCompanies,
    required this.totalUsers,
    required this.activeUsers,
    required this.totalSubscriptions,
    required this.recentCompanyCount,
  });

  final int totalCompanies;
  final int activeCompanies;
  final int inactiveCompanies;
  final int totalUsers;
  final int activeUsers;
  final int totalSubscriptions;
  final int recentCompanyCount;

  factory SuperAdminDashboard.fromJson(Map<String, Object?> json) {
    return SuperAdminDashboard(
      totalCompanies: intValue(json['totalCompanies']),
      activeCompanies: intValue(json['activeCompanies']),
      inactiveCompanies: intValue(json['inactiveCompanies']),
      totalUsers: intValue(json['totalUsers']),
      activeUsers: intValue(json['activeUsers']),
      totalSubscriptions: intValue(json['totalSubscriptions']),
      recentCompanyCount: intValue(json['recentCompanyCount']),
    );
  }
}

class SuperAdminCompanyRollup {
  const SuperAdminCompanyRollup({
    required this.companyId,
    required this.name,
    required this.status,
    required this.employeeCount,
    required this.activeEmployeeCount,
    this.subscriptionStatus,
    this.createdAt,
  });

  final String companyId;
  final String name;
  final String status;
  final int employeeCount;
  final int activeEmployeeCount;
  final String? subscriptionStatus;
  final String? createdAt;

  factory SuperAdminCompanyRollup.fromJson(Map<String, Object?> json) {
    return SuperAdminCompanyRollup(
      companyId: stringValue(json['companyId']),
      name: stringValue(json['name'], fallback: 'Company'),
      status: stringValue(json['status'], fallback: 'INACTIVE'),
      employeeCount: intValue(json['employeeCount']),
      activeEmployeeCount: intValue(json['activeEmployeeCount']),
      subscriptionStatus: optionalString(json['subscriptionStatus']),
      createdAt: optionalString(json['createdAt']),
    );
  }
}

class SuperAdminReportsBundle {
  const SuperAdminReportsBundle({
    required this.dashboard,
    required this.rollups,
  });

  final SuperAdminDashboard dashboard;
  final List<SuperAdminCompanyRollup> rollups;
}

Map<String, Object?>? objectValue(Object? value) {
  if (value is Map) return Map<String, Object?>.from(value);
  return null;
}

List<Map<String, Object?>> listValue(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, Object?>.from(item))
      .toList(growable: false);
}

String stringValue(Object? value, {String fallback = ''}) {
  final parsed = optionalString(value);
  return parsed == null || parsed.isEmpty ? fallback : parsed;
}

String? optionalString(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.trim().isEmpty ? null : text;
}

int intValue(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double doubleValue(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

bool boolValue(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  return fallback;
}
