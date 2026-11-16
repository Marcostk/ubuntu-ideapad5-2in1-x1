#!/bin/bash
# UbuntoARM: lê do painel (DPCD do eDP) como ele controla o brilho. Só leitura. Uso: sudo bash ~/ubuntoarm/dpcd-brilho.sh
for d in /sys/class/drm_dp_aux_dev/*; do readlink -f "$d" | grep -q aea0000 && N=/dev/$(basename "$d"); done
rd(){ dd if="$N" bs=1 skip=$(( $1 )) count=$2 status=none | od -An -tx1; }
echo "aux=$N sysfs=$(cat /sys/class/backlight/dp_aux_backlight/brightness)"
echo "700-703 rev/cap1/cap-brilho/cap2: $(rd 0x700 4)"
echo "720-727 ctl/modo/MSB/LSB/bits/min/max/ctl: $(rd 0x720 8)"
echo "728-72a freq/var: $(rd 0x728 3)"
echo "734-736 luminância alvo: $(rd 0x734 3)"
