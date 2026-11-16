#!/bin/bash
# UbuntoARM: entrega ao ADSP a configuração de sensores do Windows (via hexagonrpcd) e reinicia o daemon.
# Uso: sudo bash ~/ubuntoarm/sensores-setup.sh [pasta qcsensorsconfigcrd8380 do DriverStore]
set -euo pipefail
SRC=${1:-$(ls -d /run/media/*/*/Windows/System32/DriverStore/FileRepository/qcsensorsconfigcrd8380.inf_arm64_* | head -1)}
R=/var/lib/ubuntoarm/sensores
[ -f "$SRC/sns_reg_config" ] || { echo "config do Windows não encontrada em '$SRC'" >&2; exit 1; }
install -d -m 0755 "$R/sensors/config" "$R/socinfo"
install -d -m 0755 -o fastrpc -g fastrpc "$R/sensors/registry"
install -m 0644 "$SRC"/*.json "$SRC"/*.pb "$SRC/json.lst" "$R/sensors/config/"
install -m 0644 "$SRC/sns_reg_config" "$R/sensors/sns_reg.conf"
for f in hw_platform platform_subtype platform_subtype_id platform_version soc_id revision; do
  install -m 0644 "$SRC/$f" "$R/socinfo/$f"
done
install -d /etc/systemd/system/hexagonrpcd.service.d
cat > /etc/systemd/system/hexagonrpcd.service.d/ubuntoarm.conf <<'CONF'
# UbuntoARM: config de sensores do Windows (83GH) e registro gravável pelo ADSP
[Service]
Environment=hexagonrpcd_fw_dir=/var/lib/ubuntoarm/sensores
ReadWritePaths=/var/lib/ubuntoarm/sensores/sensors/registry
CONF
systemctl daemon-reload
systemctl restart hexagonrpcd
sleep 15
journalctl -u hexagonrpcd -b --no-pager --since -20s | tail -40
echo "--- registro gerado:"; ls -la "$R/sensors/registry" | head
