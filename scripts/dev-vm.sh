#!/usr/bin/env bash
# LiOS dev VM — kernel smoke via lic (M1) or QEMU x86_64 (M2).
#
# Phase 0: skeleton only (--help, --smoke stub).
# Phase 2 (M1): --smoke runs hello_kern on x86_64 serial via lic smoke-kernel.
# M2: --smoke --engine qemu boots multiboot hello_kern under qemu-system-x86_64.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCH="${LIOS_DEV_VM_ARCH:-x86_64}"
ENGINE="${LIOS_DEV_VM_ENGINE:-lic}"
SMOKE=0
TIMEOUT_SEC="${LIOS_DEV_VM_TIMEOUT:-30}"
KERNEL_ELF="${LIOS_KERNEL_ELF:-}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--smoke] [--engine lic|qemu] [--arch x86_64|aarch64] [--kernel PATH] [--timeout SEC]

  --smoke       Run serial smoke test (hello_kern on COM1)
  --engine ENG  Smoke backend: lic (in-process @hw, M1 default) or qemu (M2)
  --arch ARCH   Guest architecture hint (default: x86_64; smoke uses i686 ELF)
  --kernel PATH Path to freestanding kernel ELF (default: build/hello_kern.elf)
  --timeout SEC Smoke timeout in seconds (default: 30)
  -h, --help    Show this help

Environment:
  LIC_ROOT              Path to lic checkout (compiler toolchain)
  LIK_ROOT              Path to lik checkout (kernel source + build scripts)
  LIOS_KERNEL_ELF       Override kernel ELF path
  LIOS_DEV_VM_ARCH      Default guest arch
  LIOS_DEV_VM_ENGINE    Default smoke engine (lic|qemu)
  LIOS_DEV_VM_HOSTFWD   Optional extra hostfwd rules (comma-separated host:guest:proto)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --smoke) SMOKE=1; shift ;;
    --engine) ENGINE="$2"; shift 2 ;;
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

case "${ENGINE}" in
  lic|qemu)
    ;;
  *)
    echo "dev-vm: unsupported engine: ${ENGINE} (expected lic or qemu)" >&2
    exit 1
    ;;
esac

ARTIFACT_DIR="${ROOT}/data/gate-artifacts"
mkdir -p "${ARTIFACT_DIR}"
if [[ "${ENGINE}" == "qemu" ]]; then
  LOG="${ARTIFACT_DIR}/dev-vm-qemu-smoke-${ARCH}.log"
else
  LOG="${ARTIFACT_DIR}/dev-vm-smoke-${ARCH}.log"
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "dev-vm: required command missing: $1" >&2
    return 1
  fi
}

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

qemu_smoke() {
  require_cmd qemu-system-x86_64 || return 1

  local -a run_cmd=()
  if command -v timeout >/dev/null 2>&1; then
    run_cmd=(timeout --kill-after=5 "${TIMEOUT_SEC}")
  elif command -v gtimeout >/dev/null 2>&1; then
    run_cmd=(gtimeout --kill-after=5 "${TIMEOUT_SEC}")
  fi

  local -a qemu_args=(
    qemu-system-x86_64
    -machine pc
    -cpu qemu32
    -m 128M
    -kernel "${KERNEL_ELF}"
    -serial mon:stdio
    -display none
    -no-reboot
  )

  echo "dev-vm: qemu ${qemu_args[*]}" | tee -a "${LOG}"
  set +e
  if [[ ${#run_cmd[@]} -gt 0 ]]; then
    "${run_cmd[@]}" "${qemu_args[@]}" 2>&1 | tee -a "${LOG}"
    local rc=${PIPESTATUS[0]}
  else
    "${qemu_args[@]}" 2>&1 | tee -a "${LOG}"
    local rc=${PIPESTATUS[0]}
  fi
  set -e

  # timeout(1) exits 124 when the guest keeps running after hello_kern (expected).
  if [[ ${rc} -ne 0 && ${rc} -ne 124 ]]; then
    echo "dev-vm: qemu exited ${rc}" | tee -a "${LOG}"
    return 1
  fi

  if grep -q 'hello_kern' "${LOG}"; then
    echo "dev-vm: PASS — hello_kern seen on serial (qemu-system-x86_64)" | tee -a "${LOG}"
    return 0
  fi
  return 1
}

echo "dev-vm: smoke engine=${ENGINE} ${ARCH} kernel=${KERNEL_ELF} timeout=${TIMEOUT_SEC}s" | tee "${LOG}"

case "${ENGINE}" in
  lic)
    lic_smoke || {
      echo "dev-vm: FAIL — expected hello_kern on serial (see ${LOG})" >&2
      exit 1
    }
    ;;
  qemu)
    qemu_smoke || {
      echo "dev-vm: FAIL — expected hello_kern on serial via QEMU (see ${LOG})" >&2
      exit 1
    }
    ;;
esac
