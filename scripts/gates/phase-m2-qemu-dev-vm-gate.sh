#!/usr/bin/env bash
# M2 P1: QEMU x86_64 dev-vm smoke (not yet implemented).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

gate_fail "phase-m2-qemu-dev-vm not implemented — add QEMU boot path to scripts/dev-vm.sh"
