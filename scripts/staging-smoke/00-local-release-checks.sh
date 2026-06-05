#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

export NODE_ENV="${NODE_ENV:-test}"
export DATABASE_URL="${DATABASE_URL:-postgresql://postgres:postgres@localhost:5432/workforce_management?schema=public}"

if [[ "${RUN_NPM_CI:-false}" == "true" ]]; then
  npm ci
else
  printf '[SKIP] RUN_NPM_CI is not true; using currently installed dependencies\n'
fi

npm run prisma:validate
npm run prisma:generate
npm run typecheck
npm run build
npm test

printf '[PASS] Local release checks completed\n'
