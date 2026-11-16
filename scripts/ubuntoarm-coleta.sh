#!/bin/bash
# UbuntoARM: coleta, SÓ LEITURA, o estado do Ubuntu instalado no SSD a partir do pendrive live.
# Uso no Ubuntu live (pendrive, opção 1):  sudo bash /cdrom/ubuntoarm-coleta.sh
V=7.3.0-15-qcom-x1e
mount -o remount,rw /cdrom 2>/dev/null
D=/cdrom/coleta-$(date +%Y%m%d-%H%M%S); mkdir -p "$D" || { D=$HOME/coleta; mkdir -p "$D"; }
lsblk -f -o NAME,FSTYPE,LABEL,SIZE,MOUNTPOINTS > "$D/lsblk.txt" 2>&1
efibootmgr -v > "$D/efibootmgr.txt" 2>&1

# partição ext4 do SSD que tem um Ubuntu instalado
T=/mnt/ubuntoarm-alvo; mkdir -p "$T"; P=""
for p in $(lsblk -lnpo NAME,FSTYPE | awk '$1 ~ /nvme/ && $2 == "ext4" {print $1}'); do
  mount -o ro "$p" "$T" 2>/dev/null || continue
  [ -f "$T/etc/os-release" ] && { P=$p; break; }
  umount "$T"
done
[ -n "$P" ] || { echo "Ubuntu instalado não encontrado no SSD (veja $D/lsblk.txt)"; exit 1; }
echo "$P" > "$D/particao.txt"

{ ls -l --time-style=full-iso "$T/boot"
  echo "--- vmlinuz instalado == h4 do pendrive?"
  cmp "$T/boot/vmlinuz-$V" /cdrom/casper/vmlinuz.h4 && echo SIM
  echo "--- qnoc modificado presente?"
  zstd -q -d -c "$T/usr/lib/modules/$V/kernel/drivers/interconnect/qcom/qnoc-x1e80100.ko.zst" | strings | grep -c 'ubuntoarm:'
  echo "--- módulos de kernel instalados"; ls "$T/usr/lib/modules"
  echo "--- initrd do $V tem o firmware 83GH?"
  lsinitramfs "$T/boot/initrd.img-$V" 2>/dev/null | grep -E '83GH|gen71500|qnoc' ; } > "$D/boot.txt" 2>&1
dpkg --admindir="$T/var/lib/dpkg" --get-selections | awk '$2 == "hold"' > "$D/holds.txt"
dpkg --admindir="$T/var/lib/dpkg" -l 'linux-*' 'grub*' 'shim*' 'initramfs-tools*' 'ubuntu-x1e*' 'linux-firmware*' 2>/dev/null \
  | awk '$1 ~ /^[a-z]i/' > "$D/pacotes.txt"
cp "$T"/var/log/apt/history.log "$D/" 2>/dev/null
tail -n 400 "$T/var/log/apt/term.log" > "$D/apt-term.txt" 2>/dev/null
ls -l "$T/etc/apt/sources.list.d" > "$D/fontes-apt.txt" 2>&1
grep -E '^\s*(menuentry|submenu|linux|initrd|set default)' "$T/boot/grub/grub.cfg" > "$D/grub-menu.txt" 2>&1
ls -l "$T/etc/default/grub.d" "$T/etc/grub.d" "$T/etc/initramfs-tools/hooks" "$T/etc/modules-load.d" >> "$D/grub-menu.txt" 2>&1

# logs dos últimos boots do sistema instalado (o journal fica no disco)
J="$T/var/log/journal"
journalctl -D "$J" --list-boots --no-pager > "$D/boots.txt" 2>&1
for b in 0 -1 -2 -3; do
  journalctl -D "$J" -b "$b" -o short-monotonic --no-pager 2>/dev/null | tail -n 600 > "$D/journal-boot$b.txt"
  journalctl -D "$J" -b "$b" -k -o short-monotonic --no-pager 2>/dev/null | tail -n 300 > "$D/kernel-boot$b.txt"
done
journalctl -D "$J" --no-pager -o short-iso 2>/dev/null | grep -i -E 'brave' | tail -n 200 > "$D/brave.txt"

umount "$T"; sync
echo "Coleta salva em $D"
