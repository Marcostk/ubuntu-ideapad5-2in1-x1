#!/bin/bash
# Extrai 2 quadros/s de cada vídeo de teste de boot para work/videos/frames/<n>/
# Uso: video-frames.sh <dir com .mp4>
set -euo pipefail
cd "$1"; n=0
for f in *.mp4; do
  n=$((n+1)); o="frames/$n"; rm -rf "$o"; mkdir -p "$o"
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")
  ffmpeg -v error -i "$f" -vf fps=2 "$o/%03d.jpg"
  echo "$n: $f  ${dur}s  $(ls "$o" | wc -l) quadros"
done
