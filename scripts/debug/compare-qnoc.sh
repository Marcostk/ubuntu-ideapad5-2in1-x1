#!/bin/bash
# Compara o qnoc-x1e80100.ko modificado com o original do initrd (vermagic, parâmetros, tamanho das tabelas).
set -euo pipefail
O=/root/build/qnoc-orig.ko
zstd -q -d -f /root/build/initrd-x/usr/lib/modules/7.3.0-15-qcom-x1e/kernel/drivers/interconnect/qcom/qnoc-x1e80100.ko.zst -o "$O"
for k in "$O" work/qnoc-x1e80100.ko; do
  echo "== $k"
  modinfo "$k" | grep -E '^(vermagic|parm|depends):'
  objdump -h "$k" | awk '$2 ~ /^\.(data|rodata|bss)$/ {print "  ", $2, $3}'
done
