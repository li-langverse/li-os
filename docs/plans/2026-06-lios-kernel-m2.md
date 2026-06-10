---
workflow_repo: li-os
branch: cursor/lios-kernel-m2
plan: docs/plans/2026-06-lios-kernel-m2.md
---

# LiOS kernel M2 — goal-directed sprint

## North star

Post-M1 kernel bring-up: real QEMU dev-vm smoke, virtio block/net stubs, and basic physical memory management in **lik**.

| Repo | Role |
|------|------|
| **lik** | MM (page tables / alloc), virtio drivers |
| **lic** | Freestanding + `@hw`; any new intrinsics for MMIO |
| **li-os** | `dev-vm.sh` QEMU path, M2 gates, CI |

## Phase checklist

| Phase | Key | Deliverable | Gate |
|-------|-----|-------------|------|
| **P1** | `m2-qemu-dev-vm` | QEMU x86_64 guest boot via `dev-vm.sh --engine qemu` | `phase-m2-qemu-dev-vm-gate.sh` |
| **P2** | `m2-virtio` | Virtio-mmio probe + minimal block read in lik | `phase-m2-virtio-gate.sh` |
| **P3** | `m2-mm` | Physical memory map + bump allocator gate in lik | `phase-m2-mm-gate.sh` |

Advance `state.json` only when the current phase gate exits 0.

## Progress gate

```bash
export LIK_ROOT=/workspace/lik LIC_ROOT=/workspace/lic
bash scripts/gates/m2-progress-gate.sh
```

## Completion gate

```bash
export LIK_ROOT=/workspace/lik LIC_ROOT=/workspace/lic
bash scripts/gates/m2-completion-gate.sh
```

Expected: QEMU dev-vm smoke green; virtio probe gate; MM alloc gate.

## Todos

- id: m2-qemu-dev-vm
  content: QEMU dev-vm smoke path for hello_kern
  status: done
- id: m2-virtio
  content: virtio-mmio probe + blk sector peek in lik
  status: done
- id: m2-mm
  content: physmap + bump allocator smoke in lik
  status: done
