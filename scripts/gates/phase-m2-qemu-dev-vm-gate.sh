#!/usr/bin/env bash
# M2 P1: QEMU x86_64 dev-vm smoke (qemu-system-x86_64 -kernel hello_kern.elf).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

gate_export_roots
LIK="${LIK_ROOT}"

BUILD_DIR="${ROOT}/../build"
KERNEL_ELF="${BUILD_DIR}/hello_kern.elf"
mkdir -p "${BUILD_DIR}"
ARTIFACT="${ROOT}/data/gate-artifacts/phase-m2-qemu-dev-vm.log"
DEV_VM_LOG="${ROOT}/data/gate-artifacts/dev-vm-qemu-smoke-x86_64.log"
mkdir -p "$(dirname "${ARTIFACT}")"

require_cmd qemu-system-x86_64 || gate_fail "qemu-system-x86_64 not installed"

{
  echo "phase-m2-qemu-dev-vm gate"
  echo "lic=${LIC_ROOT}"
  echo "lik=${LIK}"
  echo "kernel=${KERNEL_ELF}"
} | tee "${ARTIFACT}"

export LIOS_KERNEL_ELF="${KERNEL_ELF}"
export LIOS_DEV_VM_ENGINE=qemu

bash "${LIK}/scripts/build-hello-kern.sh" 2>&1 | tee -a "${ARTIFACT}"
[[ -f "${KERNEL_ELF}" ]] || gate_fail "hello_kern.elf not built at ${KERNEL_ELF}"

if ! bash "${ROOT}/scripts/dev-vm.sh" --smoke --engine qemu --arch x86_64 --kernel "${KERNEL_ELF}" \
  2>&1 | tee -a "${ARTIFACT}"; then
  gate_fail "dev-vm.sh --smoke --engine qemu x86_64 failed"
fi

[[ -f "${DEV_VM_LOG}" ]] || gate_fail "missing QEMU dev-vm smoke log: ${DEV_VM_LOG}"
grep -q 'hello_kern' "${DEV_VM_LOG}" || gate_fail "QEMU dev-vm log missing hello_kern serial output"
grep -q 'PASS — hello_kern seen on serial (qemu-system-x86_64)' "${DEV_VM_LOG}" \
  || gate_fail "QEMU dev-vm log missing qemu PASS marker"

gate_pass "phase-m2-qemu-dev-vm (dev-vm.sh --smoke --engine qemu x86_64)"
