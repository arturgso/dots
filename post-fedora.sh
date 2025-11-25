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


#Adicionar copr

echo "Adicionado Copr necessários"

sudo dnf copr enable solopasha/hyprland -y
echo "Copr's habilitados"

# -------------------
# Configuração
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
# Utilitários
# -------------------
# Barra de progresso fixa no rodapé
progress_bar() {
  local done=$1
  local total=$2
  local cols
  cols=$(tput cols 2>/dev/null || echo 80)
  local percent=0
  if [ "$total" -gt 0 ]; then
    percent=$((100 * done / total))
  fi

  local bar_size=$(( cols - 25 ))
  [ $bar_size -lt 10 ] && bar_size=10

  local filled=$(( bar_size * done / total ))
  local empty=$(( bar_size - filled ))

  # Criar strings
  local bar
  bar="$(printf "%0.s#" $(seq 1 $filled) 2>/dev/null)"
  local spc
  spc="$(printf "%0.s " $(seq 1 $empty) 2>/dev/null)"

  tput sc
  tput cup $(( $(tput lines) - 1 )) 0
  printf "Progresso: [%s%s] %3d%% (%d/%d)" "$bar" "$spc" "$percent" "$done" "$total"
  printf "%*s" $((cols - 1 - ${#percent})) ""   # enche até o final da linha
  tput rc
}

# Instala pacote e registra resultado
install_pkg() {
  local pkg=$1

  # Checa se já instalado
  if rpm -q "$pkg" &>/dev/null; then
    echo "✔ $pkg já instalado" | tee -a "$LOGFILE"
    SKIPPED+=("$pkg")
    return 0
  fi

  echo "→ Instalando: $pkg" | tee -a "$LOGFILE"
  if sudo dnf install -y "$pkg" >>"$LOGFILE" 2>&1; then
    echo "  ✓ Sucesso: $pkg" | tee -a "$LOGFILE"
    INSTALLED+=("$pkg")
    return 0
  else
    echo "  ✖ Falhou: $pkg (ver $LOGFILE para detalhes)" | tee -a "$LOGFILE"
    FAILED+=("$pkg")
    return 1
  fi
}

# -------------------
# Preparação
# -------------------
# Mantém sudo ativo enquanto o script roda
sudo -v
# Background keepalive (será killado no exit)
( while true; do sudo -v; sleep 60; done ) 2>/dev/null &
SUDO_KEEPALIVE_PID=$!

cleanup() {
  kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
  # garante que a barra final foi desenhada corretamente
  tput cup $(( $(tput lines) - 1 )) 0
  echo
}
trap cleanup EXIT

# Limpa arquivo de log antigo
: > "$LOGFILE"

# Junta todas as listas, remove comentários/linhas vazias e duplicados mantendo ordem
ALL=( "${DEV_PKGS[@]}" "${FONTS[@]}" "${DESKTOP[@]}" )
# Remove duplicatas (preserva ordem)
uniq_list=()
declare -A seen
for p in "${ALL[@]}"; do
  if [ -z "${seen[$p]:-}" ]; then
    uniq_list+=("$p")
    seen[$p]=1
  fi
done

TOTAL=${#uniq_list[@]}
CURRENT=0

echo "== Iniciando instalações ($TOTAL pacotes) =="
progress_bar "$CURRENT" "$TOTAL"

# -------------------
# Loop de instalação (um por um para identificar falhas)
# -------------------
for pkg in "${uniq_list[@]}"; do
  CURRENT=$((CURRENT + 1))
  # Atualiza barra antes de cada operação
  progress_bar "$CURRENT" "$TOTAL"

  install_pkg "$pkg"
done

# barra final 100%
progress_bar "$TOTAL" "$TOTAL"
echo    # pula linha para imprimir resumo

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
