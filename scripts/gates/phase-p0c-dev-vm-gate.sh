#!/usr/bin/env bash
# Phase 2 — dev-vm.sh --smoke for x86_64 guest (+ optional aarch64 row).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

gate_fail "phase-p0c-dev-vm not implemented yet — dev-vm.sh --smoke required"
