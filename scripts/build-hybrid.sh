#!/bin/bash
# DTB híbrido: Slim 5x do Ubuntu (boota no 83GH) + overlays de dt/ com as peças do 83GH.
# Gera work/vmlinuz.h1 (teclado/touchpad), h2 (+ tela touch), h3 (+ firmware dos DSPs),
# h4 (+ câmera, zona térmica cpu-thermal). Rodar como root no WSL, a partir da raiz do projeto, depois de build-slim5x-test.sh.
set -euo pipefail
B=/root/build; BASE=$B/slim5x-as-2in1.dtb
[ -f "$BASE" ] || { echo "rode scripts/build-slim5x-test.sh antes" >&2; exit 1; }
for o in input touchscreen firmware camera; do
  dtc -q -@ -I dts -O dtb -o "$B/83gh-$o.dtbo" "dt/83gh-$o.dtso"
done
build() { # $1 = nome, resto = overlays
  n=$1; shift
  fdtoverlay -i "$BASE" -o "$B/$n.dtb" $(for o in "$@"; do echo "$B/83gh-$o.dtbo"; done)
  if [[ " $* " == *" camera "* ]]; then
    # no 83GH o redriver@43 (eusb5) não tem reset; o GPIO 7 passa para o redriver@4b
    r=$(fdtget -t s "$B/$n.dtb" /__symbols__ eusb5_repeater)
    for p in reset-gpios pinctrl-0 pinctrl-names; do fdtput -d "$B/$n.dtb" "$r" $p; done
    # monitores como o GNOME Resources só leem a zona térmica chamada "cpu-thermal";
    # o tipo da zona é o nome do nó, então renomeia a do subsistema da CPU (inclui o caminho em __symbols__)
    dtc -q -I dtb -O dts "$B/$n.dtb" | sed 's/\bcpuss0-top-thermal\b/cpu-thermal/g' \
      | dtc -q -@ -I dts -O dtb -o "$B/$n.dtb" -
    fdtget -l "$B/$n.dtb" /thermal-zones | grep -qx cpu-thermal
  fi
  fdtput -t s "$B/$n.dtb" / model "Lenovo IdeaPad 5 2-in-1 14Q8X9 (UbuntoARM $n)"
  python3 -I scripts/add-dtb-to-uki.py work/usb/vmlinuz "$B/$n.dtb" "work/vmlinuz.$n" >/dev/null
  echo "$n: i2c2=$(fdtget "$B/$n.dtb" /soc@0/geniqup@bc0000/i2c@b88000 status) ts=$(fdtget -d - "$B/$n.dtb" /soc@0/geniqup@ac0000/i2c@a80000/touchscreen@a compatible) adsp=$(fdtget "$B/$n.dtb" /soc@0/remoteproc@6800000 firmware-name | cut -d' ' -f1) cam=$(fdtget -d - "$B/$n.dtb" /regulator-cam-5p0 regulator-name)"
}
build h1 input
build h2 input touchscreen
build h3 input touchscreen firmware
build h4 input touchscreen firmware camera
