#!/usr/bin/env bash

echo "
▄███████▄  ▄██████▄     ▄████████     ███           ▄█  ███▄▄▄▄      ▄████████     ███        ▄████████  ▄█        ▄█       
  ███    ███ ███    ███   ███    ███ ▀█████████▄      ███  ███▀▀▀██▄   ███    ███ ▀█████████▄   ███    ███ ███       ███       
  ███    ███ ███    ███   ███    █▀     ▀███▀▀██      ███▌ ███   ███   ███    █▀     ▀███▀▀██   ███    ███ ███       ███       
  ███    ███ ███    ███   ███            ███   ▀      ███▌ ███   ███   ███            ███   ▀   ███    ███ ███       ███       
▀█████████▀  ███    ███ ▀███████████     ███          ███▌ ███   ███ ▀███████████     ███     ▀███████████ ███       ███       
  ███        ███    ███          ███     ███          ███  ███   ███          ███     ███       ███    ███ ███       ███       
  ███        ███    ███    ▄█    ███     ███          ███  ███   ███    ▄█    ███     ███       ███    ███ ███▌    ▄ ███▌    ▄ 
 ▄████▀       ▀██████▀   ▄████████▀     ▄████▀        █▀    ▀█   █▀   ▄████████▀     ▄████▀     ███    █▀  █████▄▄██ █████▄▄██ 
                                                                                                           ▀         ▀         "


set -u
IFS=$'\n'

# -------------------
# Adicionar copr
# -------------------
echo "Adicionando Copr necessários"
sudo dnf copr enable solopasha/hyprland -y
echo "Copr's habilitados"

# -------------------
# Configuração (suas listas)
# -------------------
DEV_PKGS=(
  openssl-devel zlib-devel libyaml-devel libffi-devel readline-devel bzip2-devel
  gdbm-devel sqlite-devel ncurses-devel fuse-devel lz4-devel
  gcc make autoconf automake libtool pkgconfig
  neovim kitty zsh git
)

FONTS=(
  mscore-fonts-all
)

DESKTOP=(
  niri hyprlock hypridle hyprpicker hyprshot waybar rofi dunst
  xdg-desktop-portal-wlr xdg-portal-desktop-gtk wl-wayland nwg-look xdg-utils
  mint-themes-gtk3 mint-themes-gtk4 cloc cliphist bat nmtui fastfetch ImageMagick
  blueman nemo mousepad
)

LOGFILE="install.log"
FAILED=()
SKIPPED=()
INSTALLED=()

# -------------------
# Variáveis dinâmicas de terminal
# -------------------
rows=0
cols=0

update_dims() {
  rows=$(tput lines 2>/dev/null || echo 24)
  cols=$(tput cols 2>/dev/null || echo 80)
}

# -------------------
# Barra fixa no rodapé
# -------------------
draw_progress() {
    local done=${1:-0}
    local total=${2:-0}

    update_dims

    # evita divisão por zero
    local percent=0
    if [ "$total" -gt 0 ]; then
      percent=$(( 100 * done / total ))
    fi

    local meta
    meta=$(printf " %3d%% (%d/%d) " "$percent" "$done" "$total")
    local meta_len=${#meta}

    local reserved=12
    local bar_size=$(( cols - meta_len - reserved ))
    [ $bar_size -lt 10 ] && bar_size=10

    local filled=0
    if [ "$total" -gt 0 ]; then
      filled=$(( bar_size * done / total ))
    fi
    local empty=$(( bar_size - filled ))

    local bar_filled=""
    local bar_empty=""
    if [ "$filled" -gt 0 ]; then
      bar_filled=$(printf '%*s' "$filled" '' | tr ' ' '#')
    fi
    if [ "$empty" -gt 0 ]; then
      bar_empty=$(printf '%*s' "$empty" '' )
    fi

    # salva cursor, vai pra última linha, limpa e imprime, restaura cursor
    tput sc
    tput cup $(( rows - 1 )) 0
    printf "\033[2K"    # clear entire line
    printf "Progresso: [%s%s]%s" "$bar_filled" "$bar_empty" "$meta"

    # preencher resto até o final da coluna para evitar restos de linhas antigas
    local printed_len=$(( 11 + ${#bar_filled} + ${#bar_empty} + meta_len ))
    if [ $printed_len -lt $cols ]; then
      printf "%*s" $(( cols - printed_len )) ""
    fi

    tput rc
}

# Redesenha a barra quando o terminal for redimensionado
on_resize() {
  update_dims
  draw_progress "$CURRENT" "$TOTAL"
}
trap 'on_resize' SIGWINCH

# -------------------
# Função de instalação por pacote
# -------------------
install_pkg() {
    local pkg="$1"

    # redesenha antes de imprimir (mantém a barra fixa)
    draw_progress "$CURRENT" "$TOTAL"

    # checa se já instalado
    if rpm -q "$pkg" &>/dev/null; then
      echo "✔ $pkg já instalado" | tee -a "$LOGFILE"
      SKIPPED+=("$pkg")
      draw_progress "$CURRENT" "$TOTAL"
      return 0
    fi

    echo "→ Instalando: $pkg" | tee -a "$LOGFILE"

    # executa instalação com saída só para log (append)
    if sudo dnf install -y "$pkg" >>"$LOGFILE" 2>&1; then
      echo "  ✓ Sucesso: $pkg" | tee -a "$LOGFILE"
      INSTALLED+=("$pkg")
      draw_progress "$CURRENT" "$TOTAL"
      return 0
    else
      echo "  ✗ Falhou:  $pkg (ver $LOGFILE)" | tee -a "$LOGFILE"
      FAILED+=("$pkg")
      draw_progress "$CURRENT" "$TOTAL"
      return 1
    fi
}

# -------------------
# Preparação: sudo keepalive
# -------------------
sudo -v || { echo "sudo sem sucesso. Verifique permissões." ; exit 1; }
( while true; do sudo -v; sleep 60; done ) 2>/dev/null &
SUDO_KEEPALIVE_PID=$!

cleanup() {
  kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
  update_dims
  tput cup $(( rows - 1 )) 0
  tput el
  echo
}
trap cleanup EXIT

# -------------------
# Prepara log, une listas e remove duplicatas (preserva ordem)
# -------------------
: > "$LOGFILE"

ALL=( "${DEV_PKGS[@]}" "${FONTS[@]}" "${DESKTOP[@]}" )
uniq_list=()
declare -A seen
for p in "${ALL[@]}"; do
  [ -z "$p" ] && continue
  if [ -z "${seen[$p]:-}" ]; then
    uniq_list+=("$p")
    seen[$p]=1
  fi
done

TOTAL=${#uniq_list[@]}
CURRENT=0

# Desenha barra inicial
update_dims
draw_progress "$CURRENT" "$TOTAL"

echo "== Iniciando instalações ($TOTAL pacotes) ==" | tee -a "$LOGFILE"
draw_progress "$CURRENT" "$TOTAL"

# -------------------
# Loop principal: atualiza barra antes/depois e instala pacote a pacote
# -------------------
for pkg in "${uniq_list[@]}"; do
  CURRENT=$(( CURRENT + 1 ))
  draw_progress "$CURRENT" "$TOTAL"
  install_pkg "$pkg"
done

# barra final 100%
draw_progress "$TOTAL" "$TOTAL"
echo

# -------------------
# Resumo final
# -------------------
echo
echo "=== Resumo ==="
echo "Total pacotes processados: $TOTAL"
echo "Instalados agora: ${#INSTALLED[@]}"
echo "Pulados (já instalados): ${#SKIPPED[@]}"
echo "Falharam: ${#FAILED[@]}"
if [ ${#FAILED[@]} -gt 0 ]; then
  echo
  echo "Pacotes que falharam na instalação:"
  for f in "${FAILED[@]}"; do
    echo " - $f"
  done
  echo
  echo "Confira $LOGFILE para saída completa e erros."
else
  echo "Nenhuma falha detectada. Tudo certo!"
fi

exit 0

