#!/bin/bash
# UbuntoARM: teste do brilho do OLED (dp_aux_backlight). Faz uma rampa logarítmica descendo e subindo,
# mede o tempo de cada escrita e salva no pendrive. Uso no Ubuntu live:  sudo bash /cdrom/ubuntoarm-brilho.sh
# Durante o teste, observe a tela: a variação deve parecer contínua.
B=/sys/class/backlight/dp_aux_backlight
[ -w "$B/brightness" ] || { echo "rode com sudo"; exit 1; }
mount -o remount,rw /cdrom 2>/dev/null
O=/cdrom/brilho-$(date +%Y%m%d-%H%M%S).txt
orig=$(cat "$B/brightness"); max=$(cat "$B/max_brightness")
echo "max=$max original=$orig" > "$O"
# 60 passos de 100% até 1% em escala logarítmica, depois de volta
lv=$(awk -v m="$max" 'BEGIN { for (i = 0; i <= 60; i++) printf "%d\n", m * exp(log(0.01) * i / 60) }')
for v in $lv $(echo "$lv" | tac); do
  t0=$(date +%s%N); echo "$v" > "$B/brightness"; t1=$(date +%s%N)
  echo "$v $(( (t1 - t0) / 1000 ))us lido=$(cat "$B/actual_brightness")" >> "$O"
  sleep 0.05
done
echo "$orig" > "$B/brightness"; sync
awk 'NR>1 {gsub("us","",$2); s+=$2; if ($2>m) m=$2} END {printf "escritas: %d, média %d us, pior %d us\n", NR-1, s/(NR-1), m}' "$O" | tee -a "$O"
echo "Resultado salvo em $O"
