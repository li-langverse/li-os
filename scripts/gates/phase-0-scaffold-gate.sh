#!/usr/bin/env bash
# Phase 0 — verify li-os scaffold and lic kernel-abi stub exist.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

required=(
  "${ROOT}/README.md"
  "${ROOT}/docs/plans/2026-06-lios-kernel-m1.md"
  "${ROOT}/scripts/dev-vm.sh"
  "${ROOT}/scripts/gates/common.sh"
  "${ROOT}/scripts/gates/m1-progress-gate.sh"
  "${ROOT}/scripts/gates/m1-completion-gate.sh"
  "${ROOT}/scripts/gates/phase-p0-hello-kern-gate.sh"
  "${ROOT}/scripts/gates/phase-p0c-dev-vm-gate.sh"
  "${ROOT}/scripts/gates/check-zero-c.sh"
)

for path in "${required[@]}"; do
  [[ -f "${path}" ]] || gate_fail "missing required file: ${path}"
done

[[ -x "${ROOT}/scripts/dev-vm.sh" ]] || gate_fail "scripts/dev-vm.sh must be executable"

if ! "${ROOT}/scripts/dev-vm.sh" --help >/dev/null 2>&1; then
  gate_fail "scripts/dev-vm.sh --help failed"
fi

LIC="$(lic_root)"
KERNEL_ABI="${LIC}/docs/kernel-abi.md"
[[ -f "${KERNEL_ABI}" ]] || gate_fail "missing lic kernel ABI stub: ${KERNEL_ABI}"

if ! grep -q '@hw' "${KERNEL_ABI}"; then
  gate_fail "docs/kernel-abi.md must mention @hw intrinsics"
fi

if ! grep -q 'freestanding' "${KERNEL_ABI}"; then
  gate_fail "docs/kernel-abi.md must document freestanding target"
fi

gate_pass "phase-0-scaffold (li-os + lic kernel-abi stub)"
