#!/usr/bin/env bash

set -euo pipefail

DOTS_DIR="${HOME}/.dots"
ROFI_DIR="${DOTS_DIR}/rofi"
COLORS_DIR="${ROFI_DIR}/colors"
WALLPAPER_FILE="${HOME}/.default"
THEME_NAME="wallpaper"

# Função para encontrar o arquivo de papel de parede
find_wallpaper() {
  if [[ -f "${WALLPAPER_FILE}.png" ]]; then
    echo "${WALLPAPER_FILE}.png"
  elif [[ -f "${WALLPAPER_FILE}.jpg" ]]; then
    echo "${WALLPAPER_FILE}.jpg"
  elif [[ -f "${WALLPAPER_FILE}.jpeg" ]]; then
    echo "${WALLPAPER_FILE}.jpeg"
  else
    echo "Erro: Papel de parede não encontrado em ${WALLPAPER_FILE}.(png|jpg|jpeg)" >&2
    exit 1
  fi
}

# Função para calcular luminosidade
calculate_luminosity() {
  local hex="${1#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  # Fórmula de luminosidade relativa
  echo $((r * 299 + g * 587 + b * 114))
}

# Função para ajustar brilho de uma cor
adjust_brightness() {
  local hex="${1#\#}"
  local factor="$2"  # 0.0 a 2.0
  
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  
  r=$(awk -v val="$r" -v f="$factor" 'BEGIN {result = int(val * f); if (result > 255) result = 255; if (result < 0) result = 0; printf "%d", result}')
  g=$(awk -v val="$g" -v f="$factor" 'BEGIN {result = int(val * f); if (result > 255) result = 255; if (result < 0) result = 0; printf "%d", result}')
  b=$(awk -v val="$b" -v f="$factor" 'BEGIN {result = int(val * f); if (result > 255) result = 255; if (result < 0) result = 0; printf "%d", result}')
  
  printf '#%02X%02X%02X' "$r" "$g" "$b"
}

# Função para extrair cores usando ImageMagick
extract_colors_imagemagick() {
  local img="$1"
  
  if ! command -v magick >/dev/null 2>&1; then
    echo "ImageMagick não está instalado. Instale com: sudo dnf install ImageMagick" >&2
    return 1
  fi

  echo "Extraindo cores do papel de parede com ImageMagick..." >&2

  # Extrai as cores mais dominantes e únicas
  mapfile -t all_colors < <(
    magick "$img" -resize 200x200 -colors 16 -unique-colors txt:- | \
    grep -oP '#[0-9A-Fa-f]{6}' | sort -u
  )

  if ((${#all_colors[@]} < 3)); then
    echo "Erro: Não foi possível extrair cores suficientes" >&2
    return 1
  fi

  # Classificar cores por luminosidade
  declare -a sorted_colors=()
  for color in "${all_colors[@]}"; do
    local lum=$(calculate_luminosity "$color")
    sorted_colors+=("$lum:$color")
  done
  
  # Ordenar por luminosidade
  IFS=$'\n' sorted_colors=($(sort -n <<< "${sorted_colors[*]}"))
  unset IFS

  # Extrair cores ordenadas
  declare -a colors=()
  for item in "${sorted_colors[@]}"; do
    colors+=("${item#*:}")
  done

  # Selecionar cores baseado em luminosidade e variedade
  local total=${#colors[@]}
  local dark_idx=0
  local mid_dark_idx=$((total / 5))
  local mid_idx=$((total / 2))
  local bright_idx=$(((total * 3) / 4))
  local brightest_idx=$((total - 1))
  
  # Cores base
  local bg="${colors[$dark_idx]}"
  local bg_alt="${colors[$mid_dark_idx]}"
  local fg="${colors[$brightest_idx]}"
  
  # Cores de destaque - pegar cores do meio-brilhante
  local sel="${colors[$bright_idx]}"
  local act="${colors[$mid_idx]}"
  
  # Cor urgente - cor mais saturada ou vermelha disponível
  local urg="$sel"
  if ((total > 6)); then
    urg="${colors[$((total * 2 / 3))]}"
  fi
  
  # Se as cores forem muito similares, criar variações
  local bg_lum=$(calculate_luminosity "$bg")
  local fg_lum=$(calculate_luminosity "$fg")
  local contrast=$((fg_lum - bg_lum))
  
  # Garantir contraste mínimo
  if ((contrast < 40000)); then
    fg=$(adjust_brightness "$fg" 1.3)
    bg=$(adjust_brightness "$bg" 0.7)
  fi
  
  # Garantir que background-alt seja diferente do background
  if [[ "$bg" == "$bg_alt" ]]; then
    bg_alt=$(adjust_brightness "$bg" 1.2)
  fi

  # Retornar como string
  echo "background:$bg"
  echo "background-alt:$bg_alt"
  echo "foreground:$fg"
  echo "selected:$sel"
  echo "active:$act"
  echo "urgent:$urg"
}

# Função para extrair cores usando pywal (se disponível)
extract_colors_pywal() {
  local img="$1"
  
  if ! command -v wal >/dev/null 2>&1; then
    echo "pywal não está instalado. Tentando ImageMagick..." >&2
    return 1
  fi

  echo "Gerando esquema de cores com pywal..." >&2
  
  # Gera cores sem aplicar tema
  wal -i "$img" -n -q -s -t

  local cache_file="${HOME}/.cache/wal/colors"
  
  if [[ ! -f "$cache_file" ]]; then
    echo "Erro: Arquivo de cache do pywal não encontrado" >&2
    return 1
  fi

  mapfile -t wal_colors < "$cache_file"
  
  # Mapear cores do pywal para nosso esquema
  echo "background:${wal_colors[0]}"
  echo "background-alt:${wal_colors[1]}"
  echo "foreground:${wal_colors[7]}"
  echo "selected:${wal_colors[4]}"
  echo "active:${wal_colors[2]}"
  echo "urgent:${wal_colors[1]}"
}

# Função principal para extrair cores
extract_colors() {
  local img="$1"
  declare -A palette=()
  
  # Tenta pywal primeiro, depois ImageMagick
  if mapfile -t color_pairs < <(extract_colors_pywal "$img" 2>/dev/null || extract_colors_imagemagick "$img"); then
    for pair in "${color_pairs[@]}"; do
      local key="${pair%%:*}"
      local value="${pair#*:}"
      palette["$key"]="$value"
    done
  else
    echo "Erro: Não foi possível extrair cores. Instale ImageMagick ou pywal." >&2
    exit 1
  fi

  # Retornar array associativo
  for key in "${!palette[@]}"; do
    echo "${key}:${palette[$key]}"
  done
}

# Criar arquivo .rasi com as cores extraídas
create_rasi_file() {
  local output_file="${COLORS_DIR}/${THEME_NAME}.rasi"
  
  cat > "$output_file" <<EOF
/* ────────────────────────────────────────────────────────────────────────────
 * Tema gerado automaticamente a partir do papel de parede
 * Arquivo: ${WALLPAPER}
 * Gerado em: $(date '+%Y-%m-%d %H:%M:%S')
 * ─────────────────────────────────────────────────────────────────────────── */

* {
    background:     ${PALETTE[background]};
    background-alt: ${PALETTE[background-alt]};
    foreground:     ${PALETTE[foreground]};
    selected:       ${PALETTE[selected]};
    active:         ${PALETTE[active]};
    urgent:         ${PALETTE[urgent]};
}
EOF

  echo "$output_file"
}

# Carregar palette do arquivo
load_palette() {
  local theme="$1"
  local file="${COLORS_DIR}/${theme}.rasi"
  
  if [[ ! -f "$file" ]]; then
    echo "Arquivo de cores não encontrado: $file" >&2
    exit 1
  fi

  for key in background background-alt foreground selected active urgent; do
    local value=""
    if command -v rg >/dev/null 2>&1; then
      value="$(rg -m1 -oP "${key}:[^#]*#\\K[0-9A-Fa-f]{6}" "$file" 2>/dev/null || true)"
    else
      value="$(grep -i -m1 "${key}:" "$file" 2>/dev/null | sed -E 's/.*#([0-9A-Fa-f]{6}).*/\1/' || true)"
    fi

    if [[ -z "$value" ]]; then
      value="000000"
    fi

    PALETTE["$key"]="#$value"
  done
}

# Atualizar Waybar
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

# Atualizar Dunst
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

# Atualizar Hyprland
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

  local active_hex="${active#\#}"
  local inactive_hex="${inactive#\#}"
  
  HYPR_COLOR="rgba(${active_hex}FF)" perl -0pi -e '
    my $color = $ENV{"HYPR_COLOR"};
    s{(col\.active_border\s*=\s*)rgba\([0-9A-Fa-f]{6,8}(?:FF)?\)(?:\s+rgba\([0-9A-Fa-f]{6,8}(?:FF)?\)\s+\d+deg)?}{$1$color}g;
  ' "$file"

  HYPR_COLOR="rgba(${inactive_hex}aa)" perl -0pi -e '
    my $color = $ENV{"HYPR_COLOR"};
    s{(col\.inactive_border\s*=\s*)rgba\([0-9A-Fa-f]{6,8}[0-9a-fA-F]{0,2}\)}{$1$color}g;
  ' "$file"

  printf 'Atualizado Hyprland: %s\n' "$file"
}

# Recarregar Hyprland
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

# Reiniciar Dunst
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
    dunstify "Tema aplicado" "Cores extraídas do papel de parede" >/dev/null 2>&1 || \
      echo "Não foi possível enviar notificação de teste do Dunst." >&2
  fi
  echo "Dunst reiniciado."
}

# Reiniciar Waybar
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

# Coletar arquivos que usam import de cores
gather_target_files() {
  if command -v rg >/dev/null 2>&1; then
    rg -l --no-heading '@import[^\n]*rofi/colors' "$ROFI_DIR"
  else
    grep -RIl -E 'rofi/colors/[^"]+\.rasi' "$ROFI_DIR"
  fi
}

# Aplicar tema no Rofi
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

# ============================================================================
# Main
# ============================================================================

echo "═══════════════════════════════════════════════════════════════════"
echo "  Gerador de Tema a partir do Papel de Parede"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Encontrar papel de parede
WALLPAPER="$(find_wallpaper)"
echo "✓ Papel de parede encontrado: $WALLPAPER"
echo ""

# Extrair cores
declare -A PALETTE=()
mapfile -t color_data < <(extract_colors "$WALLPAPER")

for pair in "${color_data[@]}"; do
  key="${pair%%:*}"
  value="${pair#*:}"
  PALETTE["$key"]="$value"
done

echo ""
echo "Cores extraídas:"
for key in background background-alt foreground selected active urgent; do
  printf "  %-16s %s\n" "$key:" "${PALETTE[$key]}"
done
echo ""

# Criar arquivo .rasi
rasi_file="$(create_rasi_file)"
echo "✓ Arquivo de cores criado: $rasi_file"
echo ""

# Aplicar tema
echo "Aplicando tema..."
apply_theme "$THEME_NAME"
echo ""

echo "Atualizando componentes..."
update_waybar
update_dunst
update_hyprland
echo ""

echo "Reiniciando serviços..."
restart_waybar
restart_dunst
reload_hyprland
echo ""

echo "═══════════════════════════════════════════════════════════════════"
echo "  ✓ Tema aplicado com sucesso!"
echo "═══════════════════════════════════════════════════════════════════"
