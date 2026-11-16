#!/bin/bash
# Lista topologias de áudio e perfis UCM x1e nas camadas squashfs do pendrive.
# Uso: inspect-audio.sh <dir com *.squashfs>
set -euo pipefail
for s in "$1"/minimal.squashfs "$1"/minimal.standard.squashfs "$1"/minimal.standard.live.squashfs; do
  echo "=== $(basename "$s")"
  unsquashfs -l "$s" 2>/dev/null | grep -i -E 'tplg|ucm2/(Qualcomm/x1e|conf\.d/x1e)|firmware/qcom/x1p42100|firmware/qcom/x1e80100/LENOVO' | sed 's|squashfs-root||' | head -60 || true
done
