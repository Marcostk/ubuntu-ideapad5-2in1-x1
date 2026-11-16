#!/bin/bash
# UbuntoARM: coleta o estado do hardware no Ubuntu live e salva no próprio pendrive.
# Uso no Ubuntu live:  sudo bash /cdrom/ubuntoarm-diag.sh
mount -o remount,rw /cdrom 2>/dev/null || true
D=/cdrom/diag-$(date +%Y%m%d-%H%M%S)
mkdir -p "$D" 2>/dev/null || { D=$HOME/diag; mkdir -p "$D"; }
uname -a                                       > "$D/uname.txt"
cat /proc/device-tree/model                    > "$D/dt-model.txt" 2>&1
dmesg                                          > "$D/dmesg.txt"
journalctl -b --no-pager                       > "$D/journal.txt" 2>&1
lsmod                                          > "$D/lsmod.txt"
{ lsusb; lspci -nn; }                          > "$D/bus.txt" 2>&1
grep -H . /sys/class/remoteproc/*/{name,state} > "$D/remoteproc.txt" 2>&1
upower -d                                      > "$D/battery.txt" 2>&1
{ aplay -l; arecord -l; cat /proc/asound/cards; alsaucm -c "$(cat /proc/asound/card0/id 2>/dev/null)" list _verbs; } > "$D/audio.txt" 2>&1
cat /proc/bus/input/devices                    > "$D/input.txt" 2>&1
{ nmcli dev; rfkill list; }                    > "$D/net.txt" 2>&1
{ ls -l /dev/dri; dmesg | grep -i -E 'adreno|gmu|sqe|zap|msm_dpu'; } > "$D/gpu.txt" 2>&1
grep -H . /sys/devices/system/cpu/cpu*/cpufreq/{scaling_driver,scaling_cur_freq,cpuinfo_max_freq} > "$D/cpufreq.txt" 2>&1
grep -H . /sys/class/backlight/*/{type,max_brightness,brightness,actual_brightness,scale} > "$D/backlight.txt" 2>&1
paste <(cat /sys/class/thermal/thermal_zone*/type) <(cat /sys/class/thermal/thermal_zone*/temp) > "$D/thermal.txt" 2>&1
ls -l /dev/video*                              > "$D/camera.txt" 2>&1
fprintd-list "${SUDO_USER:-ubuntu}"            > "$D/fprint.txt" 2>&1
grep -H . /sys/class/dmi/id/{board_vendor,product_family,board_name,product_name} > "$D/dmi.txt" 2>&1
sync; echo "Diagnóstico salvo em $D"
