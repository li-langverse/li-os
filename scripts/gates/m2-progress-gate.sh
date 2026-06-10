#!/usr/bin/env bash
# Run the gate for the current M2 phase (reads state.json).
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
  m2-qemu-dev-vm)
    bash "${ROOT}/scripts/gates/phase-m2-qemu-dev-vm-gate.sh"
    ;;
  m2-virtio)
    bash "${ROOT}/scripts/gates/phase-m2-virtio-gate.sh"
    ;;
  m2-mm)
    bash "${ROOT}/scripts/gates/phase-m2-mm-gate.sh"
    ;;
  *)
    gate_fail "unknown M2 phase in state.json: ${phase} (expected m2-qemu-dev-vm, m2-virtio, or m2-mm)"
    ;;
esac

gate_pass "m2-progress (${phase})"
