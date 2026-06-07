#!/usr/bin/env bash
# Reject fixed MAX_DEVICES / MAX_IO_PORTS caps in lik kernel source.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

LIK="$(lik_root)"
SRC="${LIK}/src"
[[ -d "${SRC}" ]] || gate_fail "lik src/ not found under ${LIK}"

POLICY="${LIK}/docs/device-ports.md"
[[ -f "${POLICY}" ]] || gate_fail "missing unlimited-port policy: ${POLICY}"

bad=0
while IFS= read -r path; do
  if grep -qE 'MAX_DEVICES|MAX_IO_PORTS|MAX_MMIO' "${path}"; then
    echo "check-no-port-caps: forbidden cap constant in ${path}" >&2
    bad=1
  fi
done < <(find "${SRC}" -type f \( -name '*.li' -o -name '*.md' \) 2>/dev/null)

[[ "${bad}" -eq 0 ]] || gate_fail "lik src/ contains fixed port/device caps (see docs/device-ports.md)"

gate_pass "check-no-port-caps (lik src/ has no MAX_* port caps)"
