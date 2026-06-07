#!/usr/bin/env bash
# Phase 1 — build hello_kern freestanding kernel and verify serial output.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

LIC="$(lic_root)"
LIK="$(lik_root)"
require_cmd python3
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

# QEMU serial smoke (preferred when multiboot -kernel works).
QEMU_OK=0
if command -v qemu-system-x86_64 >/dev/null 2>&1 || [[ -x /opt/qemu/usr/libexec/qemu-system-i386 ]]; then
  export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"
  export PATH="/opt/qemu/usr/bin:${PATH}"
  QEMU_BIN=""
  for candidate in qemu-system-i386 /opt/qemu/usr/libexec/qemu-system-i386 qemu-system-x86_64; do
    if command -v "${candidate}" >/dev/null 2>&1; then
      QEMU_BIN="$(command -v "${candidate}")"
      break
    fi
    if [[ -x "${candidate}" ]]; then
      QEMU_BIN="${candidate}"
      break
    fi
  done
  if [[ -n "${QEMU_BIN}" ]]; then
    QEMU_LOG="${ROOT}/data/gate-artifacts/hello-kern-qemu.log"
    set +e
    timeout 10 "${QEMU_BIN}" -display none \
      -chardev stdio,id=s0 -device isa-serial,chardev=s0,iobase=0x3f8,irq=4 \
      -kernel "${KERNEL_ELF}" >"${QEMU_LOG}" 2>&1
    QEMU_RC=$?
    set -e
    if grep -q 'hello_kern' "${QEMU_LOG}"; then
      echo "QEMU serial: PASS (see ${QEMU_LOG})" | tee -a "${ARTIFACT}"
      QEMU_OK=1
    else
      echo "QEMU serial: skipped/fail rc=${QEMU_RC} (see ${QEMU_LOG})" | tee -a "${ARTIFACT}"
    fi
  fi
fi

# Unicorn @hw outb serial smoke (validates freestanding codegen path).
UNICORN_LOG="${ROOT}/data/gate-artifacts/hello-kern-unicorn.log"
if python3 "${LIK}/scripts/hello-kern-serial-smoke.py" "${KERNEL_ELF}" >"${UNICORN_LOG}" 2>&1; then
  echo "Unicorn serial: PASS (see ${UNICORN_LOG})" | tee -a "${ARTIFACT}"
  UNICORN_OK=1
else
  cat "${UNICORN_LOG}" | tee -a "${ARTIFACT}"
  UNICORN_OK=0
fi

if [[ "${QEMU_OK}" -eq 0 && "${UNICORN_OK:-0}" -eq 0 ]]; then
  gate_fail "hello_kern serial not verified (QEMU and Unicorn smoke failed)"
fi

gate_pass "phase-p0-freestanding (hello_kern built + serial smoke)"
