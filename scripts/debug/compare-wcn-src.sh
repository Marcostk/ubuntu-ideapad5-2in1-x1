#!/bin/bash
# Compara, no fonte do jglathe, os reguladores do Wi-Fi e os overrides de pcie4 entre 2-in-1 e Slim 5x.
Q=/root/src/jg/arch/arm64/boot/dts/qcom
for f in x1p42100-lenovo-ideapad-5-2in1.dts x1p42100-lenovo-ideapad-slim5x.dtsi; do
  echo "=================== $f"
  awk '/vreg_wcn_[0-9a-z]+: regulator|vreg_wwan|vreg_nvme|&pcie4 \{|&pcie4_phy \{|&pcie4_port0 \{|&pcie6a \{|&pcie6a_phy \{|pcie4_opp|wcn_wlan_bt_en: |wcn_sw_en: |nvme_reg_en: |pcie4_default: |pcie6a_default: / {p=1}
       p {print} p && /^\t\};|^\t};|^};/ {p=0}' "$Q/$f" | grep -v -E '^\s*$'
done
