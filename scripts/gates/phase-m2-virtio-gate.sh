#!/usr/bin/env bash
# M2 P2: virtio-mmio probe + minimal block read in lik (lic smoke-kernel --stub virtio-mmio).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=common.sh
source "${ROOT}/scripts/gates/common.sh"

LIC="$(lic_root)"
LIK="$(lik_root)"

BUILD_DIR="${ROOT}/../build"
KERNEL_ELF="${BUILD_DIR}/virtio_probe_kern.elf"
mkdir -p "${BUILD_DIR}"
ARTIFACT="${ROOT}/data/gate-artifacts/phase-m2-virtio.log"
mkdir -p "$(dirname "${ARTIFACT}")"

{
  echo "phase-m2-virtio gate"
  echo "lic=${LIC}"
  echo "lik=${LIK}"
  echo "kernel=${KERNEL_ELF}"
} | tee "${ARTIFACT}"

export LIC_ROOT="${LIC}"
export LIK_ROOT="${LIK}"
export LIOS_VIRTIO_PROBE_ELF="${KERNEL_ELF}"

bash "${LIK}/scripts/build-virtio-probe-kern.sh" 2>&1 | tee -a "${ARTIFACT}"
[[ -f "${KERNEL_ELF}" ]] || gate_fail "virtio_probe_kern.elf not built at ${KERNEL_ELF}"

if ! bash "${LIK}/scripts/smoke-virtio-probe-kern.sh" "${KERNEL_ELF}" 2>&1 | tee -a "${ARTIFACT}"; then
  gate_fail "smoke-virtio-probe-kern.sh failed"
fi

grep -q 'virtio-mmio:blk-read-ok' "${ARTIFACT}" \
  || gate_fail "virtio smoke log missing virtio-mmio:blk-read-ok serial marker"
grep -q 'smoke-kernel: PASS' "${ARTIFACT}" \
  || gate_fail "virtio smoke log missing smoke-kernel PASS marker"

gate_pass "phase-m2-virtio (virtio-mmio probe + blk read via lic smoke-kernel)"
