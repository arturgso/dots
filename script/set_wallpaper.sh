#!/usr/bin/env bash

set -euo pipefail

awww_bin="$(command -v awww || true)"
awww_daemon_bin="$(command -v awww-daemon || true)"

if [[ -z "$awww_bin" || -z "$awww_daemon_bin" ]]; then
  echo "awww/awww-daemon não encontrados no PATH." >&2
  exit 1
fi

shopt -s nullglob
default_image=""
for candidate in "$HOME"/.default.*; do
  lower_name=${candidate,,}
  if [[ $lower_name =~ \.(png|jpe?g|webp|bmp)$ ]]; then
    default_image="$candidate"
    break
  fi
done
shopt -u nullglob

if [[ -z $default_image ]]; then
  echo "Nenhuma imagem .default.* encontrada na home." >&2
  exit 1
fi

if ! pgrep -x awww-daemon >/dev/null 2>&1; then
  "$awww_daemon_bin" >/dev/null 2>&1 &
  sleep 0.5
fi

"$awww_bin" img "$default_image"
