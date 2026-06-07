#!/usr/bin/env bash
# M1 kernel CI smoke — local/CI entrypoint (stub for GitHub Actions wiring).
#
# Phase 2 deliverable: deterministic script CI can call without ad-hoc gate paths.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODE="check"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--check | --smoke | --full]

  --check   Verify scaffold + dev-vm --help (CI dry run, default)
  --smoke   Run dev-vm.sh --smoke for x86_64 (requires lic + hello_kern)
  --full    Run all M1 phase gates (scaffold + hello_kern + dev-vm)

Environment:
  LIC_ROOT            Path to lic checkout
  LIOS_KERNEL_ELF     Override x86 guest kernel ELF
  LIOS_KERNEL_ELF_AARCH64  Optional aarch64 guest ELF
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) MODE="check"; shift ;;
    --smoke) MODE="smoke"; shift ;;
    --full) MODE="full"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "m1-kernel-smoke: unknown arg: $1" >&2; usage >&2; exit 1 ;;
  esac
done

case "${MODE}" in
  check)
    bash "${ROOT}/scripts/gates/phase-0-scaffold-gate.sh"
    bash "${ROOT}/scripts/dev-vm.sh" --help >/dev/null
    echo "ci/m1-kernel-smoke: check PASS"
    ;;
  smoke)
    bash "${ROOT}/scripts/dev-vm.sh" --smoke --arch x86_64
    ;;
  full)
    bash "${ROOT}/scripts/gates/m1-completion-gate.sh"
    ;;
esac
