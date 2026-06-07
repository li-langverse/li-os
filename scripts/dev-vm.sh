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
  --arch ARCH   Guest architecture (default: x86_64)
  --kernel PATH Path to freestanding kernel ELF (default: build/hello_kern.elf)
  --timeout SEC QEMU run timeout in seconds (default: 30)
  -h, --help    Show this help

Environment:
  LIC_ROOT          Path to lic checkout (for building hello_kern in Phase 1+)
  LIOS_KERNEL_ELF   Override kernel ELF path
  LIOS_DEV_VM_ARCH  Default guest arch
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
  x86_64)
    QEMU="qemu-system-x86_64"
    QEMU_ARGS=(
      -machine q35
      -cpu max
      -m 128M
      -nographic
      -kernel "${KERNEL_ELF}"
      -serial stdio
    )
    ;;
  aarch64)
    QEMU="qemu-system-aarch64"
    QEMU_ARGS=(
      -machine virt
      -cpu max
      -m 128M
      -nographic
      -kernel "${KERNEL_ELF}"
      -serial stdio
    )
    ;;
  *)
    echo "dev-vm: unsupported arch: ${ARCH}" >&2
    exit 1
    ;;
esac

ARTIFACT_DIR="${ROOT}/data/gate-artifacts"
mkdir -p "${ARTIFACT_DIR}"
LOG="${ARTIFACT_DIR}/dev-vm-smoke-${ARCH}.log"

if ! command -v "${QEMU}" >/dev/null 2>&1; then
  echo "dev-vm: QEMU not found: ${QEMU}" >&2
  echo "dev-vm: falling back to Unicorn serial smoke" >&2
  LIC="${LIC_ROOT:-}"
  if [[ -z "${LIC}" ]]; then
    for candidate in "${ROOT}/../lic" "/workspace/lic"; do
      if [[ -d "${candidate}/.git" ]]; then
        LIC="${candidate}"
        break
      fi
    done
  fi
  if [[ -n "${LIC}" && -f "${LIC}/scripts/hello-kern-serial-smoke.py" ]]; then
    if python3 "${LIC}/scripts/hello-kern-serial-smoke.py" "${KERNEL_ELF}" 2>&1 | tee -a "${LOG}"; then
      echo "dev-vm: PASS — hello_kern seen on serial (unicorn)" | tee -a "${LOG}"
      exit 0
    fi
  fi
  exit 1
fi

# Prefer i386 multiboot loader when available (M1 hello_kern is i686 freestanding).
QEMU_BIN="${QEMU}"
if [[ -x /opt/qemu/usr/libexec/qemu-system-i386 ]]; then
  QEMU_BIN="/opt/qemu/usr/libexec/qemu-system-i386"
fi

echo "dev-vm: smoke ${ARCH} kernel=${KERNEL_ELF} timeout=${TIMEOUT_SEC}s qemu=${QEMU_BIN}" | tee "${LOG}"
set +e
timeout "${TIMEOUT_SEC}" "${QEMU_BIN}" -display none \
  -chardev stdio,id=s0 -device isa-serial,chardev=s0,iobase=0x3f8,irq=4 \
  -kernel "${KERNEL_ELF}" 2>&1 | tee -a "${LOG}"
QEMU_RC=$?
set -e

if grep -q 'hello_kern' "${LOG}"; then
  echo "dev-vm: PASS — hello_kern seen on serial" | tee -a "${LOG}"
  exit 0
fi

if [[ "${QEMU_RC}" -ne 0 ]]; then
  echo "dev-vm: QEMU rc=${QEMU_RC}; trying Unicorn serial smoke" | tee -a "${LOG}"
  LIC="${LIC_ROOT:-}"
  if [[ -z "${LIC}" ]]; then
    for candidate in "${ROOT}/../lic" "/workspace/lic"; do
      if [[ -d "${candidate}/.git" ]]; then
        LIC="${candidate}"
        break
      fi
    done
  fi
  if [[ -n "${LIC}" && -f "${LIC}/scripts/hello-kern-serial-smoke.py" ]]; then
    if python3 "${LIC}/scripts/hello-kern-serial-smoke.py" "${KERNEL_ELF}" 2>&1 | tee -a "${LOG}"; then
      echo "dev-vm: PASS — hello_kern seen on serial (unicorn fallback)" | tee -a "${LOG}"
      exit 0
    fi
  fi
fi

if grep -q 'hello_kern' "${LOG}"; then
  echo "dev-vm: PASS — hello_kern seen on serial" | tee -a "${LOG}"
  exit 0
fi

echo "dev-vm: FAIL — expected hello_kern on serial (see ${LOG})" >&2
exit 1
