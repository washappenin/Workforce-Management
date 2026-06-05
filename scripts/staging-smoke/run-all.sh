#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SCRIPT_DIR/01-infrastructure.sh"
bash "$SCRIPT_DIR/02-auth-and-boundaries.sh"

printf '[SKIP] The data-creating core workflow is intentionally separate.\n'
printf '[INFO] Run it explicitly with: RUN_CORE_WORKFLOW=true bash %s/03-core-workflow.sh\n' "$SCRIPT_DIR"
