#!/bin/bash
# Compara o nó qcom,wcn7850-pmu (power sequencer do Wi-Fi/BT) e a OPP do pcie4 entre DTBs.
cd "$(dirname "$0")/../.."
gpioname() { echo "$1"; }
show() {
  echo "=== $1"
  dtc -q -I dtb -O dts "$2" 2>/dev/null | awk '
    /compatible = "qcom,wcn7850-pmu"/ {p=1; print prev}
    {prev=$0}
    p {print} p && /^\t\};/ {p=0}' \
  | grep -v -E 'phandle|regulator-(min|max)|^\s*$' | grep -E 'pmu|gpios|supply|compatible|pinctrl|regulators|ldo|clocks' | sed 's/^\s*/  /'
}
show "83GH (jglathe)" work/x1p42100-lenovo-ideapad-5-2in1.dtb
for f in /root/build/dtbs-orig/*.dtb; do
  c=$(fdtget "$f" / compatible)
  case "$c" in lenovo,ideapad-slim5x-oled*|lenovo,thinkbook-16*) show "${c%% *}" "$f";; esac
done
echo "=== pinos tlmm usados pelo pmu do 83GH (fonte jglathe)"
grep -n -A30 'wcn7850-pmu' /root/src/jg/arch/arm64/boot/dts/qcom/x1p42100-lenovo-ideapad-5-2in1.dts | grep -E 'gpios|pinctrl|supply'
grep -n -A30 'wcn7850-pmu' /root/src/jg/arch/arm64/boot/dts/qcom/x1p42100-lenovo-ideapad-slim5x.dtsi | grep -E 'gpios|pinctrl|supply'
