#!/bin/bash
# Brilho máximo (YMAX) da área da tela, 2 quadros/s, para achar quando há texto e quando a tela apaga.
# Uso: video-brightness.sh <dir com .mp4>
cd "$1"; n=0
for f in *.mp4; do
  n=$((n+1)); echo "== $n"
  ffmpeg -v info -nostats -i "$f" -vf "fps=2,crop=iw*0.6:ih*0.7:iw*0.2:ih*0.05,signalstats,metadata=print:key=lavfi.signalstats.YMAX" -f null - 2>&1 \
    | grep -o 'YMAX=[0-9]*' | cut -d= -f2 | awk '{printf "%d:%s ", NR, $1} END {print ""}'
done
