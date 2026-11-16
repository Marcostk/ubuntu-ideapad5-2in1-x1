#!/bin/bash
# initrd.qnoc = firmware do 83GH (cpio sem compressão) + initrd original com qnoc-x1e80100.ko trocado
# pelo módulo de kernel/qnoc-83gh (banda inicial 0). Rodar como root no WSL, a partir da raiz do projeto.
set -euo pipefail
B=/root/build; R=$B/initrd-q; V=7.3.0-15-qcom-x1e
M=usr/lib/modules/$V/kernel/drivers/interconnect/qcom/qnoc-x1e80100.ko.zst
[ -f work/qnoc-x1e80100.ko ] && [ -f "$B/fw.cpio" ] || { echo "rode build-qnoc.sh e build-live-83gh.sh antes" >&2; exit 1; }
rm -rf "$R"; unmkinitramfs work/usb/initrd "$R"
[ ! -d "$R/main" ] || { echo "initrd tem early/main: ajustar o script" >&2; exit 1; }
[ -f "$R/$M" ] || { echo "módulo original não encontrado no initrd" >&2; exit 1; }
zstd -q -19 -f work/qnoc-x1e80100.ko -o "$R/$M"
chmod 0644 "$R/$M"  # o zstd copia o modo do .ko em /mnt/c (777)
(cd "$R" && find . -mindepth 1 | LC_ALL=C sort | cpio -o -H newc -R 0:0 --quiet | zstd -q -19 -T0) > "$B/main-q.cpio.zst"
cat "$B/fw.cpio" "$B/main-q.cpio.zst" > work/initrd.qnoc
# confere: o initrd novo abre e tem o módulo modificado
rm -rf "$B/chk-q"; unmkinitramfs work/initrd.qnoc "$B/chk-q"
[ "$(zstd -q -d -c "$B/chk-q/$M" | strings | grep -c 'ubuntoarm:')" -gt 0 ] && echo "initrd.qnoc OK: módulo modificado presente"
ls "$B/chk-q/usr/lib/firmware/qcom/x1p42100/LENOVO/83GH" | wc -l | xargs echo "arquivos de firmware 83GH:"
ls -l work/initrd.qnoc
