#!/bin/bash
# Copia do Windows (partição montada) o firmware Qualcomm do notebook para firmware/windows-driverstore.
# Equivalente Linux do extract-firmware.ps1. O firmware é assinado para o aparelho e licenciado pela
# Qualcomm/Lenovo: use só o do seu próprio Windows e não redistribua.
# Uso (na raiz do projeto):  bash scripts/extract-firmware.sh /caminho/da/particao/do/Windows
#   ex.: udisksctl mount -b /dev/nvme0n1p3 -o ro   →   bash scripts/extract-firmware.sh /run/media/$USER/<id>
set -euo pipefail
WIN=${1:?informe onde a partição do Windows está montada}
DS="$WIN/Windows/System32/DriverStore/FileRepository"
[ -d "$DS" ] || { echo "não achei $DS" >&2; exit 1; }
DST=firmware/windows-driverstore
mkdir -p "$DST"
for d in "$DS"/*; do
  case "$(basename "$d")" in
    qcdx8380*|qcdxext_crd8380*|qcnspmcdm_ext_cdsp8380*|qcsubsys*|qcwlan*|qcbt*|qcadcm*|qcasd*) ;;
    *) continue ;;
  esac
  [ -d "$d" ] || continue
  mkdir -p "$DST/$(basename "$d")"
  find "$d" -maxdepth 1 -type f \( -iname '*.mbn' -o -iname '*.elf' -o -iname '*.jsn' -o -iname '*.bin' -o -iname '*.inf' \) \
    -exec cp -t "$DST/$(basename "$d")" {} +
done
for n in qcadsp8380.mbn adsp_dtbs.elf qccdsp8380.mbn cdsp_dtbs.elf qcdxkmsucpurwa.mbn qcvss8380_pa.mbn; do
  find "$DST" -name "$n" | grep -q . || echo "AVISO: faltou $n" >&2
done
echo "Firmware copiado para $(realpath "$DST")"
