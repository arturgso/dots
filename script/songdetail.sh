#!/usr/bin/env bash

# Exibe título e artista da faixa atual usando playerctl
# Saída: "<titulo>  <artista>"

song_info=$(playerctl metadata --format '{{title}}  {{artist}}')

echo "$song_info"
