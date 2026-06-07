#!/usr/bin/env bash
# Phase 2 — dev-vm.sh --smoke for x86_64 guest (+ optional aarch64 row).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

LIC="$(lic_root)"
LIK="$(lik_root)"
require_cmd python3

BUILD_DIR="${ROOT}/../build"
KERNEL_ELF="${BUILD_DIR}/hello_kern.elf"
mkdir -p "${BUILD_DIR}"
ARTIFACT="${ROOT}/data/gate-artifacts/phase-p0c-dev-vm.log"
mkdir -p "$(dirname "${ARTIFACT}")"

CI_STUB="${ROOT}/scripts/ci/m1-kernel-smoke.sh"
[[ -f "${CI_STUB}" ]] || gate_fail "missing CI stub: ${CI_STUB}"
[[ -x "${CI_STUB}" ]] || gate_fail "CI stub must be executable: ${CI_STUB}"

{
  echo "phase-p0c-dev-vm gate"
  echo "lic=${LIC}"
  echo "lik=${LIK}"
  echo "kernel=${KERNEL_ELF}"
  echo "ci_stub=${CI_STUB}"
} | tee "${ARTIFACT}"

export LIC_ROOT="${LIC}"
export LIK_ROOT="${LIK}"
export LIOS_KERNEL_ELF="${KERNEL_ELF}"

bash "${LIK}/scripts/build-hello-kern.sh" 2>&1 | tee -a "${ARTIFACT}"
[[ -f "${KERNEL_ELF}" ]] || gate_fail "hello_kern.elf not built at ${KERNEL_ELF}"

if ! bash "${ROOT}/scripts/dev-vm.sh" --smoke --arch x86_64 --kernel "${KERNEL_ELF}" 2>&1 | tee -a "${ARTIFACT}"; then
  gate_fail "dev-vm.sh --smoke x86_64 failed"
fi

DEV_VM_LOG="${ROOT}/data/gate-artifacts/dev-vm-smoke-x86_64.log"
[[ -f "${DEV_VM_LOG}" ]] || gate_fail "missing dev-vm smoke log: ${DEV_VM_LOG}"
grep -q 'hello_kern' "${DEV_VM_LOG}" || gate_fail "dev-vm log missing hello_kern serial output"

# CI stub dry-run (scaffold gate + dev-vm --help).
bash "${CI_STUB}" --check 2>&1 | tee -a "${ARTIFACT}"

# Optional aarch64 row — document skip when no guest kernel is built yet.
AARCH64_LOG="${ROOT}/data/gate-artifacts/dev-vm-smoke-aarch64.log"
if [[ -f "${LIOS_KERNEL_ELF_AARCH64:-}" ]]; then
  bash "${ROOT}/scripts/dev-vm.sh" --smoke --arch aarch64 --kernel "${LIOS_KERNEL_ELF_AARCH64}" \
    2>&1 | tee -a "${ARTIFACT}" || gate_fail "dev-vm.sh --smoke aarch64 failed"
else
  echo "aarch64 smoke: skipped (set LIOS_KERNEL_ELF_AARCH64 to enable optional row)" | tee -a "${ARTIFACT}"
  echo "aarch64 smoke: skipped (optional M1 row)" >"${AARCH64_LOG}"
fi

gate_pass "phase-p0c-dev-vm (dev-vm.sh --smoke x86_64 + CI stub)"
