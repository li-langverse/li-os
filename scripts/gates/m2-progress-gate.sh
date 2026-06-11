#!/usr/bin/env bash
# Run the gate for the current M2 phase (reads state.json); advance phase when gate passes.
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

m2_sync_state_copies() {
  local src="$1"
  for dest in \
    "${ROOT}/data/lios-kernel-loop/state.json" \
    "/app/data/lios-kernel-loop/state.json"; do
    if [[ "$dest" != "$src" && -d "$(dirname "$dest")" ]]; then
      cp -f "$src" "$dest" 2>/dev/null || true
    fi
  done
}

m2_advance_state() {
  local current="$1"
  python3 - "${STATE_FILE}" "${current}" <<'PY'
import json, sys
path, phase = sys.argv[1], sys.argv[2]
order = ["m2-qemu-dev-vm", "m2-virtio", "m2-mm"]
data = json.load(open(path, encoding="utf-8"))
if phase == "m2-complete":
    print("m2-complete")
    sys.exit(0)
if phase not in order:
    sys.exit(f"unknown phase for advance: {phase}")
idx = order.index(phase)
next_phase = "m2-complete" if idx == len(order) - 1 else order[idx + 1]
tag_map = {"m2-qemu-dev-vm": "P1", "m2-virtio": "P2", "m2-mm": "P3"}
done = list(data.get("phases_done") or [])
tag = tag_map.get(phase)
if tag and tag not in done:
    done.append(tag)
data["phase"] = next_phase
data["phases_done"] = done
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(next_phase)
PY
}

m2_mark_goal_phase_done() {
  local tag="$1"
  local goal_file="${LI_GOAL_FILE:-}"
  [[ -n "$goal_file" && -f "$goal_file" ]] || return 0
  python3 - "$goal_file" "$tag" <<'PY'
import re, sys
from pathlib import Path
path, tag = Path(sys.argv[1]), sys.argv[2]
text = path.read_text(encoding="utf-8")
row_re = re.compile(
    rf"^(\|\s*\*\*{re.escape(tag)}\*\*\s*\|\s*)(?!(\*\*DONE\*\*))([^|\n]*)(\|.*)$",
    re.M,
)
new_text, n = row_re.subn(rf"\1**DONE** |\3", text, count=1)
if n:
    path.write_text(new_text, encoding="utf-8")
PY
}

case "${phase}" in
  m2-qemu-dev-vm)
    bash "${ROOT}/scripts/gates/phase-m2-qemu-dev-vm-gate.sh"
    next="$(m2_advance_state "${phase}")"
    m2_mark_goal_phase_done "P1"
    m2_sync_state_copies "${STATE_FILE}"
    gate_pass "m2-progress (${phase} → ${next})"
    ;;
  m2-virtio)
    bash "${ROOT}/scripts/gates/phase-m2-virtio-gate.sh"
    next="$(m2_advance_state "${phase}")"
    m2_mark_goal_phase_done "P2"
    m2_sync_state_copies "${STATE_FILE}"
    gate_pass "m2-progress (${phase} → ${next})"
    ;;
  m2-mm)
    bash "${ROOT}/scripts/gates/phase-m2-mm-gate.sh"
    next="$(m2_advance_state "${phase}")"
    m2_mark_goal_phase_done "P3"
    m2_sync_state_copies "${STATE_FILE}"
    gate_pass "m2-progress (${phase} → ${next})"
    ;;
  m2-complete)
    gate_pass "m2-progress (all M2 phases complete)"
    ;;
  *)
    gate_fail "unknown M2 phase in state.json: ${phase} (expected m2-qemu-dev-vm, m2-virtio, m2-mm, or m2-complete)"
    ;;
esac
