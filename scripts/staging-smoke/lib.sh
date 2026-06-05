#!/usr/bin/env bash

set -Eeuo pipefail

SMOKE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SMOKE_REPO_ROOT="$(cd "$SMOKE_SCRIPT_DIR/../.." && pwd)"
SMOKE_ENV_FILE="${SMOKE_ENV_FILE:-$SMOKE_SCRIPT_DIR/smoke.env}"

if [[ -f "$SMOKE_ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$SMOKE_ENV_FILE"
  set +a
fi

BASE_URL="${BASE_URL:-https://workforce-management-production.up.railway.app}"
BASE_URL="${BASE_URL%/}"
SMOKE_TMP_DIR="$(mktemp -d)"
LAST_RESPONSE="$SMOKE_TMP_DIR/response.json"
LAST_HEADERS="$SMOKE_TMP_DIR/headers.txt"
LAST_STATUS=""
LAST_TOKEN=""

cleanup_smoke_tmp() {
  rm -rf "$SMOKE_TMP_DIR"
}

trap cleanup_smoke_tmp EXIT

info() {
  printf '[INFO] %s\n' "$*"
}

pass() {
  printf '[PASS] %s\n' "$*"
}

skip() {
  printf '[SKIP] %s\n' "$*"
}

fail() {
  printf '[FAIL] %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command is not installed: $1"
}

require_var() {
  local name="$1"
  [[ -n "${!name:-}" ]] || fail "Required environment variable is missing: $name"
}

show_last_response() {
  if node "$SMOKE_SCRIPT_DIR/json.cjs" sanitize "$LAST_RESPONSE" >&2 2>/dev/null; then
    :
  else
    cat "$LAST_RESPONSE" >&2
  fi
}

api_request() {
  local method="$1"
  local path="$2"
  local expected_statuses="$3"
  local token="${4:-}"
  local body="${5:-__NO_BODY__}"
  local -a args

  args=(
    -sS
    -D "$LAST_HEADERS"
    -o "$LAST_RESPONSE"
    -w "%{http_code}"
    -X "$method"
    "$BASE_URL$path"
    -H "Accept: application/json"
  )

  if [[ -n "$token" ]]; then
    args+=(-H "Authorization: Bearer $token")
  fi

  if [[ "$body" != "__NO_BODY__" ]]; then
    args+=(-H "Content-Type: application/json" --data "$body")
  fi

  LAST_STATUS="$(curl "${args[@]}")" || fail "$method $path could not reach $BASE_URL"

  if [[ " $expected_statuses " != *" $LAST_STATUS "* ]]; then
    printf '[FAIL] %s %s returned HTTP %s; expected one of: %s\n' \
      "$method" "$path" "$LAST_STATUS" "$expected_statuses" >&2
    show_last_response
    exit 1
  fi

  pass "$method $path -> HTTP $LAST_STATUS"
}

json_value() {
  local path="$1"
  node "$SMOKE_SCRIPT_DIR/json.cjs" get "$LAST_RESPONSE" "$path" ||
    fail "Could not read JSON value using: $path"
}

json_object() {
  node "$SMOKE_SCRIPT_DIR/json.cjs" object "$@"
}

assert_js() {
  local expression="$1"
  local message="$2"

  if node "$SMOKE_SCRIPT_DIR/json.cjs" test "$LAST_RESPONSE" "$expression"; then
    pass "$message"
  else
    printf '[FAIL] %s\n' "$message" >&2
    show_last_response
    exit 1
  fi
}

assert_js_arg() {
  local expression="$1"
  local arg_value="$2"
  local message="$3"

  if node "$SMOKE_SCRIPT_DIR/json.cjs" test-arg "$LAST_RESPONSE" "$expression" "$arg_value"; then
    pass "$message"
  else
    printf '[FAIL] %s\n' "$message" >&2
    show_last_response
    exit 1
  fi
}

assert_json_eq() {
  local filter="$1"
  local expected="$2"
  local message="$3"
  local actual

  actual="$(json_value "$filter")"
  [[ "$actual" == "$expected" ]] || fail "$message (expected '$expected', received '$actual')"
  pass "$message"
}

assert_no_sensitive_keys() {
  local message="$1"
  assert_js \
    '!["passwordHash","temporaryPassword","providerSubjectId","templateReference"].some((key) => JSON.stringify(data).includes(`"${key}"`))' \
    "$message"
}

login_user() {
  local label="$1"
  local email="$2"
  local password="$3"
  local body

  body="$(json_object email string "$email" password string "$password")"
  api_request POST "/api/auth/login" "200" "" "$body"
  LAST_TOKEN="$(json_value '.data.accessToken')"
  [[ -n "$LAST_TOKEN" ]] || fail "$label login did not return an access token"
  pass "$label login returned an access token"
}

verify_me_role() {
  local label="$1"
  local role="$2"
  local token="$3"

  api_request GET "/api/auth/me" "200" "$token"
  assert_js_arg 'data.data.user.roles.includes(arg)' "$role" "$label /api/auth/me contains $role"
  assert_no_sensitive_keys "$label /api/auth/me excludes sensitive keys"
}

expect_denied() {
  local label="$1"
  local method="$2"
  local path="$3"
  local token="$4"

  api_request "$method" "$path" "403 404" "$token"
  pass "$label is denied without leaking a successful response"
}

require_command curl
require_command node
