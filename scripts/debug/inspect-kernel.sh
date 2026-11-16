#!/bin/bash
# Uso: inspect-kernel.sh <vmlinuz>  — procura DTBs embutidos (stubble) para o IdeaPad 83GH
set -e
k="$1"; w=$(mktemp -d)
file "$k"
objdump -h "$k" 2>/dev/null | grep -E '^\s+[0-9]+ ' || true
# stubble guarda os DTBs numa seção .dtbs; zboot comprime o kernel mas não essa seção
grep -a -o -E 'lenovo,[a-z0-9,-]*ideapad[a-z0-9,-]*|x1p42100-[a-z0-9-]+' "$k" | sort | uniq -c || echo "nenhuma string ideapad/x1p42100 encontrada"
rm -rf "$w"
