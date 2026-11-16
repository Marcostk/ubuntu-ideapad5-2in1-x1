#!/bin/bash
# Analisa a cópia do Ubuntu instalado feita por read-ubuntu-disk.py (work/ubuntu-disk).
cd "$(dirname "$0")/../../work/ubuntu-disk"
J=var/log/journal
echo "== boots (kernel de cada um)"
journalctl -D $J --list-boots --no-pager 2>/dev/null | tail -8
for b in $(journalctl -D $J --list-boots --no-pager 2>/dev/null | awk 'NR>1 {print $1}' | tail -6); do
  k=$(journalctl -D $J -b "$b" -k --no-pager 2>/dev/null | grep -m1 -o 'Linux version [^ ]*')
  last=$(journalctl -D $J -b "$b" -o short-monotonic --no-pager 2>/dev/null | tail -1 | cut -c1-140)
  echo "boot $b: $k | último: $last"
done
echo "== initrd 7.3.0-15: firmware 83GH/GPU e qnoc"
lsinitramfs boot/initrd.img-7.3.0-15-qcom-x1e | grep -c -E '83GH|gen71500' | xargs echo "arquivos de firmware:"
echo "== Brave"
journalctl -D $J --no-pager 2>/dev/null | grep -i -E 'brave' | grep -i -E 'error|fail|segfault|crash|denied|trap' | tail -8 | cut -c1-220
