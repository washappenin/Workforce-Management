# SUBSCRIPTION AND BILLING RULES

Rules for the internal subscription and billing foundation. Implemented at Checkpoint 15.

## Scope

- CP15 supports Basic and Premium subscription plans.
- Pricing is stored as `pricePerEmployee` and `currency`.
- Company subscriptions link a company to one plan with a status, start date, and optional end date.
- Payment records are manual history records only.
- CP15 does not collect money, charge cards, generate invoices, run automated billing jobs, or integrate accounting systems.

## Plans

- `SUPER_ADMIN` can create, list, view, update, and activate/deactivate plans.
- Supported plan types are `BASIC` and `PREMIUM`.
- `name`, `type`, `pricePerEmployee`, and `currency` are required for plan creation.
- `pricePerEmployee` must be non-negative.
- `currency` must be an uppercase 3-letter code.
- Deactivating a plan does not delete or rewrite historical subscriptions.
- Duplicate plan names are rejected.

## Company Subscriptions

- `SUPER_ADMIN` can assign a subscription to a company and update subscription status.
- `companyId` must reference an existing company.
- `planId` must reference an active plan.
- `startsAt` is required; `endsAt` is optional.
- `endsAt` cannot be before `startsAt`.
- Supported statuses are `TRIALING`, `ACTIVE`, `PAST_DUE`, `CANCELLED`, and `EXPIRED`.
- CP15 rejects creation of a second `ACTIVE` subscription for the same company with `ACTIVE_SUBSCRIPTION_EXISTS`.
- CP15 does not automatically end an existing active subscription when a new one is requested.

## Payment Records

- `SUPER_ADMIN` can create and list manual payment records.
- Payment records may be linked to a subscription.
- If `subscriptionId` is provided, it must belong to the same company as the payment record.
- `amount` must be non-negative.
- `currency` must be an uppercase 3-letter code.
- Supported statuses are `PENDING`, `PAID`, `FAILED`, `REFUNDED`, and `CANCELLED`.
- `provider` and `providerReference` are optional manual metadata fields.
- CP15 does not store card numbers, bank account numbers, raw payment instruments, Stripe secrets, or payment credentials.
- Provider references must not be written to audit metadata.

## Company Admin Self-View

- `COMPANY_ADMIN` and `HR_ADMIN` can view their own company subscription and payment records.
- `MANAGER` and `EMPLOYEE` cannot view billing endpoints.
- `SUPER_ADMIN` uses super-admin billing endpoints, not company-admin self-view endpoints.
- Company-admin payment responses omit `providerReference`.
- Non-super-admin `companyId` overrides are rejected.

## Future Scope

- Live Stripe or payment-provider charging is future work.
- Webhooks are future work.
- Invoice PDFs are future work.
- Tax, refunds, proration, coupons, metered billing, automated billing jobs, and accounting integrations are future work.
