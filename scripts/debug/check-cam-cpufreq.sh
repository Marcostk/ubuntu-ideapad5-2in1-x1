#!/bin/bash
# Câmera (regulador e controlador usb_2), cpufreq e sensores: DTB h3 vs DTS do 2-in-1, e o diag do Slim 5x.
cd "$(dirname "$0")/../.."
H=/root/build/h3.dtb; Q=/root/src/jg/arch/arm64/boot/dts/qcom
echo "== h3: reguladores/consumidores de câmera"
dtc -q -I dtb -O dts "$H" | grep -n -B2 -A12 -E 'VREG_CAM|regulator-dummy-consumer' | grep -E 'regulator-name|compatible|gpio =|always-on|boot-on|status|vdd-supply' | sed 's/^\s*/  /'
echo "== h3: usb@a200000 (usb_2) e phy"
for n in usb@a200000 phy@88e0000; do echo "  $n status=$(fdtget -d okay "$H" /soc@0/$n status 2>&1)"; done
echo "== 2-in-1 (jglathe): câmera e usb_2"
grep -n -A12 -E 'vreg_cam_5p0: regulator|^&usb_2 \{|^&usb_2_hsphy \{|camera \{' "$Q/x1p42100-lenovo-ideapad-5-2in1.dts" | grep -v '^\s*$' | head -45
echo "== slim5x (jglathe): câmera e usb_2"
grep -n -A12 -E 'vreg_cam_5p0: regulator|^&usb_2 \{|^&usb_2_hsphy \{|camera \{' "$Q/x1p42100-lenovo-ideapad-slim5x.dtsi" | grep -v '^\s*$' | head -45
echo "== diag Slim 5x: módulos cpufreq/uvc/thermal"
grep -E '^(scmi_cpufreq|uvcvideo|qcom_tsens|qcom_spmi_temp_alarm|qcom_spmi_adc|cpufreq)' work/logs/diag-20261115-204422/lsmod.txt
grep -i -E 'cpufreq|scmi' work/logs/boot-008-journal.txt | head -5
