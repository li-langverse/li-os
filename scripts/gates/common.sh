#!/usr/bin/env bash
# Shared helpers for LiOS M1 phase gates.
set -euo pipefail

gate_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

lic_root() {
  if [[ -n "${LIC_ROOT:-}" && -d "${LIC_ROOT}" ]]; then
    echo "${LIC_ROOT}"
    return 0
  fi
  local root
  root="$(gate_root)"
  for candidate in "${root}/../lic" "/workspace/lic"; do
    if [[ -d "${candidate}/.git" ]]; then
      echo "${candidate}"
      return 0
    fi
  done
  echo "li-os gates: LIC_ROOT not found (set LIC_ROOT or clone lic as ../lic)" >&2
  return 1
}

lik_root() {
  if [[ -n "${LIK_ROOT:-}" && -d "${LIK_ROOT}" ]]; then
    echo "${LIK_ROOT}"
    return 0
  fi
  local root
  root="$(gate_root)"
  for candidate in "${root}/../lik" "/workspace/lik"; do
    if [[ -d "${candidate}/.git" ]]; then
      echo "${candidate}"
      return 0
    fi
  done
  echo "li-os gates: LIK_ROOT not found (set LIK_ROOT or clone lik as ../lik)" >&2
  return 1
}

artifact_dir() {
  local root
  root="$(gate_root)"
  local dir="${root}/data/gate-artifacts"
  mkdir -p "${dir}"
  echo "${dir}"
}

require_cmd() {
  local name="$1"
  if ! command -v "${name}" >/dev/null 2>&1; then
    echo "li-os gates: required command missing: ${name}" >&2
    return 1
  fi
}

lic_bin() {
  local root
  root="$(lic_root)"
  local candidate
  for candidate in \
    "${root}/build-kernel/compiler/lic/lic" \
    "${root}/build/compiler/lic/lic" \
    "${root}/build-wsl/compiler/lic/lic"; do
    if [[ -x "${candidate}" ]] && "${candidate}" --version >/dev/null 2>&1; then
      echo "${candidate}"
      return 0
    fi
  done
  if command -v lic >/dev/null 2>&1 && lic --version >/dev/null 2>&1; then
    command -v lic
    return 0
  fi
  echo "li-os gates: lic compiler not found (build lic or set LIC=)" >&2
  return 1
}

# Export lic/lik roots and a working compiler binary for lik build-*.sh scripts.
gate_export_roots() {
  export LIC_ROOT="$(lic_root)"
  export LIK_ROOT="$(lik_root)"
  export LIC="$(lic_bin)"
}

# readelf or llvm-readelf; falls back to bundled Python shim when neither is installed.
readelf_cmd() {
  if command -v readelf >/dev/null 2>&1; then
    echo readelf
    return 0
  fi
  if command -v llvm-readelf >/dev/null 2>&1; then
    echo llvm-readelf
    return 0
  fi
  local shim
  shim="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/elf-readelf-shim.py"
  if [[ -f "${shim}" ]]; then
    echo "python3 ${shim}"
    return 0
  fi
  echo "li-os gates: readelf/llvm-readelf not found and no shim at ${shim}" >&2
  return 1
}

gate_pass() {
  echo "PASS: $*"
}

gate_fail() {
  echo "FAIL: $*" >&2
  exit 1
}
