#!/bin/bash
# Compara permissões de alguns arquivos entre o initrd original e o novo (desempacotados).
for d in /root/build/initrd-x /root/build/chk-q; do
  echo "== $d"; stat -c '%a %U %n' "$d/init" "$d/usr/lib/modules/7.3.0-15-qcom-x1e/kernel/drivers/nvme/host/nvme.ko.zst" "$d/usr/bin" 2>&1
done
umask
