#!/bin/bash
# gpio-reserved-ranges do tlmm: h4 (Slim 5x) vs fonte do 2-in-1 e do Slim 5x.
Q=/root/src/jg/arch/arm64/boot/dts/qcom
echo "h4: $(fdtget /root/build/h4.dtb /soc@0/pinctrl@f100000 gpio-reserved-ranges)"
for f in x1p42100-lenovo-ideapad-5-2in1.dts x1p42100-lenovo-ideapad-slim5x.dtsi; do
  echo "== $f"; awk '/^&tlmm \{/ {p=1} p && /gpio-reserved-ranges/ {q=1} q {print} q && /;/ {exit}' "$Q/$f"
done
