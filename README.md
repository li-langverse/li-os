# li-os

Li operating system — kernel bring-up, HAL, and dev VM tooling for the Li language ecosystem.

## M1 foundation (complete)

This repo hosts the LiOS kernel M1 sprint: freestanding `lic` kernel target (`@hw`), dev-vm smoke, and phase gates.

| Phase | Key | Status |
|-------|-----|--------|
| 0 | `phase-0-scaffold` | done |
| 1 | `phase-p0-freestanding` | done — `hello_kern` serial smoke |
| 2 | `phase-p0c-dev-vm` | done — `dev-vm.sh --smoke` + CI stub |

## M2 kernel bring-up (complete)

| Phase | Key | Status |
|-------|-----|--------|
| P1 | `m2-qemu-dev-vm` | done — `dev-vm.sh --smoke --engine qemu` |
| P2 | `m2-virtio` | done — virtio-mmio probe + blk read (lik) |
| P3 | `m2-mm` | done — physmap + bump allocator (lik) |

Normative plans: [M1](docs/plans/2026-06-lios-kernel-m1.md) · [M2](docs/plans/2026-06-lios-kernel-m2.md)

Kernel ABI (lic): [../lic/docs/kernel-abi.md](../lic/docs/kernel-abi.md) when lic is cloned as a sibling.

## Quick start

```bash
# Current phase gate (reads data/lios-kernel-loop/state.json)
bash scripts/gates/m1-progress-gate.sh

# All M1 gates
bash scripts/gates/m1-completion-gate.sh

# M2 gates (requires lik + lic on cursor/lios-kernel-m2)
export LIK_ROOT=../lik LIC_ROOT=../lic
bash scripts/gates/m2-progress-gate.sh    # current phase from state.json
bash scripts/gates/m2-completion-gate.sh  # all M2 phases

# Dev VM smoke (Li-native lic smoke-kernel; no external VM)
export LIC_ROOT=../lic   # or /workspace/lic in agent workspaces
export LIK_ROOT=../lik   # kernel source + smoke wrapper
bash scripts/dev-vm.sh --smoke
bash scripts/dev-vm.sh --smoke --arch i686 --kernel ../build/hello_kern.elf

# CI entrypoints (stubs for GitHub Actions)
bash scripts/ci/m1-kernel-smoke.sh --check
bash scripts/ci/m1-kernel-smoke.sh --smoke
bash scripts/ci/m1-kernel-smoke.sh --full
bash scripts/ci/m2-kernel-smoke.sh --check
bash scripts/ci/m2-kernel-smoke.sh --smoke   # requires qemu-system-x86_64
bash scripts/ci/m2-kernel-smoke.sh --full
```

## Dev VM (`scripts/dev-vm.sh`)

`--smoke` builds on Phase 1 `hello_kern`: runs **`lic smoke-kernel`** — lic loads the
ELF and traps `@hw outb` to COM1 in-process. No QEMU, Python, or Unicorn. Success requires
`hello_kern` in the log under `data/gate-artifacts/dev-vm-smoke-*.log`.

| Flag | Purpose |
|------|---------|
| `--smoke` | Run serial smoke test |
| `--engine lic\|qemu` | Smoke backend: in-process `@hw` (M1) or QEMU x86_64 (M2) |
| `--arch x86_64\|aarch64` | Guest architecture (default: x86_64) |
| `--kernel PATH` | Freestanding kernel ELF (default: `../build/hello_kern.elf`) |
| `--timeout SEC` | Smoke instruction budget scale (default: 30) |

Optional **aarch64** guest row: set `LIOS_KERNEL_ELF_AARCH64` when an aarch64 kernel
ELF is available; otherwise gates document the skip.

## Prerequisites

- `lic` on branch `cursor/lios-kernel-m2`, cloned at `../lic` or set `LIC_ROOT`
- `lik` on branch `cursor/lios-kernel-m2`, cloned at `../lik` or set `LIK_ROOT`
- M1 gates: no external VM deps (lic `smoke-kernel` only)
- M2 P1 gate: `qemu-system-x86_64` required for `--engine qemu`

## License

See [LICENSE](LICENSE).
