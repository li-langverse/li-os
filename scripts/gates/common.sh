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

gate_pass() {
  echo "PASS: $*"
}

gate_fail() {
  echo "FAIL: $*" >&2
  exit 1
}
