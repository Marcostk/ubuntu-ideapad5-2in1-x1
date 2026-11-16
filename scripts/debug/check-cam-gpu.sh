#!/bin/bash
# Firmware gen71500 na imagem, nó eusb9 e uso do GPIO 44 no DTB base, e aliases do scmi_cpufreq.
cd "$(dirname "$0")/../.."
B=/root/build; H=$B/h3.dtb
echo "== firmware gen71500 / a7xx na imagem"
grep -i -E 'gen715|gen70500_(sqe|gmu)|a740_sqe|gmu_gen7' "$B/minimal.list" | sed 's|squashfs-root||' | head
echo "== msm: nomes de firmware pedidos para gen71500 (strings do módulo)"
unsquashfs -q -f -d "$B/msm" work/usb/minimal.squashfs 'usr/lib/modules/7.3.0-15-qcom-x1e/kernel/drivers/gpu/drm/msm/msm.ko.zst' >/dev/null
zstd -q -d -c "$B"/msm/usr/lib/modules/*/kernel/drivers/gpu/drm/msm/msm.ko.zst | strings | grep -E '^(qcom/)?gen7[0-9]*_(sqe|gmu)|gen71500' | sort -u
echo "== eusb9_repeater e usb_2_hsphy no h3"
p=$(fdtget -t s "$H" /__symbols__ eusb9_repeater); dtc -q -I dtb -O dts "$H" | awk -v n="redriver@4b {" 'index($0,n) {p=1} p {print} p && /};/ {exit}'
echo "  usb_2_hsphy phys = $(fdtget -t x "$H" /soc@0/phy@88e0000 phys)  (eusb5=$(fdtget -t x "$H" "$(fdtget -t s "$H" /__symbols__ eusb5_repeater)" phandle) eusb9=$(fdtget -t x "$H" "$p" phandle))"
echo "== GPIO 44 no h3"
dtc -q -I dtb -O dts "$H" | grep -n -E '"gpio44"|tlmm 0x2c|<0x[0-9a-f]+ 0x2c 0x' | head
echo "== scmi_cpufreq aliases"
unsquashfs -q -f -d "$B/scmi" work/usb/minimal.squashfs 'usr/lib/modules/7.3.0-15-qcom-x1e/kernel/drivers/cpufreq/scmi-cpufreq.ko.zst' 'usr/lib/modules/7.3.0-15-qcom-x1e/modules.alias' >/dev/null
grep -E 'scmi_cpufreq|scmi_perf' "$B"/scmi/usr/lib/modules/*/modules.alias | head
