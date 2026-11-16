#!/bin/bash
# Quem usa cada repetidor eUSB (phys = <&eusbN_repeater>) no h3 e no fonte do 2-in-1.
H=/root/build/h3.dtb; Q=/root/src/jg/arch/arm64/boot/dts/qcom
D=$(dtc -q -I dtb -O dts "$H")
for l in eusb3_repeater eusb5_repeater eusb6_repeater eusb9_repeater; do
  ph=$(fdtget -t x "$H" "$(fdtget -t s "$H" /__symbols__ $l)" phandle)
  users=$(echo "$D" | awk -v ph="<0x$ph>;" '/^\t+[a-z0-9@,_-]+ \{/ {n=$1} $1=="phys" && $3==ph {print n}' | xargs)
  echo "h3: $l (0x$ph) <- ${users:-ninguém}"
done
echo "== 2-in-1 (fonte):"; grep -n -B8 'phys = <&eusb' "$Q/x1p42100-lenovo-ideapad-5-2in1.dts" | grep -E '^[0-9]+-&|phys'
