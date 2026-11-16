#!/bin/bash
# Nó eusb5 e estados de pino eusb*_reset_n e gpio44 no DTB h3 (Slim 5x + overlays).
H=/root/build/h3.dtb
D=$(dtc -q -I dtb -O dts "$H")
echo "== eusb5 (redriver@43)"; echo "$D" | awk 'index($0,"redriver@43 {") {p=1} p {print} p && /};/ {exit}'
for l in eusb3_reset_n eusb5_reset_n eusb6_reset_n eusb9_reset_n; do
  p=$(fdtget -t s "$H" /__symbols__ $l); echo "== $l -> $p: pins=$(fdtget -t s "$H" "$p" pins) $(fdtget -t s -d '' "$H" "$p" function)"
done
echo "== estados com gpio44"
echo "$D" | awk '/^\t+[a-z0-9-]+-state \{|^\t+[a-z0-9-]+-pins \{/ {n=$1} /"gpio44"/ {print n": "$0}'
