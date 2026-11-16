#!/bin/bash
# UbuntoARM: instala o tuned-ppd (substitui o power-profiles-daemon) com os modos Economia/Equilibrado/Desempenho.
# Uso: sudo bash extras/modos-de-energia/instalar.sh
set -euo pipefail
cd "$(dirname "$0")"
apt-get install -y tuned-ppd
install -d /etc/tuned/profiles
for p in etc/tuned/profiles/*; do install -D -m 0644 "$p/tuned.conf" "/$p/tuned.conf"; done
install -m 0644 etc/tuned/ppd.conf /etc/tuned/ppd.conf
systemctl enable --now tuned tuned-ppd
systemctl restart tuned tuned-ppd
sleep 3
busctl --system get-property org.freedesktop.UPower.PowerProfiles /org/freedesktop/UPower/PowerProfiles org.freedesktop.UPower.PowerProfiles ActiveProfile
