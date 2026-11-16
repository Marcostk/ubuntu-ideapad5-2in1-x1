#!/bin/bash
# UbuntoARM: repara o Ubuntu instalado no SSD a partir do pendrive live e o protege contra atualizações.
# - reaplica kernel h4, módulo de interconexão, firmware, áudio, GRUB e hook do initramfs (copiados do live)
# - remove kernels que não sejam o 7.3.0-15 corrigido e os metapacotes que puxam kernels novos
# - instala o serviço ubuntoarm-protege (bloqueio no apt, GRUB fixo, desvio do UCM) e o roda
# Uso no Ubuntu live (pendrive, opção 1), DEPOIS da coleta:  sudo bash /cdrom/ubuntoarm-reparo.sh
set -euo pipefail
V=7.3.0-15-qcom-x1e
[ "$(id -u)" = 0 ] || { echo "rode com sudo"; exit 1; }
cmp -s /boot/vmlinuz-$V /cdrom/casper/vmlinuz.h4 || { echo "este live não está com o kernel h4; boote a opção 1 do pendrive"; exit 1; }
[ -f /cdrom/ubuntoarm-protege ] || { echo "falta /cdrom/ubuntoarm-protege no pendrive"; exit 1; }

T=/mnt/ubuntoarm-alvo; mkdir -p "$T"; P=""
for p in $(lsblk -lnpo NAME,FSTYPE | awk '$1 ~ /nvme/ && $2 == "ext4" {print $1}'); do
  mount "$p" "$T" 2>/dev/null || continue
  [ -f "$T/etc/os-release" ] && [ -d "$T/usr/lib/modules/$V" ] && { P=$p; break; }
  umount "$T"
done
[ -n "$P" ] || { echo "Ubuntu instalado (com o kernel $V) não encontrado no SSD"; exit 1; }
echo "Ubuntu instalado em $P"
trap 'for m in run sys proc dev; do umount -l "$T/$m" 2>/dev/null || true; done; umount -l "$T" 2>/dev/null || true' EXIT

# 1. kernel com o DTB do 83GH e módulo de interconexão corrigido
cat /boot/vmlinuz-$V > "$T/boot/vmlinuz-$V"
Q=usr/lib/modules/$V/kernel/drivers/interconnect/qcom/qnoc-x1e80100.ko.zst
install -m 0644 "/$Q" "$T/$Q"

# 2. firmware do 83GH e da GPU, topologia de áudio, cpufreq, GRUB, hook do initramfs e serviço de proteção
mkdir -p "$T/usr/lib/firmware/qcom/x1p42100/LENOVO"
cp -a /usr/lib/firmware/qcom/x1p42100/LENOVO/83GH "$T/usr/lib/firmware/qcom/x1p42100/LENOVO/"
cp -a /usr/lib/firmware/qcom/gen71500_sqe.fw* /usr/lib/firmware/qcom/gen71500_gmu.bin* "$T/usr/lib/firmware/qcom/"
cp -a /usr/lib/firmware/qcom/x1e80100/X1E80100-LENOVO-Ideapad-5-tplg.bin* "$T/usr/lib/firmware/qcom/x1e80100/"
for f in etc/modules-load.d/ubuntoarm.conf etc/default/grub.d/ubuntoarm.cfg etc/grub.d/01_ubuntoarm etc/initramfs-tools/hooks/ubuntoarm; do
  install -D -m "$(stat -c %a "/$f")" "/$f" "$T/$f"
done
install -D -m 0755 /cdrom/ubuntoarm-protege "$T/usr/local/sbin/ubuntoarm-protege"
install -D -m 0644 /cdrom/ubuntoarm-protege.service "$T/etc/systemd/system/ubuntoarm-protege.service"
ln -sf ../ubuntoarm-protege.service "$T/etc/systemd/system/multi-user.target.wants/ubuntoarm-protege.service"
# versão anterior deste reparo punha o GRUB_DEFAULT aqui; agora fica em ubuntoarm-default.cfg
sed -i '/GRUB_DEFAULT=/d; /kernel com as correções do 83GH/d' "$T/etc/default/grub.d/ubuntoarm.cfg"

# 3. dentro do sistema instalado
for m in dev proc sys run; do mount --bind "/$m" "$T/$m"; done
alvo() { chroot "$T" env DEBIAN_FRONTEND=noninteractive LC_ALL=C "$@"; }
alvo apt-mark manual "linux-image-$V" "linux-modules-$V"
alvo apt-mark hold "linux-image-$V" "linux-modules-$V"
# kernels que não são o corrigido + metapacotes que puxam kernels novos
remover=$(alvo dpkg-query -W -f='${Package} ${db:Status-Abbrev}\n' 'linux-image-*' 'linux-modules-*' 'linux-headers-*' \
            'linux-tools-*' 'linux-qcom-x1e*' 'linux-*-qcom-x1e' 2>/dev/null \
          | awk '$2 ~ /^[ih]i/ {print $1}' | grep -v -e "7.3.0-15" -e '^linux-tools-common$' | sort -u | xargs || true)
if [ -n "$remover" ]; then
  echo "removendo: $remover"
  alvo apt-mark unhold $remover >/dev/null 2>&1 || true
  alvo apt-get -y purge $remover
fi
alvo /usr/local/sbin/ubuntoarm-protege "$(blkid -s UUID -o value "$P")"
alvo update-initramfs -u -k "$V"
alvo update-grub

echo "--- conferência"
alvo lsinitramfs "/boot/initrd.img-$V" | grep -c -E '83GH|gen71500' | xargs echo "firmware no initramfs:"
grep -E '^GRUB_DEFAULT' "$T/etc/default/grub.d/ubuntoarm-default.cfg"
grep -m1 -E "^\s*linux\s" "$T/boot/grub/grub.cfg" | sed 's/^\s*/primeira entrada: /' | cut -c1-90
echo "kernels no sistema: $(ls "$T/usr/lib/modules" | xargs)"
alvo apt-mark showhold | xargs echo "em hold:"
alvo apt-cache policy linux-image-qcom-x1e 2>/dev/null | grep -E 'Candidat' || true
sync
echo "Reparo concluído. Reinicie, tire o pendrive e boote pelo SSD."
