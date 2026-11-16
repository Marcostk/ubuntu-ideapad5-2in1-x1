#!/bin/bash
# Mostra o compatible do PDC (interrupt-controller@b220000) no DTB do 83GH e nos DTBs x1p42100 do Ubuntu.
cd "$(dirname "$0")/../.."
N=/soc@0/interrupt-controller@b220000
echo "83GH (jglathe): $(fdtget work/x1p42100-lenovo-ideapad-5-2in1.dtb $N compatible)"
for f in /root/build/dtbs-orig/*.dtb; do
  c=$(fdtget "$f" / compatible)
  case "$c" in *x1p42100*) echo "${c%% *}: $(fdtget "$f" $N compatible)";; esac
done
echo "--- purwa.dtsi (jglathe)"; grep -n -A3 '&pdc' /root/src/jg/arch/arm64/boot/dts/qcom/purwa.dtsi || echo "sem override de &pdc"
