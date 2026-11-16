#!/bin/bash
# Confere o que entrou na camada base gerada (work/minimal.squashfs.83gh).
cd "$(dirname "$0")/../.."
S=/root/build/minimal.squashfs.83gh; V=7.3.0-15-qcom-x1e
unsquashfs -lls "$S" | grep -E "LENOVO/83GH/qcadsp|gen71500_sqe|Ideapad-5-tplg|modules-load.d/ubuntoarm|grub.d/ubuntoarm|grub.d/01_ubuntoarm|hooks/ubuntoarm|boot/vmlinuz-$V|qnoc-x1e80100" | sed 's/squashfs-root//'
rm -rf /tmp/bc && unsquashfs -q -d /tmp/bc "$S" "boot/vmlinuz-$V" usr/share/alsa/ucm2/Qualcomm/x1e80100/x1e80100.conf var/lib/dpkg/status \
  "usr/lib/modules/$V/kernel/drivers/interconnect/qcom/qnoc-x1e80100.ko.zst" >/dev/null
cmp /tmp/bc/boot/vmlinuz-$V work/vmlinuz.h4 && echo "vmlinuz = h4"
grep -c '\[Ii\]dea\[Pp\]ad' /tmp/bc/usr/share/alsa/ucm2/Qualcomm/x1e80100/x1e80100.conf | xargs echo "UCM corrigido:"
zstd -q -d -c /tmp/bc/usr/lib/modules/$V/kernel/drivers/interconnect/qcom/qnoc-x1e80100.ko.zst | strings | grep -c 'ubuntoarm:' | xargs echo "qnoc modificado:"
awk '/^Package: linux-(image|modules|qcom|headers-qcom)/ {p=$2} /^Status: hold/ && p {print "hold:", p} /^$/ {p=""}' /tmp/bc/var/lib/dpkg/status
