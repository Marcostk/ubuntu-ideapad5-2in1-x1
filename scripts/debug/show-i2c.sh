#!/bin/bash
# Mostra os blocos &i2cN / &uart / &sdhc / firmware-name / sound do DTS do 2-in-1 (jglathe)
# e quais barramentos/firmware o DTB do Slim 5x do Ubuntu usa.
Q=/root/src/jg/arch/arm64/boot/dts/qcom
echo "############ 2-in-1 (jglathe): blocos i2c/uart/sdhc"
awk '/^&(i2c[0-9]+|uart[0-9]+|sdhc_2|qupv3_[0-9]|keyboard|touchpad)\b/ {p=1} p {print} p && /^};/ {p=0; print ""}' \
  "$Q/x1p42100-lenovo-ideapad-5-2in1.dts" | grep -v -E '^\s*$'
echo "############ labels -> endereço (hamoa/purwa dtsi)"
grep -h -E '^\s+(i2c[0-9]+|uart[0-9]+|sdhc_2|qupv3_[0-9]): ' "$Q"/hamoa.dtsi "$Q"/purwa.dtsi 2>/dev/null | sed 's/^\s*//' | sort -u
echo "############ Slim 5x (Ubuntu DTB): i2c ativos e filhos"
S=$(for f in /root/build/dtbs-orig/*.dtb; do fdtget "$f" / compatible | grep -q '^lenovo,ideapad-slim5x-oled' && echo "$f" || true; done)
dtc -q -I dtb -O dts "$S" | awk '/^\t\t\t(i2c|serial)@[0-9a-f]+ \{/ {p=1; buf=$0; ok=0; next}
  p {buf=buf"\n"$0; if ($0 ~ /status = "okay"/) ok=1; if ($0 ~ /^\t\t\t\};/) {p=0; if (ok) print buf"\n"}}' \
  | grep -E '@|compatible|reg = <0x[0-9a-f]+>;|hid-descr|status|firmware' | sed 's/^\s*/  /'
echo "############ Slim 5x (Ubuntu DTB): firmware-name e sound"
dtc -q -I dtb -O dts "$S" | grep -E 'firmware-name|model = ' | sed 's/^\s*/  /'
