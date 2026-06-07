#!/usr/bin/env bash
# Reject C/asm objects in a freestanding kernel ELF (Phase 1+).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

elf="${1:-}"
if [[ -z "${elf}" || ! -f "${elf}" ]]; then
  gate_fail "usage: check-zero-c.sh <kernel.elf>"
fi

require_cmd readelf

while IFS= read -r line; do
  if echo "${line}" | grep -qE '\.(c|cc|cpp|s|S|asm|o)\b'; then
    gate_fail "kernel ELF must not link C/asm objects: ${line}"
  fi
done < <(readelf -p .comment "${elf}" 2>/dev/null || true)

# Reject if any .o from trusted C runtime appears in dynamic symbols (best-effort).
if readelf -s "${elf}" 2>/dev/null | grep -qiE 'md_core|trusted|\.c'; then
  gate_fail "kernel ELF contains suspicious C/runtime symbols"
fi

gate_pass "check-zero-c ${elf}"
