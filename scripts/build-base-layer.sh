#!/bin/bash
# Camada base (minimal.squashfs) com as correções do 83GH. O instalador copia esta camada para o SSD e o
# live também a usa por baixo, então o live e o sistema instalado ficam iguais.
# Rodar como root no WSL, na raiz do projeto, depois de build-all.sh. Gera work/minimal.squashfs.83gh.
set -euo pipefail
B=/root/build; R=$B/base; V=7.3.0-15-qcom-x1e; U=work/usb
[ -f work/vmlinuz.h4 ] && [ -f work/qnoc-x1e80100.ko ] && [ -d "$B/overlay/usr/lib/firmware" ] \
  || { echo "rode scripts/build-all.sh antes" >&2; exit 1; }
rm -rf "$R"; unsquashfs -q -d "$R" "$U/minimal.squashfs"

# 1. firmware do 83GH + GPU, topologia e UCM de áudio, cpufreq (a mesma árvore da camada live)
cp -a "$B/overlay/usr/lib/." "$R/usr/lib/"
cp -a "$B/overlay/usr/share/." "$R/usr/share/"
install -D -m 0644 "$B/overlay/etc/modules-load.d/ubuntoarm.conf" "$R/etc/modules-load.d/ubuntoarm.conf"

# 2. GRUB (parâmetros e cutmem do Snapdragon X) e hook do initramfs com o firmware
cp -r base-overlay/. "$R/"
chmod 0755 "$R/etc/grub.d/01_ubuntoarm" "$R/etc/initramfs-tools/hooks/ubuntoarm" "$R/usr/local/sbin/ubuntoarm-protege"
chmod 0644 "$R/etc/default/grub.d/ubuntoarm.cfg" "$R/etc/systemd/system/ubuntoarm-protege.service"
# serviço que, a cada boot do sistema instalado, bloqueia kernels no apt e fixa o GRUB no 7.3.0-15
# (o instalador refaz o banco do dpkg e perde holds feitos aqui; o serviço reaplica no primeiro boot)
ln -sf ../ubuntoarm-protege.service "$R/etc/systemd/system/multi-user.target.wants/ubuntoarm-protege.service"
# brilho do OLED: extensão do GNOME (o painel satura em 2047 e o GNOME usava 655..65535), ativa por padrão
# modo tablet manual (sensores do ADSP derrubam a placa no Linux): extensão + regra udev do "inhibited"
find "$R/usr/share/gnome-shell/extensions/oled-brilho@ubuntoarm" "$R/usr/share/gnome-shell/extensions/tablet@ubuntoarm" \
  "$R/usr/share/glib-2.0/schemas/90_ubuntoarm.gschema.override" "$R/etc/udev/rules.d/70-ubuntoarm-tablet.rules" -type f -exec chmod 0644 {} +
chmod 0755 "$R/usr/share/gnome-shell/extensions/oled-brilho@ubuntoarm" "$R/usr/share/gnome-shell/extensions/tablet@ubuntoarm"
glib-compile-schemas "$R/usr/share/glib-2.0/schemas"

# 3. módulo de interconexão com banda inicial 0
M="$R/usr/lib/modules/$V/kernel/drivers/interconnect/qcom/qnoc-x1e80100.ko.zst"
[ -f "$M" ] || { echo "módulo original não encontrado na camada base" >&2; exit 1; }
zstd -q -19 -f work/qnoc-x1e80100.ko -o "$M"
chmod 0644 "$M"  # o zstd copia o modo do .ko em /mnt/c (777)

# 4. kernel com o DTB do 83GH (cat mantém dono e permissões do arquivo original)
cmp -s "$R/boot/vmlinuz-$V" "$U/vmlinuz" || echo "AVISO: /boot/vmlinuz-$V da camada difere do casper/vmlinuz" >&2
cat work/vmlinuz.h4 > "$R/boot/vmlinuz-$V"

# 5. travar o kernel: um kernel novo do apt viria sem o DTB e sem o módulo corrigido
for p in linux-qcom-x1e linux-image-qcom-x1e linux-headers-qcom-x1e "linux-image-$V" "linux-modules-$V"; do
  echo "$p hold"
done | dpkg --admindir="$R/var/lib/dpkg" --set-selections
echo "pacotes travados: $(dpkg --admindir="$R/var/lib/dpkg" --get-selections | awk '$2=="hold" {printf "%s ", $1}')"

# 6. reempacota com a mesma compressão/bloco do original
read -r comp bs < <(unsquashfs -s "$U/minimal.squashfs" | awk '/^Compression/ {c=$2} /^Block size/ {b=$3} END {print c, b}')
# minimal.size/install-sources.yaml ficam iguais: só estimam espaço e a diferença é ~60 MB em 7,2 GB
# gera no ext4 do WSL e só depois copia: escrever direto em /mnt/c (drvfs) falha com "Cannot allocate memory"
# 4 processos e 1 GB de buffer: com 8 o xz estoura os ~7 GB de RAM do WSL ("Cannot allocate memory")
mksquashfs "$R" "$B/minimal.squashfs.83gh" -comp "$comp" -b "$bs" -noappend -quiet -processors 4 -mem 1G
cp "$B/minimal.squashfs.83gh" work/minimal.squashfs.83gh
cmp "$B/minimal.squashfs.83gh" work/minimal.squashfs.83gh
ls -l "$U/minimal.squashfs" work/minimal.squashfs.83gh
