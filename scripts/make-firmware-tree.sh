#!/bin/bash
# Monta usr/lib/firmware/qcom/x1p42100/LENOVO/83GH a partir da cópia do DriverStore do Windows.
# Os nomes seguem os firmware-name do DTS do 83GH; os .jsn são lidos pelo pd-mapper.
# Uso: make-firmware-tree.sh <firmware/windows-driverstore> <raiz de saída>
set -euo pipefail
SRC="$1"; ROOT="$2"
# usr/lib, não lib: no Ubuntu /lib é symlink e uma camada com lib/ real o esconderia
DST="$ROOT/usr/lib/firmware/qcom/x1p42100/LENOVO/83GH"
mkdir -p "$DST"
for f in qcdxkmsucpurwa.mbn qcvss8380_pa.mbn qcadsp8380.mbn adsp_dtbs.elf qccdsp8380.mbn cdsp_dtbs.elf \
         adspr.jsn adsps.jsn adspua.jsn battmgr.jsn cdspr.jsn; do
  n=$(find "$SRC" -name "$f" | head -1)
  [ -n "$n" ] || { echo "FALTA: $f" >&2; exit 1; }
  install -m 0644 "$n" "$DST/$f"
done
ls -l "$DST"
