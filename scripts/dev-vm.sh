#!/usr/bin/env bash
# LiOS dev VM — QEMU launcher for kernel smoke tests.
#
# Phase 0: skeleton only (--help, --smoke stub).
# Phase 2: --smoke runs hello_kern on x86_64 serial.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCH="${LIOS_DEV_VM_ARCH:-x86_64}"
SMOKE=0
TIMEOUT_SEC="${LIOS_DEV_VM_TIMEOUT:-30}"
KERNEL_ELF="${LIOS_KERNEL_ELF:-}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--smoke] [--arch x86_64|aarch64] [--kernel PATH] [--timeout SEC]

  --smoke       Run serial smoke test (hello_kern must print on QEMU stdout)
  --arch ARCH   Guest architecture (default: x86_64; also i686, aarch64)
  --kernel PATH Path to freestanding kernel ELF (default: build/hello_kern.elf)
  --timeout SEC QEMU run timeout in seconds (default: 30)
  -h, --help    Show this help

Environment:
  LIC_ROOT          Path to lic checkout (compiler toolchain)
  LIK_ROOT          Path to lik checkout (kernel source + build scripts)
  LIOS_KERNEL_ELF   Override kernel ELF path
  LIOS_DEV_VM_ARCH  Default guest arch
  LIOS_DEV_VM_HOSTFWD  Optional extra hostfwd rules (comma-separated host:guest:proto)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --smoke) SMOKE=1; shift ;;
    --arch) ARCH="$2"; shift 2 ;;
    --kernel) KERNEL_ELF="$2"; shift 2 ;;
    --timeout) TIMEOUT_SEC="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "dev-vm: unknown arg: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ "${SMOKE}" -eq 0 ]]; then
  usage
  exit 0
fi

if [[ -z "${KERNEL_ELF}" ]]; then
  if [[ -f "${ROOT}/../build/hello_kern.elf" ]]; then
    KERNEL_ELF="${ROOT}/../build/hello_kern.elf"
  else
    KERNEL_ELF="${ROOT}/build/hello_kern.elf"
  fi
fi

if [[ ! -f "${KERNEL_ELF}" ]]; then
  echo "dev-vm: kernel ELF not found: ${KERNEL_ELF}" >&2
  echo "dev-vm: implement phase-p0-freestanding (hello_kern) first" >&2
  exit 1
fi

case "${ARCH}" in
  i686|x86_64)
    ;;
  aarch64)
    echo "dev-vm: aarch64 smoke uses lic smoke-kernel when available" >&2
    ;;
  *)
    echo "dev-vm: unsupported arch: ${ARCH}" >&2
    exit 1
    ;;
esac

ARTIFACT_DIR="${ROOT}/data/gate-artifacts"
mkdir -p "${ARTIFACT_DIR}"
LOG="${ARTIFACT_DIR}/dev-vm-smoke-${ARCH}.log"

lic_smoke() {
  local lik="${LIK_ROOT:-}"
  if [[ -z "${lik}" ]]; then
    for candidate in "${ROOT}/../lik" "/workspace/lik"; do
      if [[ -d "${candidate}/.git" ]]; then
        lik="${candidate}"
        break
      fi
    done
  fi
  if [[ -n "${lik}" && -f "${lik}/scripts/smoke-hello-kern.sh" ]]; then
    export LIOS_KERNEL_SMOKE_TIMEOUT="${TIMEOUT_SEC}"
    if bash "${lik}/scripts/smoke-hello-kern.sh" "${KERNEL_ELF}" 2>&1 | tee -a "${LOG}"; then
      echo "dev-vm: PASS — hello_kern seen on serial (lic smoke-kernel)" | tee -a "${LOG}"
      return 0
    fi
  fi
  return 1
}

echo "dev-vm: smoke ${ARCH} kernel=${KERNEL_ELF} timeout=${TIMEOUT_SEC}s" | tee "${LOG}"
lic_smoke || {
  echo "dev-vm: FAIL — expected hello_kern on serial (see ${LOG})" >&2
  exit 1
}
