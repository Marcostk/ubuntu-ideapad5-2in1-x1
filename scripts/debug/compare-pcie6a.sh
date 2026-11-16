#!/bin/bash
# Compara o nó pcie@1c08000 (NVMe) e sua PHY entre o DTB do 83GH e DTBs x1p42100 do Ubuntu.
cd "$(dirname "$0")/../.."
show() {
  echo "=== $1"
  dtc -q -I dtb -O dts "$2" 2>/dev/null | awk '
    /^\t\tpcie@1c08000 \{/ {p=1} /^\t\tphy@1c0e000 \{/ {p=1}
    p {print} p && /^\t\t\};/ {p=0}' \
  | grep -E 'pcie@|phy@|compatible|status|num-lanes|max-link-speed|supply|perst|wake|reset-gpios|phys =|phy-names|clocks =|clock-names|power-domains|operating-points|interconnect' \
  | sed 's/^\s*/  /'
}
show "83GH (jglathe)" work/x1p42100-lenovo-ideapad-5-2in1.dtb
for f in /root/build/dtbs-orig/*.dtb; do
  c=$(fdtget "$f" / compatible)
  case "$c" in lenovo,ideapad-slim5x-oled*|asus,zenbook-a14-ux3407qa-oled*|lenovo,thinkbook-16*) show "${c%% *}" "$f";; esac
done
