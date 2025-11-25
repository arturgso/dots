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
# Funções utilitárias
# -------------------

# Desenha/atualiza a barra fixa no rodapé
progress_bar() {
  local done=$1
  local total=$2
  local cols
  cols=$(tput cols 2>/dev/null || echo 80)

  local percent=0
  if [ "$total" -gt 0 ]; then
    percent=$(( 100 * done / total ))
  fi

  # Espaço reservado para texto ao redor da barra
  local meta=" %3d%% (%d/%d) "
  local meta_len
  meta_len=$(printf "$meta" "$percent" "$done" "$total" | wc -c)
  local bar_size=$(( cols - meta_len - 10 ))
  [ $bar_size -lt 10 ] && bar_size=10

  local filled=0
  if [ "$total" -gt 0 ]; then
    filled=$(( bar_size * done / total ))
  fi
  local empty=$(( bar_size - filled ))

  # Preparar strings
  local bar_filled
  bar_filled="$(printf "%0.s#" $(seq 1 $filled) 2>/dev/null)"
  local bar_empty
  bar_empty="$(printf "%0.s " $(seq 1 $empty) 2>/dev/null)"

  # Salva cursor, vai para a última linha, limpa a linha, imprime a barra e restaura cursor
  tput sc
  tput cup $(( $(tput lines) - 1 )) 0
  tput el               # clear line
  printf "Progresso: [%s%s] %3d%% (%d/%d)" "$bar_filled" "$bar_empty" "$percent" "$done" "$total"
  tput rc
}

# Função que instala um pacote e registra resultado.
# OBS: imprime mensagens normalmente (acima da barra) e a barra é redesenhada sempre que chamamos progress_bar.
install_pkg() {
  local pkg=$1

  # Checa se já instalado
  if rpm -q "$pkg" &>/dev/null; then
    echo "✔ $pkg já instalado" | tee -a "$LOGFILE"
    SKIPPED+=("$pkg")
    return 0
  fi

  # Mensagem inicial (aparece acima da barra)
  echo "→ Instalando: $pkg" | tee -a "$LOGFILE"
  progress_bar "$CURRENT" "$TOTAL"

  # Executa instalação (saída no log)
  if sudo dnf install -y "$pkg" >>"$LOGFILE" 2>&1; then
    echo "  ✓ Sucesso: $pkg" | tee -a "$LOGFILE"
    INSTALLED+=("$pkg")
    progress_bar "$CURRENT" "$TOTAL"
    return 0
  else
    echo "  ✖ Falhou: $pkg (ver $LOGFILE)" | tee -a "$LOGFILE"
    FAILED+=("$pkg")
    progress_bar "$CURRENT" "$TOTAL"
    return 1
  fi
}

# -------------------
# Preparação e keepalive do sudo
# -------------------
sudo -v
( while true; do sudo -v; sleep 60; done ) 2>/dev/null &
SUDO_KEEPALIVE_PID=$!

cleanup() {
  kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
  # garante que a barra final foi desenhada corretamente e pule uma linha
  tput cup $(( $(tput lines) - 1 )) 0
  echo
}
trap cleanup EXIT

# -------------------
# Prepara log e lista única (remove duplicatas preservando ordem)
# -------------------
: > "$LOGFILE"

ALL=( "${DEV_PKGS[@]}" "${FONTS[@]}" "${DESKTOP[@]}" )
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

# Desenha barra inicial (0%)
progress_bar "$CURRENT" "$TOTAL"

echo "== Iniciando instalações ($TOTAL pacotes) ==" | tee -a "$LOGFILE"
# Re-desenha a barra logo após o cabeçalho
progress_bar "$CURRENT" "$TOTAL"

# -------------------
# Loop de instalação: imprime mensagens normalmente; barra é re-desenhada para ficar fixa no rodapé
# -------------------
for pkg in "${uniq_list[@]}"; do
  CURRENT=$((CURRENT + 1))
  progress_bar "$CURRENT" "$TOTAL"   # atualiza antes de iniciar instalação (opcional)
  install_pkg "$pkg"
done

# barra final 100%
progress_bar "$TOTAL" "$TOTAL"
echo    # pula linha para o resumo

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
