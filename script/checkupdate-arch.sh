#!/usr/bin/env bash

set -u

# Pacman updates
pacman_updates=""
if command -v checkupdates >/dev/null 2>&1; then
  pacman_updates="$(checkupdates 2>/dev/null || true)"
else
  pacman_updates="$(pacman -Qu 2>/dev/null || true)"
fi
pacman_count=$(echo "$pacman_updates" | grep -c .)

# Flatpak updates
flatpak_updates=""
flatpak_count=0
if command -v flatpak >/dev/null 2>&1; then
  flatpak_updates="$(flatpak remote-ls --updates --columns=application,version 2>/dev/null || true)"
  flatpak_count=$(echo "$flatpak_updates" | grep -c .)
fi

total_updates=$((pacman_count + flatpak_count))
tooltip_parts=()

if [ "$pacman_count" -gt 0 ]; then
  pacman_tooltip="$(echo "$pacman_updates" | head -10 | sed 's/"/\\"/g')"
  tooltip_parts+=("Pacman Updates ($pacman_count):\n$pacman_tooltip")
fi

if [ "$flatpak_count" -gt 0 ]; then
  flatpak_tooltip="$(echo "$flatpak_updates" | head -10 | sed 's/"/\\"/g')"
  tooltip_parts+=("Flatpak Updates ($flatpak_count):\n$flatpak_tooltip")
fi

if [ "${#tooltip_parts[@]}" -gt 0 ]; then
  tooltip="$(printf "\n\n%s" "${tooltip_parts[@]}")"
  tooltip="${tooltip:2}"
else
  tooltip="System updated"
fi

tooltip="$(echo "$tooltip" | sed 's/\\/\\\\/g' | sed ':a;N;$!ba;s/\n/\\n/g')"

alt="has-updates"
if [ "$total_updates" -eq 0 ]; then
  alt="updated"
fi

echo "{\"text\": \"$total_updates\", \"tooltip\": \"$tooltip\", \"alt\": \"$alt\"}"
