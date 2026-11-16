#!/bin/bash
# Extrai quadros em resolução máxima de um trecho do vídeo, para ler texto pequeno.
# Uso: video-zoom.sh <video> <inicio_s> <dur_s> <dir_saida> [fps]
set -euo pipefail
v="$1"; ss="$2"; t="$3"; o="$4"; fps="${5:-4}"
rm -rf "$o"; mkdir -p "$o"
ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$v"
ffmpeg -v error -ss "$ss" -t "$t" -i "$v" -vf "fps=$fps,scale=iw*2:ih*2:flags=lanczos" -q:v 2 "$o/%03d.jpg"
ls "$o" | wc -l
