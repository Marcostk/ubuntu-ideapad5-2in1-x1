#!/bin/bash
# Extrai DTBs do vmlinuz, acha o do IdeaPad 5 2-in-1 e descompila para .dts
set -e
cd "$(dirname "$0")/../.."
command -v dtc >/dev/null || { apt-get update -qq && apt-get install -y -qq device-tree-compiler python3 >/dev/null; }
rm -rf work/dtbs && python3 -I scripts/extract-dtbs.py work/usb/vmlinuz work/dtbs
for f in work/dtbs/*.dtb; do
  c=$(fdtget "$f" / compatible 2>/dev/null | tr ' ' ',')
  m=$(fdtget "$f" / model 2>/dev/null || true)
  echo "$(basename $f)  $c  [$m]"
done
f=$(for f in work/dtbs/*.dtb; do fdtget "$f" / compatible | grep -q 'ideapad-5-2in1' && echo "$f"; done)
dtc -q -I dtb -O dts -o work/ideapad-5-2in1.dts "$f"
echo "DTS: work/ideapad-5-2in1.dts ($(wc -l < work/ideapad-5-2in1.dts) linhas) de $f"
echo "--- hwids (strings)"; strings -e l work/dtbs/hwids.bin | grep -i -E 'ideapad|83GH|lenovo' | sort -u | head -30
strings work/dtbs/hwids.bin | grep -i -E 'ideapad|83GH' | sort -u | head -30
