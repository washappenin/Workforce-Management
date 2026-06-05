#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

for variable in \
  SUPER_ADMIN_EMAIL SUPER_ADMIN_PASSWORD \
  COMPANY_ADMIN_EMAIL COMPANY_ADMIN_PASSWORD \
  HR_ADMIN_EMAIL HR_ADMIN_PASSWORD \
  MANAGER_EMAIL MANAGER_PASSWORD \
  EMPLOYEE_EMAIL EMPLOYEE_PASSWORD; do
  require_var "$variable"
done

info "Logging in and verifying all five synthetic staging roles"

login_user "SUPER_ADMIN" "$SUPER_ADMIN_EMAIL" "$SUPER_ADMIN_PASSWORD"
SUPER_TOKEN="$LAST_TOKEN"
verify_me_role "SUPER_ADMIN" "SUPER_ADMIN" "$SUPER_TOKEN"

login_user "COMPANY_ADMIN" "$COMPANY_ADMIN_EMAIL" "$COMPANY_ADMIN_PASSWORD"
COMPANY_TOKEN="$LAST_TOKEN"
verify_me_role "COMPANY_ADMIN" "COMPANY_ADMIN" "$COMPANY_TOKEN"

login_user "HR_ADMIN" "$HR_ADMIN_EMAIL" "$HR_ADMIN_PASSWORD"
HR_TOKEN="$LAST_TOKEN"
verify_me_role "HR_ADMIN" "HR_ADMIN" "$HR_TOKEN"

login_user "MANAGER" "$MANAGER_EMAIL" "$MANAGER_PASSWORD"
MANAGER_TOKEN="$LAST_TOKEN"
verify_me_role "MANAGER" "MANAGER" "$MANAGER_TOKEN"

login_user "EMPLOYEE" "$EMPLOYEE_EMAIL" "$EMPLOYEE_PASSWORD"
EMPLOYEE_TOKEN="$LAST_TOKEN"
verify_me_role "EMPLOYEE" "EMPLOYEE" "$EMPLOYEE_TOKEN"

info "Verifying role boundaries"

expect_denied "EMPLOYEE admin route boundary" GET "/api/admin/employees" "$EMPLOYEE_TOKEN"
expect_denied "COMPANY_ADMIN super-admin route boundary" GET "/api/super-admin/plans" "$COMPANY_TOKEN"
expect_denied "HR_ADMIN super-admin route boundary" GET "/api/super-admin/plans" "$HR_TOKEN"
expect_denied "MANAGER admin setup route boundary" GET "/api/admin/geofences" "$MANAGER_TOKEN"

api_request GET "/api/super-admin/reports/dashboard" "200" "$SUPER_TOKEN"
assert_js 'data.data.dashboard && typeof data.data.dashboard === "object"' "SUPER_ADMIN can access the super-admin dashboard"

if [[ -n "${OTHER_COMPANY_ID:-}" ]]; then
  expect_denied \
    "COMPANY_ADMIN cross-company boundary" \
    GET \
    "/api/admin/employees?companyId=$OTHER_COMPANY_ID" \
    "$COMPANY_TOKEN"
else
  skip "OTHER_COMPANY_ID is empty; cross-company boundary verification was not run"
fi

info "Logging out each role and confirming session revocation"

for entry in \
  "SUPER_ADMIN:$SUPER_TOKEN" \
  "COMPANY_ADMIN:$COMPANY_TOKEN" \
  "HR_ADMIN:$HR_TOKEN" \
  "MANAGER:$MANAGER_TOKEN" \
  "EMPLOYEE:$EMPLOYEE_TOKEN"; do
  label="${entry%%:*}"
  token="${entry#*:}"
  api_request POST "/api/auth/logout" "200" "$token" "{}"
  api_request GET "/api/auth/me" "401" "$token"
  pass "$label logout revoked the tested session"
done

pass "Authentication and role-boundary smoke tests completed"
