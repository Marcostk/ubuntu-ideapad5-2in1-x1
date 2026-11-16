#!/bin/bash
# Base do DTB híbrido: o DTB do IdeaPad Slim 5x OLED (83HL, já embutido no kernel do Ubuntu),
# com "lenovo,ideapad-5-2in1" na frente do compatible para o stubble escolhê-lo no 83GH.
# Gera /root/build/slim5x-as-2in1.dtb e work/vmlinuz.slim5x (reserva: boota, sem teclado/touch/DSPs).
# Rodar como root no WSL, a partir da raiz do projeto.
set -euo pipefail
B=/root/build; rm -rf "$B/dtbs-orig"
python3 -I scripts/extract-dtbs.py work/usb/vmlinuz "$B/dtbs-orig"
S=$(for f in "$B"/dtbs-orig/*.dtb; do fdtget "$f" / compatible | grep -q '^lenovo,ideapad-slim5x-oled' && echo "$f" || true; done)
[ -n "$S" ] || { echo "DTB do Slim 5x não encontrado" >&2; exit 1; }
cp "$S" "$B/slim5x-as-2in1.dtb"
fdtput -t s "$B/slim5x-as-2in1.dtb" / compatible lenovo,ideapad-5-2in1 lenovo,ideapad-slim5x-oled lenovo,ideapad-5 qcom,x1p42100
fdtget "$B/slim5x-as-2in1.dtb" / compatible
python3 -I scripts/add-dtb-to-uki.py work/usb/vmlinuz "$B/slim5x-as-2in1.dtb" work/vmlinuz.slim5x
