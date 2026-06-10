#!/usr/bin/env bash
# M1 completion — all phase gates must pass.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

bash "${ROOT}/scripts/gates/phase-0-scaffold-gate.sh"
bash "${ROOT}/scripts/gates/phase-p0-hello-kern-gate.sh"
bash "${ROOT}/scripts/gates/phase-p0c-dev-vm-gate.sh"

gate_pass "m1-completion (all phases)"
