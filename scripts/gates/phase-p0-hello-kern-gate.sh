#!/usr/bin/env bash
# Phase 1 — build hello_kern freestanding kernel and verify QEMU serial output.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

gate_fail "phase-p0-freestanding not implemented yet — hello_kern + QEMU serial required"
