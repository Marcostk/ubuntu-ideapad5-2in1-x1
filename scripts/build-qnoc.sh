#!/bin/bash
# Compila kernel/qnoc-83gh contra os headers 7.3.0-15-qcom-x1e e copia o .ko para work/.
# Rodar como root no WSL, a partir da raiz do projeto.
set -euo pipefail
command -v make >/dev/null && command -v gcc-15 >/dev/null || \
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq make gcc-15 libc6-dev >/dev/null
B=/root/build/qnoc; rm -rf "$B"; cp -r kernel/qnoc-83gh "$B"
make -C "$B" CC=gcc-15 2>&1 | grep -v -E '^make|^\s*$' || true
modinfo "$B/qnoc-x1e80100.ko" | grep -E '^(name|vermagic|parm|alias):' | head -6
cp "$B/qnoc-x1e80100.ko" work/qnoc-x1e80100.ko
