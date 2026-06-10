#!/usr/bin/env bash
# M2 P2: virtio-mmio probe in lik (not yet implemented).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

gate_fail "phase-m2-virtio not implemented — add virtio-mmio probe in lik/src"
