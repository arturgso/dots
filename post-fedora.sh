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
# Variáveis dinâmicas de terminal
# -------------------
rows=0
cols=0

update_dims() {
  # Atualiza dimensões; usa valores padrão caso tput falhe
  rows=$(tput lines 2>/dev/null || echo 24)
  cols=$(tput cols 2>/dev/null || echo 80)
}

# -------------------
# Barra fixa no rodapé
# -------------------
draw_progress() {
  local done=$1
  local total=$2

  update_dims

  # cálculo do percent
  local percent=0
  if [ "$total" -gt 0 ]; then
    percent=$(( 100 * done / total ))
  fi

  # espaço para meta (ex: " 100% (12/12) ")
  local meta
  meta=$(printf " %3d%% (%d/%d) " "$percent" "$done" "$total")
  local meta_len=${#meta}

  # tamanho da barra baseado na largura
  local reserved=12   # margem de segurança
  local bar_size=$(( cols - meta_len - reserved ))
  [ $bar_size -lt 10 ] && bar_size=10

  local filled=0
  if [ "$total" -gt 0 ]; then
    filled=$(( bar_size * done / total ))
  fi
  local empty=$(( bar_size - filled ))

  # montar strings (usando printf para evitar problemas com seq em alguns ttys)
  local bar_filled
  if [ "$filled" -gt 0 ]; then
    bar_filled=$(printf '%*s' "$filled" '' | tr ' ' '#')
  else
    bar_filled=""
  fi
  local bar_empty
  if [ "$empty" -gt 0 ]; then
    bar_empty=$(printf '%*s' "$empty" '' )
  else
    bar_empty=""
  fi

  # salva cursor, vai para última linha, limpa e imprime barra, restaura cursor
  tput sc
  tput cup $(( rows - 1 )) 0
  tput el
  printf "Progresso: [%s%s]%s" "$bar_filled" "$bar_empty" "$meta"
  # preenche até o final se necessário
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
  local pkg=$1

  # Se já instalado
  if rpm -q "$pkg" &>/dev/null; then
    echo "✔ $pkg já instalado" | tee -a "$LOGFILE"
    SKIPPED+=("$pkg")
    # redesenha barra após a mensagem
    draw_progress "$CURRENT" "$TOTAL"
    return 0
  fi

  # Mensagem inicial
  echo "→ Instalando: $pkg" | tee -a "$LOGFILE"
  draw_progress "$CURRENT" "$TOTAL"

  # Executa a instalação com saída somente para log
  if sudo dnf install -y "$pkg" >>"$LOGFILE" 2>&1; then
    echo "  ✓ Sucesso: $pkg" | tee -a "$LOGFILE"
    INSTALLED+=("$pkg")
    draw_progress "$CURRENT" "$TOTAL"
    return 0
  else
    echo "  ✖ Falhou: $pkg (ver $LOGFILE)" | tee -a "$LOGFILE"
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
  # remove background keepalive
  kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
  # garante que a barra seja reposicionada e pula linha para o resumo
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
  # pula entradas vazias (caso)
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
  # atualiza barra antes de tentar instalar (mostra progresso visual)
  draw_progress "$CURRENT" "$TOTAL"
  install_pkg "$pkg"
done

# barra final 100%
draw_progress "$TOTAL" "$TOTAL"
echo    # pula linha para imprimir o resumo

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
