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

#!/usr/bin/env bash

# Funções de cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

# Função de delay e espaçamento
pause() {
  sleep 1
  echo
}

# -------------------
# Atualização do sistema
# -------------------
echo -e "${BLUE}Atualizando sistema...${NC}"
sudo dnf upgrade --refresh -y
pause

# -------------------
# Adicionando Copr e RPM Fusion
# -------------------
echo -e "${BLUE}Adicionando Copr e RPM Fusion...${NC}"
sudo dnf copr enable solopasha/hyprland -y
pause

echo -e "${YELLOW}Baixando pacotes RPM Fusion...${NC}"
curl -LO https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-43.noarch.rpm
curl -LO https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-43.noarch.rpm

sudo dnf install -y rpmfusion-free-release-43.noarch.rpm rpmfusion-nonfree-release-43.noarch.rpm
rm -f rpmfusion-*-release-43.noarch.rpm
pause

echo -e "${GREEN}Copr e RPM Fusion habilitados${NC}"
pause

# -------------------
# Instalando grupos padrão
# -------------------
echo -e "${BLUE}Instalando grupos padrão...${NC}"
sudo dnf group install -y development-tools
sudo dnf group install -y multimedia
pause

echo -e "${GREEN}Grupos instalados${NC}"
pause

# -------------------
# Baixando e instalando Nerd Fonts
# -------------------
echo -e "${BLUE}Instalando Nerd Fonts...${NC}"
NERD_FONTS_URL="https://codeload.github.com/ryanoasis/nerd-fonts/zip/refs/heads/master"
curl -L -o nerd-fonts.zip "$NERD_FONTS_URL"
unzip nerd-fonts.zip -d nerd-fonts
(cd nerd-fonts && ./install.sh)
rm -rf nerd-fonts nerd-fonts.zip
pause

echo -e "${GREEN}Nerd Fonts instaladas${NC}"
pause

# -------------------
# Adicionando repositório do Visual Studio Code
# -------------------
echo -e "${BLUE}Adicionando repositório do VS Code...${NC}"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
pause

echo -e "${YELLOW}Verificando atualizações do repositório...${NC}"
sudo dnf check-update
pause

echo -e "${BLUE}Instalando VS Code...${NC}"
sudo dnf install -y code
pause

echo -e "${GREEN}VS Code instalado${NC}"
pause
xit 0
