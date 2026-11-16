#!/bin/bash
# Monta tudo para o pendrive do IdeaPad 5 2-in-1 (83GH). Rodar como root no WSL, na raiz do projeto,
# depois de scripts/extract-firmware.ps1 (Windows) e scripts/prepare.sh.
# Saídas em work/: vmlinuz.h4 (principal), vmlinuz.h3 (sem câmera), vmlinuz.slim5x (reserva), initrd.qnoc,
#                  minimal.standard.live.squashfs.83gh, minimal.squashfs.83gh
set -euo pipefail
[ -d firmware/windows-driverstore ] || { echo "rode scripts/extract-firmware.ps1 no Windows antes" >&2; exit 1; }
bash scripts/build-live-83gh.sh    # firmware + topologia/UCM de áudio + serviço de log -> initrd e camada live
bash scripts/build-qnoc.sh         # módulo de interconexão com banda inicial 0
bash scripts/build-initrd-qnoc.sh  # initrd com o módulo + firmware
bash scripts/build-slim5x-test.sh  # base do DTB híbrido (+ kernel de reserva)
bash scripts/build-hybrid.sh       # DTB híbrido h1..h4
bash scripts/build-base-layer.sh   # camada base com tudo: o instalador copia esta para o SSD (~15 min)
echo; ls -l work/vmlinuz.h4 work/vmlinuz.h3 work/vmlinuz.slim5x work/initrd.qnoc work/minimal.standard.live.squashfs.83gh
