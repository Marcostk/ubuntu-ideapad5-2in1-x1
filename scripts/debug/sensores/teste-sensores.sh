#!/bin/bash
# UbuntoARM: teste dos sensores do ADSP, passo a passo, com tudo gravado no disco (fsync por linha).
# Se o notebook resetar, o fim dos arquivos em $D mostra o último passo e as últimas mensagens.
# Uso: sudo bash ~/ubuntoarm/teste-sensores.sh
U=${SUDO_USER:-$USER}; H=$(getent passwd "$U" | cut -d: -f6)
D=$H/ubuntoarm/testes/$(date +%Y%m%d-%H%M%S)
mkdir -p "$D"
P=$D/passos.txt

# grava cada linha da entrada em $1 com hora, forçando para o disco a cada linha
fsl() { while IFS= read -r l; do printf '%s %s\n' "$(date +%T.%N | cut -c1-12)" "$l" >> "$1"; sync "$1"; done; }
passo() { echo "COMEÇANDO: $*" | fsl "$P"; }
ok() { echo "OK: $*" | fsl "$P"; }

passo "0 loggers (kernel e hexagonrpcd) em $D"
journalctl -k -f -n 0 -o short-monotonic | fsl "$D/kernel.txt" &
sleep 2; ok 0

REG=/var/lib/ubuntoarm/sensores/sensors/registry
if [ "${SEM_SECUREDB:-0}" = 1 ] && [ -f "$REG/sns_secure_database.bin" ]; then
  passo "0b escondendo sns_secure_database.bin (backup em /var/lib/ubuntoarm/sensores/)"
  mv "$REG/sns_secure_database.bin" /var/lib/ubuntoarm/sensores/sns_secure_database.bin.bak; sync; ok 0b
fi

passo "0c insmod voto de banda do motor de criptografia (ubuntoarm_ce_vote)"
insmod $H/ubuntoarm/src/ce-vote/ubuntoarm_ce_vote.ko 2>&1 | fsl "$P"
sleep 3; dmesg | grep -iE 'ce-vote|ubuntoarm|1dfa000' | tail -3 | fsl "$P"
ok "0c ($(lsmod | grep -c ubuntoarm_ce_vote) módulo carregado)"

passo "1 hexagonrpcd corrigido direto (fremove + log detalhado), cada linha com fsync"
LD_LIBRARY_PATH=/usr/local/lib/ubuntoarm/hexagonrpc stdbuf -oL -eL \
  /usr/local/lib/ubuntoarm/hexagonrpc/hexagonrpcd -f /dev/fastrpc-adsp -d adsp -s -R /var/lib/ubuntoarm/sensores 2>&1 \
  | fsl "$D/hexagonrpcd.txt" &
ok 1

passo "2 só observando 90 s, sem consultar sensores"
for t in $(seq 5 5 90); do sleep 5; echo "vivo t=${t}s hexagonrpcd=$(pgrep -f lib/ubuntoarm/hexagonrpc/hexagonrpcd >/dev/null && echo rodando || echo parado)" | fsl "$P"; done
ok 2

passo "3 qrtr-lookup (lista serviços do QRTR, só leitura)"
timeout 5 qrtr-lookup 2>&1 | fsl "$D/qrtr.txt"; ok 3

passo "4 observando mais 60 s"
for t in $(seq 5 5 60); do sleep 5; echo "vivo t=${t}s" | fsl "$P"; done
ok 4

passo "5 libssc: procurar acelerômetro (o passo que antecedeu o 1o reset)"
sudo -u "$U" timeout 20 python3 -u "$H/ubuntoarm/ssc_accel.py" 2>&1 | fsl "$D/acelerometro.txt"
ok 5

passo "6 observando mais 60 s"
for t in $(seq 5 5 60); do sleep 5; echo "vivo t=${t}s" | fsl "$P"; done
ok 6

passo "FIM: sem reset. hexagonrpcd continua rodando."
kill %1 2>/dev/null
chown -R "$U": "$H/ubuntoarm/testes"
echo "Resultado em $D"
