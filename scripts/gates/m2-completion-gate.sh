#!/usr/bin/env bash
# M2 completion — all M2 phase gates must pass (after M1 stays green).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

export LIK_ROOT="${LIK_ROOT:-$(lik_root)}"
export LIC_ROOT="${LIC_ROOT:-$(lic_root)}"

bash "${ROOT}/scripts/gates/m1-completion-gate.sh"
bash "${ROOT}/scripts/gates/phase-m2-qemu-dev-vm-gate.sh"
bash "${ROOT}/scripts/gates/phase-m2-virtio-gate.sh"
bash "${ROOT}/scripts/gates/phase-m2-mm-gate.sh"

gate_pass "m2-completion (all phases)"
