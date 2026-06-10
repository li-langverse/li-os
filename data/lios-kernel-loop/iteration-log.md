# lios-kernel M1 loop

| iter | phase | gate | notes |
|------|-------|------|-------|
| 1 | phase-0-scaffold | PASS | li-os scaffold, dev-vm skeleton, gates; lic docs/kernel-abi.md stub |
| 2 | phase-p0-freestanding | PASS | lic freestanding i686 + @hw; hello_kern ELF; Unicorn COM1 serial smoke |
| 3 | phase-p0c-dev-vm | PASS | dev-vm.sh --smoke x86_64; scripts/ci/m1-kernel-smoke.sh stub; aarch64 row documented skip |
| R0 | phase-r0-lik-scaffold | PASS | lik repo; kernel moved from lic; device-ports unlimited policy |
| R1 | phase-r1-lic-compiler-only | PASS | lic compiler-only; kernel tree removed |
| R2 | phase-r2-lios-gates | PASS | LIK_ROOT gates; check-no-port-caps; dev-vm dynamic hostfwd |
