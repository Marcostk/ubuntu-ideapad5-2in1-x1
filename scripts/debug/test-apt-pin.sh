#!/bin/bash
# Testa o bloqueio de kernels do ubuntoarm-protege com o apt do WSL, num diretório de preferências temporário.
cd "$(dirname "$0")/../.."
D=$(mktemp -d)
sed -n "/<<'EOF'/,/^EOF/p" base-overlay/usr/local/sbin/ubuntoarm-protege | sed '1d;$d' > "$D/ubuntoarm-kernel"
cat "$D/ubuntoarm-kernel"
for p in linux-image-generic linux-generic linux-headers-generic linux-tools-common linux-firmware firefox; do
  c=$(apt-cache -o Dir::Etc::PreferencesParts="$D" policy "$p" 2>&1 | awk '/Candidat/ {print $2}')
  echo "$p -> candidato: ${c:-?}"
done
apt-cache -o Dir::Etc::PreferencesParts="$D" policy 2>&1 | grep -i -E 'error|warn' | head
rm -rf "$D"
