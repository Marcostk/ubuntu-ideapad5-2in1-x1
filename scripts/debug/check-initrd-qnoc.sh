#!/bin/bash
# Confere se o initrd desempacotado em /root/build/chk-q tem o qnoc modificado.
M=/root/build/chk-q/usr/lib/modules/7.3.0-15-qcom-x1e/kernel/drivers/interconnect/qcom/qnoc-x1e80100.ko.zst
ls -l "$M"
zstd -q -d -c "$M" > /tmp/q.ko && modinfo /tmp/q.ko | grep -E '^(parm|vermagic):'
strings /tmp/q.ko | grep -c ubuntoarm
