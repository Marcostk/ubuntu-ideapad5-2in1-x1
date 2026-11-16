#!/bin/bash
# Mostra no fonte (jglathe) os blocos &i2c0/&i2c2/&i2c8 e pinctrl de teclado/touchpad/touchscreen
# do 2-in-1 e do Slim 5x, e os rótulos disponíveis no DTB do Ubuntu para overlays.
Q=/root/src/jg/arch/arm64/boot/dts/qcom
for f in x1p42100-lenovo-ideapad-5-2in1.dts x1p42100-lenovo-ideapad-slim5x.dtsi; do
  echo "=================== $f"
  awk '/^&(i2c0|i2c2|i2c8) \{/ {p=1} /^\t(kybd|tpad|ts0)_default: / {p=2}
       p==1 {print} p==1 && /^};/ {p=0}
       p==2 {print} p==2 && /^\t};/ {p=0}' "$Q/$f"
done
S=$(for f in /root/build/dtbs-orig/*.dtb; do fdtget "$f" / compatible | grep -q '^lenovo,ideapad-slim5x-oled' && echo "$f" || true; done)
echo "=================== rótulos no DTB do Ubuntu (Slim 5x)"
fdtget -p "$S" /__symbols__ | grep -E '^(i2c0|i2c2|i2c8|tlmm|remoteproc_adsp|remoteproc_cdsp|gpu_zap_shader|iris|vreg_misc_3p3|vreg_l12b_1p2|vreg_l15b_1p8|qup_i2c2_data_clk|qup_i2c8_data_clk|kybd_default|tpad_default|ts0_default|sdhc_2)$'
