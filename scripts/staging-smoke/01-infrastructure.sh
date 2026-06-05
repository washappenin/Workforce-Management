#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

EXPECTED_ENVIRONMENT="${EXPECTED_ENVIRONMENT:-staging}"

info "Testing public infrastructure at $BASE_URL"

api_request GET "/health" "200"
assert_json_eq '.data.status' "ok" "Health status is ok"
assert_json_eq '.data.environment' "$EXPECTED_ENVIRONMENT" "Health reports the expected environment"
assert_js 'typeof data.meta.requestId === "string" && data.meta.requestId.length > 0' "Health response includes a request ID"

api_request GET "/ready" "200"
assert_json_eq '.data.status' "ready" "Readiness status is ready"
assert_json_eq '.data.checks.database.status' "connected" "Readiness confirms the database is connected"
assert_js 'typeof data.meta.requestId === "string" && data.meta.requestId.length > 0' "Readiness response includes a request ID"

if [[ "$EXPECTED_ENVIRONMENT" == "production" ]]; then
  api_request GET "/api/system/auth-check" "404"
  pass "Internal verification routes are hidden in production"
else
  api_request GET "/api/system/auth-check" "401"
  assert_json_eq '.error.code' "UNAUTHENTICATED" "Internal verification route is auth-protected"
fi

if [[ -n "${FRONTEND_ORIGIN:-}" ]]; then
  info "Checking CORS preflight for $FRONTEND_ORIGIN"
  cors_headers="$SMOKE_TMP_DIR/cors-headers.txt"
  cors_status="$(
    curl -sS -D "$cors_headers" -o /dev/null -w "%{http_code}" \
      -X OPTIONS "$BASE_URL/api/auth/login" \
      -H "Origin: $FRONTEND_ORIGIN" \
      -H "Access-Control-Request-Method: POST" \
      -H "Access-Control-Request-Headers: authorization,content-type"
  )"

  [[ " 200 204 " == *" $cors_status "* ]] || fail "CORS preflight returned HTTP $cors_status"
  grep -Fiq "access-control-allow-origin: $FRONTEND_ORIGIN" "$cors_headers" ||
    fail "CORS response did not allow $FRONTEND_ORIGIN"
  pass "CORS allows the configured frontend origin"
else
  skip "FRONTEND_ORIGIN is empty; CORS origin verification was not run"
fi

pass "Infrastructure smoke tests completed"
