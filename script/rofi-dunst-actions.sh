#!/usr/bin/env bash

# Custom wrapper so dunst action pickers share the same rofi styling
# while still returning the action ID (not the label) back to dunst.

dir="$HOME/.dots/rofi/launchers/type-2"
theme='style-1'

mapfile -t lines || exit 1
(( ${#lines[@]} )) || exit 0

labels=()
ids=()
max_label_len=0

for line in "${lines[@]}"; do
  # Dunst sends "id\tLabel". If no tab is present, show the whole line.
  IFS=$'\t' read -r id label <<<"$line"
  if [[ -z "$label" ]]; then
    label="$id"
  fi
  ids+=("$id")
  labels+=("$label")
  (( ${#label} > max_label_len )) && max_label_len=${#label}
done

lines_count=${#labels[@]}
(( lines_count == 0 )) && exit 0
(( lines_count > 6 )) && lines_count=6

# Approximate width: base 220px plus 9px per character of the longest label.
width=$((220 + max_label_len * 9))
(( width > 640 )) && width=640

selection_index=$(
  printf '%s\n' "${labels[@]}" | \
  rofi -dmenu \
       -format i \
       -theme-str "window { width: ${width}px; }" \
       -theme-str "listview { lines: ${lines_count}; }" \
       -theme "${dir}/${theme}.rasi" \
       "$@"
)

[[ -z "$selection_index" ]] && exit 1
printf '%s\n' "${ids[$selection_index]}"
