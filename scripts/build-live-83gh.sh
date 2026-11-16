#!/bin/bash
# Gera os arquivos do pendrive live para o IdeaPad 5 2-in-1 (83GH):
#   work/vmlinuz.83gh                       kernel com o DTB do 83GH embutido
#   work/initrd.83gh                        initrd + firmware do Windows + topologia de áudio
#   work/minimal.standard.live.squashfs.83gh camada live + firmware + topologia + UCM corrigido
# Rodar como root no WSL, a partir da raiz do projeto. Requer work/usb/ com a cópia do pendrive.
set -euo pipefail
P=$(pwd); U=$P/work/usb; B=/root/build; O=$B/overlay
[ -f "$U/vmlinuz" ] || { echo "rode scripts/prepare.sh antes" >&2; exit 1; }

# 1. kernel com o DTB do jglathe (opcional: só se build-dtb.sh já rodou; esse DTB ainda reinicia o 83GH)
[ -f work/x1p42100-lenovo-ideapad-5-2in1.dtb ] && \
  python3 -I scripts/add-dtb-to-uki.py "$U/vmlinuz" work/x1p42100-lenovo-ideapad-5-2in1.dtb work/vmlinuz.83gh

# 2. arquivos extras
rm -rf "$O" "$B/lower"
bash scripts/make-firmware-tree.sh firmware/windows-driverstore "$O" >/dev/null
# no Ubuntu a topologia do T14s é symlink para a do Surface Laptop 7 (Romulus)
TPLG=usr/lib/firmware/qcom/x1e80100/X1E80100-Romulus-tplg.bin.zst
UCM=usr/share/alsa/ucm2/Qualcomm/x1e80100/x1e80100.conf
# GPU Adreno X1-45: o msm carrega no initrd e não tenta de novo depois, então o SQE/GMU vão no initrd
GPU="usr/lib/firmware/qcom/gen71500_sqe.fw.zst usr/lib/firmware/qcom/gen71500_gmu.bin.zst"
unsquashfs -q -d "$B/lower" "$U/minimal.squashfs" "$TPLG" "$UCM" $GPU >/dev/null
for g in $GPU; do install -D -m 0644 "$B/lower/$g" "$O/$g"; done
# topologia: mesmo layout do T14s/Romulus (2 WSA, 2 DMIC, WCD), como no patch do Jens Glathe; cópia real para valer no initrd
install -D -m 0644 "$B/lower/$TPLG" "$O/usr/lib/firmware/qcom/x1e80100/X1E80100-LENOVO-Ideapad-5-tplg.bin.zst"
# UCM: a regex do Ubuntu procura "Ideapad", mas o DMI do 83GH diz "IdeaPad"
install -d "$O/$(dirname $UCM)"
sed 's/Ideapad\.\*5\.\*/[Ii]dea[Pp]ad.*5.*/' "$B/lower/$UCM" > "$O/$UCM"
grep -q '\[Ii\]dea\[Pp\]ad' "$O/$UCM" || { echo "patch do UCM não aplicou" >&2; exit 1; }
# serviço que grava o log do boot no pendrive (live-overlay/)
cp -r live-overlay/. "$O/"
chmod 0755 "$O/usr/local/sbin/ubuntoarm-bootlog"
chmod 0644 "$O/etc/systemd/system/ubuntoarm-bootlog.service" "$O/etc/modules-load.d/ubuntoarm.conf"
install -d "$O/etc/systemd/system/sysinit.target.wants"
ln -sf ../ubuntoarm-bootlog.service "$O/etc/systemd/system/sysinit.target.wants/ubuntoarm-bootlog.service"
echo "LENOVO-IdeaPad 5 2-in-1 14Q8X9-LNVNB161216" | grep -q -E "LENOVO.*(Think(Pad T14s Gen 6.*|Book 16 G7 QOY)|[Ii]dea[Pp]ad.*5.*)" && echo "regex UCM casa com o DMI do 83GH"

# 3. initrd: cpio sem compressão com o firmware ANTES do original (como o microcode);
#    o initramfs do kernel não cria diretórios pais, então usr e usr/lib vão explícitos
(cd "$O" && { echo usr; echo usr/lib; find usr/lib/firmware | LC_ALL=C sort; } | cpio -o -H newc -R 0:0 --quiet) > "$B/fw.cpio"
cat "$B/fw.cpio" "$U/initrd" > work/initrd.83gh

# 4. camada live
rm -rf "$B/live"
unsquashfs -q -d "$B/live" "$U/minimal.standard.live.squashfs" >/dev/null
cp -a "$O/." "$B/live/"
[ -L "$B/live/lib" ] || [ ! -e "$B/live/lib" ] || { echo "camada live ganhou lib/ real" >&2; exit 1; }
mksquashfs "$B/live" work/minimal.standard.live.squashfs.83gh -comp xz -b 131072 -noappend -quiet
ls -l work/initrd.83gh work/minimal.standard.live.squashfs.83gh
