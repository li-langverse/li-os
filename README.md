# li-os

Li operating system — kernel bring-up, HAL, and dev VM tooling for the Li language ecosystem.

## M1 foundation (in progress)

This repo hosts the LiOS kernel M1 sprint: freestanding `lic` kernel target (`@hw`), QEMU dev VM, and phase gates.

| Phase | Key | Status |
|-------|-----|--------|
| 0 | `phase-0-scaffold` | scaffold + gates |
| 1 | `phase-p0-freestanding` | `hello_kern` on QEMU serial (x86_64) |
| 2 | `phase-p0c-dev-vm` | `dev-vm.sh --smoke` documented + CI stub |

Normative plan: [docs/plans/2026-06-lios-kernel-m1.md](docs/plans/2026-06-lios-kernel-m1.md)

Kernel ABI (lic): [../lic/docs/kernel-abi.md](../lic/docs/kernel-abi.md) when lic is cloned as a sibling.

## Quick start

```bash
# Phase 0 gate
bash scripts/gates/phase-0-scaffold-gate.sh

# Dev VM (Phase 2+)
bash scripts/dev-vm.sh --help
bash scripts/dev-vm.sh --smoke   # after hello_kern lands
```

## Prerequisites

- `lic` built and on `PATH` (Phase 1+)
- QEMU (`qemu-system-x86_64`, optional `qemu-system-aarch64`) for smoke tests
- Clone [lic](https://github.com/li-langverse/lic) at `../lic` relative to this repo

## License

See [LICENSE](LICENSE).
