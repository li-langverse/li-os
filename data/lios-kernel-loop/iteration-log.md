# lios-kernel M1 loop

| iter | phase | gate | notes |
|------|-------|------|-------|
| 1 | phase-0-scaffold | PASS | li-os scaffold, dev-vm skeleton, gates; lic docs/kernel-abi.md stub |
| 2 | phase-p0-freestanding | PASS | lic freestanding i686 + @hw; hello_kern ELF; Unicorn COM1 serial smoke |
| 3 | phase-p0c-dev-vm | PASS | dev-vm.sh --smoke x86_64; scripts/ci/m1-kernel-smoke.sh stub; aarch64 row documented skip |
