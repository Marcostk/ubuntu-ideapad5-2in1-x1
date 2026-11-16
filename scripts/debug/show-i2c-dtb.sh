#!/bin/bash
# Lista os barramentos i2c/serial ativos e seus filhos num DTB. Uso: show-i2c-dtb.sh <dtb>
dtc -q -I dtb -O dts "$1" | awk '/^\t\t\t(i2c|serial)@[0-9a-f]+ \{/ {p=1; buf=$0; ok=0; next}
  p {buf=buf"\n"$0; if ($0 ~ /status = "okay"/) ok=1; if ($0 ~ /^\t\t\t\};/) {p=0; if (ok) print buf"\n"}}' \
  | grep -E '@|compatible|reg = <0x[0-9a-f]+>;|hid-descr|interrupts-extended|clock-frequency' | sed 's/^\s*/  /'
