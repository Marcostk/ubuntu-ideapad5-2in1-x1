#!/bin/bash
# Prepara o ambiente de build no WSL (Ubuntu arm64) a partir da ISO/pendrive Ubuntu 26.10 arm64+x1e.
# Uso (como root, na raiz do projeto):  bash scripts/prepare.sh /mnt/e
#   (no WSL, monte o pendrive antes:  mkdir -p /mnt/e && mount -t drvfs E: /mnt/e)
set -euo pipefail
SRC="${1:?uso: prepare.sh <raiz da ISO ou do pendrive>}"
V=7.3.0-15-qcom-x1e
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq device-tree-compiler python3 squashfs-tools cpio zstd binutils file \
  initramfs-tools-core make gcc-15 libc6-dev >/dev/null
mkdir -p work/usb
# só a primeira vez: estes são os originais que os scripts modificam
for f in vmlinuz initrd minimal.squashfs minimal.standard.squashfs minimal.standard.live.squashfs install-sources.yaml; do
  [ -f "work/usb/$f" ] || cp "$SRC/casper/$f" work/usb/
done
[ -f work/usb/grub.cfg.orig ] || cp "$SRC/boot/grub/grub.cfg" work/usb/grub.cfg.orig
grep -q "linux-image-$V" "$SRC/casper/minimal.manifest" || echo "AVISO: a ISO não tem o kernel $V; kernel/qnoc-83gh e os scripts foram feitos para ele" >&2
# headers do kernel (para compilar o módulo qnoc) direto da imagem
mkdir -p /root/build
[ -d /root/build/hdr/usr/src/linux-headers-$V ] || unsquashfs -q -d /root/build/hdr work/usb/minimal.squashfs \
  usr/src/linux-headers-$V usr/src/linux-qcom-x1e-headers-${V%-qcom-x1e} >/dev/null
echo "pronto: work/usb/ e /root/build/hdr"
