#!/usr/bin/env bash
# Run the gate for the current M1 phase (reads state.json).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

STATE_FILE="${LIOS_KERNEL_STATE:-}"
if [[ -z "${STATE_FILE}" ]]; then
  for candidate in \
    "${ROOT}/data/lios-kernel-loop/state.json" \
    "/workspace/lios-kernel-loop/state.json" \
    "/app/data/lios-kernel-loop/state.json"; do
    if [[ -f "${candidate}" ]]; then
      STATE_FILE="${candidate}"
      break
    fi
  done
fi

if [[ -z "${STATE_FILE}" || ! -f "${STATE_FILE}" ]]; then
  gate_fail "state.json not found (set LIOS_KERNEL_STATE)"
fi

phase="$(python3 - "${STATE_FILE}" <<'PY'
import json, sys
print(json.load(open(sys.argv[1], encoding="utf-8")).get("phase", ""))
PY
)"

case "${phase}" in
  phase-0-scaffold)
    bash "${ROOT}/scripts/gates/phase-0-scaffold-gate.sh"
    ;;
  phase-p0-freestanding)
    bash "${ROOT}/scripts/gates/phase-p0-hello-kern-gate.sh"
    ;;
  phase-p0c-dev-vm)
    bash "${ROOT}/scripts/gates/phase-p0c-dev-vm-gate.sh"
    ;;
  m1-complete)
    bash "${ROOT}/scripts/gates/m1-completion-gate.sh"
    ;;
  *)
    gate_fail "unknown phase in state.json: ${phase}"
    ;;
esac

gate_pass "m1-progress (${phase})"
