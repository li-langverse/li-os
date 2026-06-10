#!/usr/bin/env bash
# Phase 0 — verify li-os scaffold and lik kernel ABI docs exist.
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

LIK="$(lik_root)"
lic_root >/dev/null

KERNEL_ABI="${LIK}/docs/kernel-abi.md"
DEVICE_PORTS="${LIK}/docs/device-ports.md"
[[ -f "${KERNEL_ABI}" ]] || gate_fail "missing lik kernel ABI: ${KERNEL_ABI}"
[[ -f "${DEVICE_PORTS}" ]] || gate_fail "missing lik device-ports policy: ${DEVICE_PORTS}"

grep -q '@hw' "${KERNEL_ABI}" || gate_fail "kernel-abi.md must mention @hw intrinsics"
grep -q 'freestanding' "${KERNEL_ABI}" || gate_fail "kernel-abi.md must document freestanding target"
grep -q 'unlimited' "${DEVICE_PORTS}" || gate_fail "device-ports.md must document unlimited port policy"

[[ -f "${LIK}/scripts/build-hello-kern.sh" ]] || gate_fail "missing lik/scripts/build-hello-kern.sh"

gate_pass "phase-0-scaffold (li-os + lik docs + lic toolchain)"
