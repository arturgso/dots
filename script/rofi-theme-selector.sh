#!/usr/bin/env bash

set -euo pipefail

DOTS_DIR="${HOME}/.dots"
ROFI_DIR="${DOTS_DIR}/rofi"
COLORS_DIR="${ROFI_DIR}/colors"

if [[ ! -d "$COLORS_DIR" ]]; then
  echo "Diretório de cores não encontrado: $COLORS_DIR" >&2
  exit 1
fi

shopt -s nullglob
declare -a COLOR_FILES=("$COLORS_DIR"/*.rasi)
shopt -u nullglob

if ((${#COLOR_FILES[@]} == 0)); then
  echo "Nenhum arquivo .rasi encontrado em $COLORS_DIR" >&2
  exit 1
fi

mapfile -t THEMES < <(
  for path in "${COLOR_FILES[@]}"; do
    name="$(basename "${path}")"
    printf '%s\n' "${name%.rasi}"
  done | sort -f
)

declare -A PALETTE=()

extract_color() {
  local file="$1" key="$2" value=""
  if command -v rg >/dev/null 2>&1; then
    value="$(rg -m1 -oP "${key}:[^#]*#\\K[0-9A-Fa-f]{6}" "$file" 2>/dev/null || true)"
  else
    value="$(grep -i -m1 "${key}:" "$file" 2>/dev/null | sed -E 's/.*#([0-9A-Fa-f]{6}).*/\1/' || true)"
  fi

  if [[ -z "$value" ]]; then
    value="000000"
  fi

  printf '#%s' "$value"
}

color_block() {
  local hex="${1#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  printf '\033[48;2;%d;%d;%dm  \033[0m' "$r" "$g" "$b"
}

print_menu() {
  printf 'Temas disponíveis:\n'
  local idx=0
  for theme in "${THEMES[@]}"; do
    local file="${COLORS_DIR}/${theme}.rasi"
    local bg fg sel act urg
    bg="$(extract_color "$file" background)"
    fg="$(extract_color "$file" foreground)"
    sel="$(extract_color "$file" selected)"
    act="$(extract_color "$file" active)"
    urg="$(extract_color "$file" urgent)"
    printf '%2d) %-14s %s%-9s %s%-9s %s%-9s %s%-9s %s%-9s\n' \
      $((idx + 1)) "$theme" \
      "$(color_block "$bg")" "$bg" \
      "$(color_block "$fg")" "$fg" \
      "$(color_block "$sel")" "$sel" \
      "$(color_block "$act")" "$act" \
      "$(color_block "$urg")" "$urg"
    ((idx += 1))
  done
}

select_theme() {
  local choice=""
  read -r -p $'\nEscolha um tema (número ou nome, ENTER para sair): ' choice

  if [[ -z "$choice" ]]; then
    echo ""
    return 0
  fi

  if [[ "$choice" =~ ^[0-9]+$ ]]; then
    local index=$((choice - 1))
    if ((index >= 0 && index < ${#THEMES[@]})); then
      echo "${THEMES[$index]}"
      return 0
    fi
  else
    local lowered
    lowered="$(tr '[:upper:]' '[:lower:]' <<< "$choice")"
    for theme in "${THEMES[@]}"; do
      if [[ "$(tr '[:upper:]' '[:lower:]' <<< "$theme")" == "$lowered" ]]; then
        echo "$theme"
        return 0
      fi
    done
  fi

  echo "Seleção inválida: $choice" >&2
  return 1
}

load_palette() {
  local theme="$1"
  local file="${COLORS_DIR}/${theme}.rasi"
  if [[ ! -f "$file" ]]; then
    echo "Arquivo de cores não encontrado: $file" >&2
    exit 1
  fi

  for key in background background-alt foreground selected active urgent; do
    PALETTE["$key"]="$(extract_color "$file" "$key")"
  done
}

update_waybar() {
  local file="${DOTS_DIR}/waybar/style.css"
  if [[ ! -f "$file" ]]; then
    echo "Waybar não encontrado, pulando atualização."
    return
  fi

  declare -A map=(
    [theme_bg]="background"
    [theme_bg_alt]="background-alt"
    [theme_fg]="foreground"
    [theme_accent]="selected"
    [theme_active]="active"
    [theme_urgent]="urgent"
  )

  for var in "${!map[@]}"; do
    local key="${map[$var]}"
    local color="${PALETTE[$key]}"
    [[ -n "$color" ]] || continue
    WAYBAR_VAR="$var" WAYBAR_COLOR="$color" perl -0pi -e '
      my $var = quotemeta($ENV{"WAYBAR_VAR"});
      my $color = $ENV{"WAYBAR_COLOR"};
      $color =~ s/^#//;
      s|(@define-color\s+$var\s+)#[0-9A-Fa-f]{6}|$1#$color|g;
    ' "$file"
  done

  printf 'Atualizado Waybar: %s\n' "$file"
}

update_dunst() {
  local file="${DOTS_DIR}/dunst/dunstrc"
  if [[ ! -f "$file" ]]; then
    echo "Arquivo do Dunst não encontrado, pulando atualização."
    return
  fi

  declare -A map=(
    [background]="background"
    [background-alt]="background-alt"
    [foreground]="foreground"
    [accent]="selected"
    [active]="active"
    [urgent]="urgent"
  )

  for tag in "${!map[@]}"; do
    local key="${map[$tag]}"
    local color="${PALETTE[$key]}"
    [[ -n "$color" ]] || continue
    THEME_TAG="$tag" THEME_COLOR="$color" perl -0pi -e '
      my $tag = quotemeta($ENV{"THEME_TAG"});
      my $color = $ENV{"THEME_COLOR"};
      s{(=\s*)"#[0-9A-Fa-f]{6}"(\s*#\s*theme:$tag(?:\s|$))}{$1"$color"$2}g;
    ' "$file"
  done

  printf 'Atualizado Dunst: %s\n' "$file"
}

update_hyprland() {
  local file="${DOTS_DIR}/hypr/conf.d/look-and-feel.conf"
  if [[ ! -f "$file" ]]; then
    echo "Arquivo do Hyprland não encontrado, pulando atualização."
    return
  fi

  local active="${PALETTE[selected]}"
  local inactive="${PALETTE[background-alt]}"
  
  if [[ -z "$active" ]] || [[ -z "$inactive" ]]; then
    echo "Cores para bordas do Hyprland não encontradas."
    return
  fi

  # Converter hex para rgba (formato Hyprland)
  local active_hex="${active#\#}"
  local inactive_hex="${inactive#\#}"
  
  # Substituir col.active_border
  HYPR_COLOR="rgba(${active_hex}FF)" perl -0pi -e '
    my $color = $ENV{"HYPR_COLOR"};
    s{(col\.active_border\s*=\s*)rgba\([0-9A-Fa-f]{6,8}(?:FF)?\)(?:\s+rgba\([0-9A-Fa-f]{6,8}(?:FF)?\)\s+\d+deg)?}{$1$color}g;
  ' "$file"

  # Substituir col.inactive_border
  HYPR_COLOR="rgba(${inactive_hex}aa)" perl -0pi -e '
    my $color = $ENV{"HYPR_COLOR"};
    s{(col\.inactive_border\s*=\s*)rgba\([0-9A-Fa-f]{6,8}[0-9a-fA-F]{0,2}\)}{$1$color}g;
  ' "$file"

  printf 'Atualizado Hyprland: %s\n' "$file"
}

reload_hyprland() {
  if ! command -v hyprctl >/dev/null 2>&1; then
    echo "hyprctl não está no PATH; configuração do Hyprland não foi recarregada."
    return
  fi

  if hyprctl reload >/dev/null 2>&1; then
    echo "Configuração do Hyprland recarregada."
  else
    echo "Erro ao recarregar configuração do Hyprland." >&2
  fi
}

restart_dunst() {
  if ! command -v dunst >/dev/null 2>&1; then
    echo "dunst não está no PATH; não foi reiniciado."
    return
  fi

  pkill -x dunst >/dev/null 2>&1 || true
  sleep 0.2
  nohup dunst >/dev/null 2>&1 &
  sleep 0.2

  if command -v dunstify >/dev/null 2>&1; then
    dunstify "Tema aplicado" "Novo esquema: ${1}" >/dev/null 2>&1 || \
      echo "Não foi possível enviar notificação de teste do Dunst." >&2
  fi
  echo "Dunst reiniciado."
}

restart_waybar() {
  if ! command -v waybar >/dev/null 2>&1; then
    echo "Waybar não está no PATH; não foi reiniciado."
    return
  fi

  pkill -x waybar >/dev/null 2>&1 || true
  sleep 0.2
  nohup waybar >/dev/null 2>&1 &
  echo "Waybar reiniciado."
}

gather_target_files() {
  if command -v rg >/dev/null 2>&1; then
    rg -l --no-heading '@import[^\n]*rofi/colors' "$ROFI_DIR"
  else
    grep -RIl -E 'rofi/colors/[^"]+\.rasi' "$ROFI_DIR"
  fi
}

apply_theme() {
  local theme="$1"
  local import_line="@import \"~/.dots/rofi/colors/${theme}.rasi\""
  mapfile -t targets < <(gather_target_files)

  if ((${#targets[@]} == 0)); then
    echo "Nenhum arquivo usa @import de cores dentro de $ROFI_DIR" >&2
    exit 1
  fi

  for file in "${targets[@]}"; do
    ROFI_TARGET_IMPORT="$import_line" perl -0pi -e 'my $line = $ENV{"ROFI_TARGET_IMPORT"};
      s|(^\s*)(?:\@import\s+)+"[^"\n]*rofi/colors/[^"\n]+\.rasi"|$1$line|gm;' "$file"
    printf 'Atualizado: %s\n' "$file"
  done

  printf '\nTema aplicado: %s\n' "$theme"
}

print_menu
selected_theme="$(select_theme)"

if [[ -z "$selected_theme" ]]; then
  echo "Nenhuma alteração realizada."
  exit 0
fi

load_palette "$selected_theme"
apply_theme "$selected_theme"
update_waybar
update_dunst
update_hyprland
restart_waybar
restart_dunst "$selected_theme"
reload_hyprland
