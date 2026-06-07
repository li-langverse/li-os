#!/usr/bin/env bash
# Phase 1 — build hello_kern freestanding kernel and verify serial output.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

LIC="$(lic_root)"
LIK="$(lik_root)"
require_cmd readelf

BUILD_DIR="${ROOT}/../build"
KERNEL_ELF="${BUILD_DIR}/hello_kern.elf"
mkdir -p "${BUILD_DIR}"
ARTIFACT="${ROOT}/data/gate-artifacts/phase-p0-hello-kern.log"
mkdir -p "$(dirname "${ARTIFACT}")"

{
  echo "phase-p0-freestanding gate"
  echo "lic=${LIC}"
  echo "lik=${LIK}"
  echo "kernel=${KERNEL_ELF}"
} | tee "${ARTIFACT}"

bash "${ROOT}/scripts/gates/check-no-port-caps.sh" 2>&1 | tee -a "${ARTIFACT}"

export LIC_ROOT="${LIC}"
export LIK_ROOT="${LIK}"
export LIOS_KERNEL_ELF="${KERNEL_ELF}"
bash "${LIK}/scripts/build-hello-kern.sh" 2>&1 | tee -a "${ARTIFACT}"

[[ -f "${KERNEL_ELF}" ]] || gate_fail "hello_kern.elf not built at ${KERNEL_ELF}"

bash "${ROOT}/scripts/gates/check-zero-c.sh" "${KERNEL_ELF}" 2>&1 | tee -a "${ARTIFACT}"

SMOKE_LOG="${ROOT}/data/gate-artifacts/hello-kern-smoke.log"
if bash "${LIK}/scripts/smoke-hello-kern.sh" "${KERNEL_ELF}" >"${SMOKE_LOG}" 2>&1; then
  echo "lic smoke-kernel: PASS (see ${SMOKE_LOG})" | tee -a "${ARTIFACT}"
  cat "${SMOKE_LOG}" >> "${ARTIFACT}"
else
  cat "${SMOKE_LOG}" | tee -a "${ARTIFACT}"
  gate_fail "hello_kern serial not verified (lic smoke-kernel failed)"
fi

gate_pass "phase-p0-freestanding (hello_kern built + serial smoke)"
