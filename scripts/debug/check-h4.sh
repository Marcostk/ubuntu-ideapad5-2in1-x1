#!/bin/bash
# Confere no h4 (arquivo e DTB embutido no vmlinuz.h4) os repetidores eUSB, o GPIO 44 e o firmware da GPU.
cd "$(dirname "$0")/../.."
H=/root/build/h4.dtb; T=/soc@0/pinctrl@f100000
ph() { fdtget -t x "$H" "$(fdtget -t s "$H" /__symbols__ "$1")" phandle; }
echo "usb_2_hsphy phys=$(fdtget -t x "$H" /soc@0/phy@88e0000 phys)  eusb9=$(ph eusb9_repeater)"
echo "usb_1_ss2_hsphy phys=$(fdtget -t x "$H" /soc@0/phy@fde000 phys)  eusb5=$(ph eusb5_repeater)"
echo "eusb9 reset-gpios: $(fdtget -t x "$H" "$(fdtget -t s "$H" /__symbols__ eusb9_repeater)" reset-gpios)"
echo "h4.dtb gpio-reserved-ranges: $(fdtget "$H" $T gpio-reserved-ranges)"
rm -rf /tmp/h4x && python3 -I scripts/extract-dtbs.py work/vmlinuz.h4 /tmp/h4x
echo "vmlinuz.h4 (seção 50) model: $(fdtget /tmp/h4x/50.dtb / model) | reserved: $(fdtget /tmp/h4x/50.dtb $T gpio-reserved-ranges) | cam: $(fdtget -d - /tmp/h4x/50.dtb /regulator-cam-5p0 regulator-name)"
ls -l /root/build/chk-q/usr/lib/firmware/qcom/gen71500_* 2>&1
