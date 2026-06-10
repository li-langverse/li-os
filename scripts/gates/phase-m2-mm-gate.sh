#!/usr/bin/env bash
# M2 P3: physical memory map + bump allocator in lik (not yet implemented).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

gate_fail "phase-m2-mm not implemented — add MM bump allocator in lik/src"
