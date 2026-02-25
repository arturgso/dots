#!/bin/bash

if command -v pacman >/dev/null 2>&1; then
    exec "$HOME/.dots/script/checkupdate-arch.sh"
fi

# Verificar atualizações do DNF
dnf_updates=$(dnf check-update --refresh -yq 2>/dev/null | tail -n +2 | grep -E 'x86_64|i686|noarch|aarch64' | awk '{print $1,$2}')
dnf_count=$(echo "$dnf_updates" | grep -c .)  # Conta linhas não vazias

# Verificar atualizações do Flatpak
flatpak_updates=""
flatpak_count=0
if command -v flatpak &> /dev/null; then
    flatpak_updates=$(flatpak remote-ls --updates --columns=application,version 2>/dev/null)
    flatpak_count=$(echo "$flatpak_updates" | grep -c .)  # Conta linhas não vazias
fi

# Total de atualizações
total_updates=$((dnf_count + flatpak_count))

# Construir tooltip
tooltip_parts=()

if [ $dnf_count -gt 0 ]; then
    dnf_tooltip=$(echo "$dnf_updates" | head -10 | sed 's/"/\\"/g')
    tooltip_parts+=("DNF Updates ($dnf_count):\n$dnf_tooltip")
fi

if [ $flatpak_count -gt 0 ]; then
    flatpak_tooltip=$(echo "$flatpak_updates" | head -10 | sed 's/"/\\"/g')
    tooltip_parts+=("Flatpak Updates ($flatpak_count):\n$flatpak_tooltip")
fi

# Juntar todas as partes do tooltip
if [ ${#tooltip_parts[@]} -gt 0 ]; then
    tooltip=$(printf "\n\n%s" "${tooltip_parts[@]}")
    tooltip="${tooltip:2}"  # Remove os primeiros \n\n
else
    tooltip="System updated"
fi

# Escapar caracteres especiais para JSON
tooltip=$(echo "$tooltip" | sed 's/\\/\\\\/g' | sed ':a;N;$!ba;s/\n/\\n/g')

alt="has-updates"
if [ $total_updates -eq 0 ]; then
    alt="updated"
fi

# Gerar JSON válido
echo "{\"text\": \"$total_updates\", \"tooltip\": \"$tooltip\", \"alt\": \"$alt\"}"
