#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_CORE_WORKFLOW_COMMAND_VALUE="${RUN_CORE_WORKFLOW:-}"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

if [[ -n "$RUN_CORE_WORKFLOW_COMMAND_VALUE" ]]; then
  RUN_CORE_WORKFLOW="$RUN_CORE_WORKFLOW_COMMAND_VALUE"
fi

[[ "${RUN_CORE_WORKFLOW:-false}" == "true" ]] ||
  fail "RUN_CORE_WORKFLOW must be true because this script creates persistent synthetic staging data"

for variable in SUPER_ADMIN_EMAIL SUPER_ADMIN_PASSWORD CORE_ACCOUNT_PASSWORD; do
  require_var "$variable"
done

CORE_EMAIL_DOMAIN="${CORE_EMAIL_DOMAIN:-example.test}"
CORE_COMPANY_PREFIX="${CORE_COMPANY_PREFIX:-Staging Smoke}"
GEOFENCE_LATITUDE="${GEOFENCE_LATITUDE:-9.0301}"
GEOFENCE_LONGITUDE="${GEOFENCE_LONGITUDE:-38.7400}"
GEOFENCE_RADIUS_METERS="${GEOFENCE_RADIUS_METERS:-200}"
SUFFIX="$(date -u +%Y%m%d%H%M%S)-$RANDOM"

COMPANY_ADMIN_EMAIL="company-admin-$SUFFIX@$CORE_EMAIL_DOMAIN"
HR_ADMIN_EMAIL="hr-admin-$SUFFIX@$CORE_EMAIL_DOMAIN"
MANAGER_EMAIL="manager-$SUFFIX@$CORE_EMAIL_DOMAIN"
EMPLOYEE_EMAIL="employee-$SUFFIX@$CORE_EMAIL_DOMAIN"

create_employee() {
  local role="$1"
  local email="$2"
  local employee_code="$3"
  local first_name="$4"
  local last_name="$5"
  local manager_id="${6:-}"
  local body
  local -a fields

  fields=(
    companyId string "$COMPANY_ID"
    email string "$email"
    temporaryPassword string "$CORE_ACCOUNT_PASSWORD"
    firstName string "$first_name"
    lastName string "$last_name"
    employeeCode string "$employee_code"
    role string "$role"
  )

  if [[ -n "$manager_id" ]]; then
    fields+=(managerId string "$manager_id")
  fi

  body="$(json_object "${fields[@]}")"

  api_request POST "/api/admin/employees" "201" "$SUPER_TOKEN" "$body"
  CREATED_EMPLOYEE_ID="$(json_value '.data.employee.id')"
  assert_no_sensitive_keys "$role creation response excludes sensitive keys"
}

info "Confirming the target is staging before creating synthetic data"
api_request GET "/health" "200"
assert_json_eq '.data.environment' "staging" "Core workflow target is explicitly staging"

login_user "SUPER_ADMIN" "$SUPER_ADMIN_EMAIL" "$SUPER_ADMIN_PASSWORD"
SUPER_TOKEN="$LAST_TOKEN"
verify_me_role "SUPER_ADMIN" "SUPER_ADMIN" "$SUPER_TOKEN"

info "Creating isolated synthetic companies"

company_body="$(json_object \
  name string "$CORE_COMPANY_PREFIX $SUFFIX" \
  contactEmail string "smoke-$SUFFIX@$CORE_EMAIL_DOMAIN" \
  country string "Ethiopia" \
  timezone string "Africa/Addis_Ababa")"
api_request POST "/api/super-admin/companies" "201" "$SUPER_TOKEN" "$company_body"
COMPANY_ID="$(json_value '.data.company.id')"

other_company_body="$(json_object \
  name string "$CORE_COMPANY_PREFIX Other $SUFFIX" \
  country string "Ethiopia" \
  timezone string "Africa/Addis_Ababa")"
api_request POST "/api/super-admin/companies" "201" "$SUPER_TOKEN" "$other_company_body"
OTHER_COMPANY_ID="$(json_value '.data.company.id')"

info "Creating synthetic company roles"

create_employee "COMPANY_ADMIN" "$COMPANY_ADMIN_EMAIL" "CA-$SUFFIX" "Staging" "CompanyAdmin"
COMPANY_ADMIN_ID="$CREATED_EMPLOYEE_ID"

create_employee "HR_ADMIN" "$HR_ADMIN_EMAIL" "HR-$SUFFIX" "Staging" "HrAdmin"
HR_ADMIN_ID="$CREATED_EMPLOYEE_ID"

create_employee "MANAGER" "$MANAGER_EMAIL" "MG-$SUFFIX" "Staging" "Manager"
MANAGER_ID="$CREATED_EMPLOYEE_ID"

create_employee "EMPLOYEE" "$EMPLOYEE_EMAIL" "EE-$SUFFIX" "Staging" "Employee" "$MANAGER_ID"
EMPLOYEE_ID="$CREATED_EMPLOYEE_ID"

info "Logging in the new synthetic roles"

login_user "COMPANY_ADMIN" "$COMPANY_ADMIN_EMAIL" "$CORE_ACCOUNT_PASSWORD"
COMPANY_TOKEN="$LAST_TOKEN"
verify_me_role "COMPANY_ADMIN" "COMPANY_ADMIN" "$COMPANY_TOKEN"

login_user "HR_ADMIN" "$HR_ADMIN_EMAIL" "$CORE_ACCOUNT_PASSWORD"
HR_TOKEN="$LAST_TOKEN"
verify_me_role "HR_ADMIN" "HR_ADMIN" "$HR_TOKEN"

login_user "MANAGER" "$MANAGER_EMAIL" "$CORE_ACCOUNT_PASSWORD"
MANAGER_TOKEN="$LAST_TOKEN"
verify_me_role "MANAGER" "MANAGER" "$MANAGER_TOKEN"

login_user "EMPLOYEE" "$EMPLOYEE_EMAIL" "$CORE_ACCOUNT_PASSWORD"
EMPLOYEE_TOKEN="$LAST_TOKEN"
verify_me_role "EMPLOYEE" "EMPLOYEE" "$EMPLOYEE_TOKEN"

info "Verifying core role and company boundaries"
expect_denied "EMPLOYEE admin boundary" GET "/api/admin/employees" "$EMPLOYEE_TOKEN"
expect_denied "COMPANY_ADMIN super-admin boundary" GET "/api/super-admin/plans" "$COMPANY_TOKEN"
expect_denied "HR_ADMIN super-admin boundary" GET "/api/super-admin/plans" "$HR_TOKEN"
expect_denied "MANAGER admin boundary" GET "/api/admin/geofences" "$MANAGER_TOKEN"
expect_denied \
  "COMPANY_ADMIN cross-company boundary" \
  GET \
  "/api/admin/employees?companyId=$OTHER_COMPANY_ID" \
  "$COMPANY_TOKEN"

info "Testing geofence, face verification, and attendance"

geofence_body="$(json_object \
  name string "Smoke HQ $SUFFIX" \
  latitude number "$GEOFENCE_LATITUDE" \
  longitude number "$GEOFENCE_LONGITUDE" \
  radiusMeters number "$GEOFENCE_RADIUS_METERS")"
api_request POST "/api/admin/geofences" "201" "$COMPANY_TOKEN" "$geofence_body"
GEOFENCE_ID="$(json_value '.data.geofence.id')"

api_request \
  POST \
  "/api/admin/employees/$EMPLOYEE_ID/face-enrollment" \
  "201" \
  "$COMPANY_TOKEN" \
  '{"provider":"mock"}'
assert_json_eq '.data.faceEnrollment.status' "ACTIVE" "Employee face enrollment is active"
assert_no_sensitive_keys "Face enrollment response excludes provider internals"

api_request POST "/api/face/verify" "200" "$EMPLOYEE_TOKEN" '{"provider":"mock","verificationReference":"mock-pass"}'
assert_js 'data.data.verified === true' "Employee face verification succeeds"
FACE_REFERENCE="$(json_value '.data.verificationReference')"

clock_in_body="$(json_object \
  latitude number "$GEOFENCE_LATITUDE" \
  longitude number "$GEOFENCE_LONGITUDE" \
  accuracyMeters number "5" \
  faceVerificationReference string "$FACE_REFERENCE")"
api_request POST "/api/attendance/clock-in" "201" "$EMPLOYEE_TOKEN" "$clock_in_body"
assert_json_eq '.data.attendanceSession.status' "OPEN" "Employee clocks in"

clock_out_body="$(json_object \
  latitude number "$GEOFENCE_LATITUDE" \
  longitude number "$GEOFENCE_LONGITUDE" \
  accuracyMeters number "5")"
api_request POST "/api/attendance/clock-out" "200" "$EMPLOYEE_TOKEN" "$clock_out_body"
assert_json_eq '.data.attendanceSession.status' "CLOSED" "Employee clocks out"

info "Testing shift assignment"

shift_body="$(json_object name string "Smoke Shift $SUFFIX" startTime string "09:00" endTime string "17:00")"
api_request POST "/api/admin/shifts" "201" "$COMPANY_TOKEN" "$shift_body"
SHIFT_ID="$(json_value '.data.shift.id')"

assignment_body="$(json_object employeeId string "$EMPLOYEE_ID" startsOn string "2099-01-01")"
api_request POST "/api/admin/shifts/$SHIFT_ID/assign" "201" "$COMPANY_TOKEN" "$assignment_body"
SHIFT_ASSIGNMENT_ID="$(json_value '.data.assignment.id')"

api_request GET "/api/shifts/me" "200" "$EMPLOYEE_TOKEN"
assert_js_arg 'data.data.assignments.some((assignment) => assignment.id === arg)' "$SHIFT_ASSIGNMENT_ID" \
  "Employee can view the assigned shift"

info "Testing leave request and manager approval"

leave_type_body="$(json_object name string "Smoke Leave $SUFFIX" defaultAnnualAllowance number "20")"
api_request POST "/api/admin/leave-types" "201" "$COMPANY_TOKEN" "$leave_type_body"
LEAVE_TYPE_ID="$(json_value '.data.leaveType.id')"

entitlement_body="$(json_object \
  employeeId string "$EMPLOYEE_ID" \
  leaveTypeId string "$LEAVE_TYPE_ID" \
  year number "2099" \
  totalDays number "20" \
  usedDays number "0")"
api_request POST "/api/admin/leave-entitlements" "201" "$COMPANY_TOKEN" "$entitlement_body"

leave_request_body="$(json_object \
  leaveTypeId string "$LEAVE_TYPE_ID" \
  startDate string "2099-02-01" \
  endDate string "2099-02-02" \
  reason string "Synthetic staging smoke test")"
api_request POST "/api/leave/request" "201" "$EMPLOYEE_TOKEN" "$leave_request_body"
LEAVE_REQUEST_ID="$(json_value '.data.leaveRequest.id')"

api_request PATCH "/api/leave/$LEAVE_REQUEST_ID/approve" "200" "$MANAGER_TOKEN" '{"comment":"Synthetic smoke approval"}'
assert_json_eq '.data.leaveRequest.status' "APPROVED" "Manager approves the direct report leave request"

info "Testing OKR assignment and approvals"

okr_body="$(json_object \
  employeeId string "$EMPLOYEE_ID" \
  title string "Smoke OKR $SUFFIX" \
  description string "Synthetic staging objective" \
  dueDate string "2099-12-31")"
api_request POST "/api/okrs" "201" "$MANAGER_TOKEN" "$okr_body"
OKR_ID="$(json_value '.data.okr.id')"

api_request POST "/api/okrs/$OKR_ID/progress" "201" "$EMPLOYEE_TOKEN" '{"progressPercent":50,"note":"Synthetic progress"}'
assert_json_eq '.data.okr.status' "IN_PROGRESS" "Employee updates OKR progress"

api_request PATCH "/api/okrs/$OKR_ID/employee-approve" "200" "$EMPLOYEE_TOKEN" '{"comment":"Synthetic employee approval"}'
assert_json_eq '.data.okr.status' "SUBMITTED" "Employee approves the OKR"

api_request PATCH "/api/okrs/$OKR_ID/manager-approve" "200" "$MANAGER_TOKEN" '{"comment":"Synthetic manager approval"}'
assert_json_eq '.data.okr.status' "APPROVED" "Manager approves the OKR"

info "Testing performance review"

review_cycle_body="$(json_object \
  name string "Smoke Review $SUFFIX" \
  startDate string "2099-01-01" \
  endDate string "2099-12-31")"
api_request POST "/api/admin/review-cycles" "201" "$COMPANY_TOKEN" "$review_cycle_body"
REVIEW_CYCLE_ID="$(json_value '.data.reviewCycle.id')"

api_request PATCH "/api/admin/review-cycles/$REVIEW_CYCLE_ID/status" "200" "$COMPANY_TOKEN" '{"status":"ACTIVE"}'
assert_json_eq '.data.reviewCycle.status' "ACTIVE" "Review cycle is active"

review_body="$(json_object \
  reviewCycleId string "$REVIEW_CYCLE_ID" \
  summary string "Synthetic staging performance review." \
  rating number "4")"
api_request POST "/api/reviews/$EMPLOYEE_ID/manager-review" "201" "$MANAGER_TOKEN" "$review_body"
REVIEW_ID="$(json_value '.data.review.id')"

api_request GET "/api/reviews/me" "200" "$EMPLOYEE_TOKEN"
assert_js_arg 'data.data.reviews.some((review) => review.id === arg)' "$REVIEW_ID" \
  "Employee can view the submitted performance review"

info "Testing notification broadcast and read state"

notification_body="$(json_object \
  title string "Smoke Notification $SUFFIX" \
  message string "Synthetic staging notification." \
  type string "SYSTEM" \
  targetRole string "EMPLOYEE")"
api_request POST "/api/admin/notifications/broadcast" "201" "$COMPANY_TOKEN" "$notification_body"
assert_js 'data.data.notificationCount >= 1' "Admin broadcast reaches at least one employee"
NOTIFICATION_ID="$(json_value '.data.notifications[0].id')"

api_request PATCH "/api/notifications/$NOTIFICATION_ID/read" "200" "$EMPLOYEE_TOKEN" "{}"
assert_json_eq '.data.notification.status' "READ" "Employee marks the notification as read"

info "Testing reports and response privacy"

api_request GET "/api/admin/reports/dashboard" "200" "$COMPANY_TOKEN"
assert_js 'data.data.dashboard && typeof data.data.dashboard === "object"' "Company admin dashboard report loads"
assert_js \
  '!["latitude","longitude","reason","summary","comment","note","providerSubjectId","templateReference"].some((key) => JSON.stringify(data).includes(`"${key}"`))' \
  "Dashboard report excludes raw private workflow fields"

api_request GET "/api/reports/me/dashboard" "200" "$EMPLOYEE_TOKEN"
assert_js 'data.data.dashboard && typeof data.data.dashboard === "object"' "Employee dashboard report loads"

info "Testing subscription plan assignment and company billing views"

plan_body="$(json_object \
  name string "Smoke Basic $SUFFIX" \
  type string "BASIC" \
  pricePerEmployee number "100" \
  currency string "ETB" \
  isActive boolean "true")"
api_request POST "/api/super-admin/plans" "201" "$SUPER_TOKEN" "$plan_body"
PLAN_ID="$(json_value '.data.plan.id')"

subscription_body="$(json_object \
  planId string "$PLAN_ID" \
  startsAt string "2099-01-01" \
  status string "ACTIVE")"
api_request POST "/api/super-admin/companies/$COMPANY_ID/subscription" "201" "$SUPER_TOKEN" "$subscription_body"
SUBSCRIPTION_ID="$(json_value '.data.subscription.id')"

api_request GET "/api/admin/subscription" "200" "$COMPANY_TOKEN"
assert_js_arg 'data.data.subscription.id === arg' "$SUBSCRIPTION_ID" "Company admin can view the assigned subscription"

api_request GET "/api/admin/payment-records" "200" "$COMPANY_TOKEN"
assert_js 'Array.isArray(data.data.paymentRecords)' "Company admin payment history loads"
assert_js '!JSON.stringify(data).includes("\"providerReference\"")' \
  "Company admin payment history excludes provider references"

info "Logging out synthetic sessions"
for token in "$SUPER_TOKEN" "$COMPANY_TOKEN" "$HR_TOKEN" "$MANAGER_TOKEN" "$EMPLOYEE_TOKEN"; do
  api_request POST "/api/auth/logout" "200" "$token" "{}"
done

cat <<EOF

[PASS] Core workflow smoke test completed.
[INFO] Synthetic data remains in staging for frontend verification:
  Company ID:       $COMPANY_ID
  Other company ID: $OTHER_COMPANY_ID
  Geofence ID:      $GEOFENCE_ID
  Company admin:    $COMPANY_ADMIN_EMAIL
  HR admin:         $HR_ADMIN_EMAIL
  Manager:          $MANAGER_EMAIL
  Employee:         $EMPLOYEE_EMAIL

[INFO] Store these emails and CORE_ACCOUNT_PASSWORD in the approved password manager.
EOF
