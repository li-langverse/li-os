#!/usr/bin/env bash
# M2 P3: physical memory map + bump allocator in lik (lic smoke-kernel --stub mm-bump).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

gate_export_roots
LIK="${LIK_ROOT}"

BUILD_DIR="${ROOT}/../build"
KERNEL_ELF="${BUILD_DIR}/mm_bump_kern.elf"
mkdir -p "${BUILD_DIR}"
ARTIFACT="${ROOT}/data/gate-artifacts/phase-m2-mm.log"
mkdir -p "$(dirname "${ARTIFACT}")"

{
  echo "phase-m2-mm gate"
  echo "lic=${LIC_ROOT}"
  echo "lik=${LIK}"
  echo "kernel=${KERNEL_ELF}"
} | tee "${ARTIFACT}"

export LIOS_MM_BUMP_ELF="${KERNEL_ELF}"

bash "${LIK}/scripts/build-mm-bump-kern.sh" 2>&1 | tee -a "${ARTIFACT}"
[[ -f "${KERNEL_ELF}" ]] || gate_fail "mm_bump_kern.elf not built at ${KERNEL_ELF}"

if ! bash "${LIK}/scripts/smoke-mm-bump-kern.sh" "${KERNEL_ELF}" 2>&1 | tee -a "${ARTIFACT}"; then
  gate_fail "smoke-mm-bump-kern.sh failed"
fi

grep -q 'mm:bump:ok' "${ARTIFACT}" \
  || gate_fail "mm bump smoke log missing mm:bump:ok serial marker"
grep -q 'smoke-kernel: PASS' "${ARTIFACT}" \
  || gate_fail "mm bump smoke log missing smoke-kernel PASS marker"

gate_pass "phase-m2-mm (physmap + bump allocator via lic smoke-kernel)"
