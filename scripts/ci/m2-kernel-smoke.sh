#!/usr/bin/env bash
# M2 kernel CI smoke — local/CI entrypoint for QEMU dev-vm + lik virtio/mm gates.
#
# Phase deliverable: deterministic script CI can call without ad-hoc gate paths.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODE="check"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--check | --smoke | --full]

  --check   Verify M2 gate scripts + dev-vm --help (CI dry run, default)
  --smoke   Run dev-vm.sh --smoke --engine qemu x86_64 (requires lic + lik + qemu)
  --full    Run all M2 phase gates (after M1 completion gate)

Environment:
  LIC_ROOT            Path to lic checkout (compiler + smoke-kernel)
  LIK_ROOT            Path to lik checkout (kernel source + virtio/mm smokes)
  LIOS_KERNEL_ELF     Override x86 guest kernel ELF for QEMU smoke
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) MODE="check"; shift ;;
    --smoke) MODE="smoke"; shift ;;
    --full) MODE="full"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "m2-kernel-smoke: unknown arg: $1" >&2; usage >&2; exit 1 ;;
  esac
done

case "${MODE}" in
  check)
    for gate in \
      phase-m2-qemu-dev-vm-gate.sh \
      phase-m2-virtio-gate.sh \
      phase-m2-mm-gate.sh; do
      [[ -f "${ROOT}/scripts/gates/${gate}" ]] \
        || { echo "m2-kernel-smoke: missing gate ${gate}" >&2; exit 1; }
    done
    bash "${ROOT}/scripts/dev-vm.sh" --help >/dev/null
    echo "ci/m2-kernel-smoke: check PASS"
    ;;
  smoke)
    bash "${ROOT}/scripts/dev-vm.sh" --smoke --engine qemu --arch x86_64
    ;;
  full)
    bash "${ROOT}/scripts/gates/m2-completion-gate.sh"
    ;;
esac
