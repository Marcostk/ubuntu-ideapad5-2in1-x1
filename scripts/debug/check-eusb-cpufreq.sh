#!/bin/bash
# Repetidores eUSB (eusb5/eusb9), cam_reg_en e a configuração de cpufreq/SCMI.
Q=/root/src/jg/arch/arm64/boot/dts/qcom; H=/root/build/h3.dtb
echo "== 2-in-1: eusb repeaters e cam_reg_en"
grep -n -B1 -A14 -E '^&eusb[0-9]_repeater \{|eusb[0-9]_repeater: |cam_reg_en: ' "$Q/x1p42100-lenovo-ideapad-5-2in1.dts" | grep -v '^\s*$'
echo "== slim5x: eusb repeaters"
grep -n -A10 -E '^&eusb[0-9]_repeater \{' "$Q/x1p42100-lenovo-ideapad-slim5x.dtsi" | grep -v '^\s*$'
echo "== rótulos no DTB h3"
fdtget -p "$H" /__symbols__ | grep -E 'eusb|cam_reg|usb_2_hsphy|smb2360|pmc8380|scmi'
for l in eusb5_repeater eusb9_repeater usb_2_hsphy; do p=$(fdtget -t s "$H" /__symbols__ $l 2>/dev/null) && echo "  $l -> $p status=$(fdtget -d okay "$H" "$p" status)"; done
echo "== config cpufreq"
grep -E 'CONFIG_ARM_SCMI_CPUFREQ|CONFIG_ARM_SCMI_PERF|CONFIG_ARM_SCMI_POWER_DOMAIN|CONFIG_ARM_QCOM_CPUFREQ' /root/build/cfg/boot/config-*
echo "== cpus no DTB h3"
dtc -q -I dtb -O dts "$H" | awk '/^\t\tcpu@0 \{/ {p=1} p {print} p && /^\t\t\};/ {exit}' | grep -E 'power-domain|clocks|operating|performance'
