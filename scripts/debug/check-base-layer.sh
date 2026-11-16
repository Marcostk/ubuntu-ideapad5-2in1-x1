#!/bin/bash
# O que o sistema instalado herda da camada base: kernel em /boot, parâmetros do GRUB, hooks de firmware do initramfs.
cd "$(dirname "$0")/../.."
B=/root/build; L=$B/minimal.list; V=7.3.0-15-qcom-x1e
echo "== /boot e grub.d na camada base"
grep -E "^squashfs-root/boot/|^squashfs-root/etc/default/grub|^squashfs-root/etc/grub.d/" $L | sed 's|squashfs-root||'
echo "== hooks do initramfs que falam de firmware/qcom"
rm -rf $B/base-peek
unsquashfs -q -d $B/base-peek work/usb/minimal.squashfs "boot/vmlinuz-$V" etc/default usr/share/initramfs-tools/hooks etc/initramfs-tools usr/share/ubuntu-x1e-settings >/dev/null 2>&1
grep -l -r -i -E "x1e80100|qcom|firmware" $B/base-peek/usr/share/initramfs-tools/hooks $B/base-peek/etc/initramfs-tools 2>/dev/null
echo "== vmlinuz da camada base == casper/vmlinuz?"
cmp $B/base-peek/boot/vmlinuz-$V work/usb/vmlinuz && echo "idênticos"
echo "== GRUB defaults"
grep -h -E "GRUB_CMDLINE|cutmem|devicetree" $B/base-peek/etc/default/grub $B/base-peek/etc/default/grub.d/* 2>/dev/null
ls $B/base-peek/etc/default/grub.d 2>/dev/null
echo "== pacote ubuntu-x1e-settings"
find $B/base-peek/usr/share/ubuntu-x1e-settings 2>/dev/null | head
grep -E "ubuntu-x1e-settings|/etc/grub.d/.*x1e|cutmem" $L | sed 's|squashfs-root||' | head
