#!/bin/bash
# Compila o Slim 5x OLED da árvore do jglathe e compara (nós/propriedades, sem phandles) com o do Ubuntu.
set -euo pipefail
K=/root/src/jg; B=/root/build
cpp -nostdinc -undef -D__DTS__ -x assembler-with-cpp -I "$K/include" -I "$K/arch/arm64/boot/dts/qcom" \
    -I "$K/scripts/dtc/include-prefixes" "$K/arch/arm64/boot/dts/qcom/x1p42100-lenovo-ideapad-slim5x-oled.dts" \
  | dtc -q -@ -I dts -O dtb -o "$B/jg-slim5x.dtb" -
U=$(for f in "$B"/dtbs-orig/*.dtb; do fdtget "$f" / compatible | grep -q '^lenovo,ideapad-slim5x-oled' && echo "$f" || true; done)
norm() { dtc -q -s -I dtb -O dts "$1" | grep -v -E 'phandle|^\s*(interconnects|clocks|power-domains|interrupts-extended|iommus|phys|resets|.*-supply|pinctrl-0|mboxes|qcom,smem-states|operating-points-v2|required-opps|remote-endpoint|dmas|memory-region|thermal-sensors|cooling-device|trip|qcom,bcm-voters|#.*-cells|gpio-ranges|interrupt-parent|msi-map|iommu-map|nvmem-cells|clocks-names) = ' | sed '/__symbols__/,$d'; }
norm "$U" > "$B/u-slim5x.dts"; norm "$B/jg-slim5x.dtb" > "$B/jg-slim5x.dts"
fdtget -l "$U" / | grep -q __symbols__ && echo "DTB do Ubuntu TEM __symbols__ (overlays funcionam)" || echo "DTB do Ubuntu SEM __symbols__"
echo "linhas diferentes: $(diff "$B/u-slim5x.dts" "$B/jg-slim5x.dts" | grep -c '^[<>]')"
diff -U2 "$B/u-slim5x.dts" "$B/jg-slim5x.dts" | head -250
