#!/bin/bash
# Compila o DTB do IdeaPad 5 2-in-1 (83GH) a partir do kernel do Jens Glathe (7.3.0-jg-4).
# Uso: build-dtb.sh <árvore do kernel> <saída.dtb>
set -euo pipefail
K="$1"; OUT="$2"
DTS="$K/arch/arm64/boot/dts/qcom/x1p42100-lenovo-ideapad-5-2in1.dts"
cpp -nostdinc -undef -D__DTS__ -x assembler-with-cpp \
    -I "$K/include" -I "$K/arch/arm64/boot/dts/qcom" -I "$K/scripts/dtc/include-prefixes" \
    "$DTS" | dtc -q -@ -I dts -O dtb -o "$OUT" -
# Sem o fallback "lenovo,thinkpad-t14s": com ele o kernel do Ubuntu libera o uefisecapp (QSEECOM)
# do T14s e o 83GH reseta ao subir o qcomtee/drivers (~15 s de boot). O Omarchy também o remove.
fdtput -t s "$OUT" / compatible lenovo,ideapad-5-2in1 qcom,x1p42100
fdtget "$OUT" / model
fdtget "$OUT" / compatible
