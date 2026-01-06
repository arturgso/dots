#!/usr/bin/env bash

## Adaptado para: Hyprland + hyprlock (fallback: swaylock / swaylock-effects)
## Autor original: Aditya Shakya (@adi1090x)
## Adaptação: Delta (GPT)

# Diretório e tema do Rofi
dir="$HOME/.dots/rofi/powermenu/type-2"
theme='style-7'

# Informações do sistema
uptime="$(uptime -p | sed -e 's/up //g')"
host="$(hostname)"

# Ícones (Nerd Fonts)
shutdown=''
reboot=''
lock=''
suspend=''
logout=''
yes=''
no=''

# Comando base do rofi
rofi_cmd() {
  rofi -dmenu \
    -p "Uptime: $uptime" \
    -mesg "Select an option — Host: $host" \
    -theme "${dir}/${theme}.rasi"
}

# Confirmação
confirm_cmd() {
  rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
    -theme-str 'mainbox {children: [ "message", "listview" ];}' \
    -theme-str 'listview {columns: 2; lines: 1;}' \
    -theme-str 'element-text {horizontal-align: 0.5;}' \
    -theme-str 'textbox {horizontal-align: 0.5;}' \
    -dmenu \
    -p 'Confirmation' \
    -mesg 'Are you sure?' \
    -theme "${dir}/${theme}.rasi"
}

confirm_exit() {
  echo -e "$yes\n$no" | confirm_cmd
}

# Menu principal
run_rofi() {
  echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Execução das ações
run_cmd() {
  selected="$(confirm_exit)"
  if [[ "$selected" == "$yes" ]]; then
    case $1 in
    --shutdown)
      systemctl poweroff
      ;;
    --reboot)
      systemctl reboot
      ;;
    --suspend)
      mpc -q pause 2>/dev/null
      amixer set Master mute 2>/dev/null
      systemctl suspend
      ;;
    --logout)
      if command -v hyprctl &>/dev/null && [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
        hyprctl dispatch exit 0
      elif command -v niri &>/dev/null; then
        niri msg action quit
      elif command -v swaymsg &>/dev/null; then
        swaymsg exit
      else
        notify-send "Nenhum compositor suportado encontrado para logout."
      fi
      ;;
    esac
  else
    exit 0
  fi
}

# Execução da seleção principal
chosen="$(run_rofi)"
case ${chosen} in
$shutdown)
  run_cmd --shutdown
  ;;
$reboot)
  run_cmd --reboot
  ;;
$lock)
  if command -v hyprlock &>/dev/null; then
    if pgrep -x hyprlock >/dev/null; then
      notify-send "Hyprlock já está em execução."
    else
      hyprlock
    fi
  elif command -v swaylock-effects &>/dev/null; then
    swaylock-effects -C "$HOME/.config/swaylock/config"
  elif command -v swaylock &>/dev/null; then
    swaylock -C "$HOME/.config/swaylock/config"
  else
    notify-send "Nenhum swaylock encontrado!"
  fi
  ;;
$suspend)
  run_cmd --suspend
  ;;
$logout)
  run_cmd --logout
  ;;
esac
