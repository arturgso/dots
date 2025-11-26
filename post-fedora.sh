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

# Variável de confirmação geral
ASK_BEFORE_STEP=true

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

# Função para perguntar antes de cada passo
confirm_step() {
  local prompt="$1"
  if [ "$ASK_BEFORE_STEP" = true ]; then
    read -p "$prompt (s/N): " response
    [[ "$response" =~ ^[Ss]$ ]]
  else
    return 0
  fi
}

# -------------------
# Atualização do sistema
# -------------------
if confirm_step "Deseja atualizar o sistema agora?"; then
    echo -e "${BLUE}Atualizando sistema...${NC}"
    sudo dnf upgrade --refresh -y
    pause
fi

# -------------------
# Adicionando Copr, RPM Fusion, Docker Repo e Code
# -------------------
if confirm_step "Deseja adicionar Copr, RPM Fusion e repositório do Docker?"; then
    echo -e "${BLUE}Adicionando Copr e RPM Fusion...${NC}"
    sudo dnf copr enable solopasha/hyprland -y
    pause

    echo -e "${YELLOW}Baixando pacotes RPM Fusion...${NC}"
    curl -LO https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-43.noarch.rpm
    curl -LO https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-43.noarch.rpm
    sudo dnf install -y rpmfusion-free-release-43.noarch.rpm rpmfusion-nonfree-release-43.noarch.rpm
    rm -f rpmfusion-*-release-43.noarch.rpm
    pause

    echo -e "${BLUE}Configurando repositório do Docker...${NC}"
    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

    echo -e "${BLUE}Configurando repositório do VS Code...${NC}"
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
    sudo dnf check-update

    echo -e "${GREEN}Copr, RPM Fusion, Docker e VS Code habilitados${NC}"
    pause
fi

# -------------------
# Instalando grupos padrão
# -------------------
if confirm_step "Deseja instalar os grupos development-tools e multimedia?"; then
    echo -e "${BLUE}Instalando grupos padrão...${NC}"
    sudo dnf group install -y development-tools
    sudo dnf group install -y multimedia
    pause

    echo -e "${GREEN}Grupos instalados${NC}"
    pause
fi

# -------------------
# Pacotes essenciais
# -------------------
ESSENTIAL_PACKAGES=(
  fuse-devel xdg-desktop-portal-wlr xdg-desktop-portal-gtk xdg-utils
  lz4-devel cliphist nmtui ImageMagick mint-themes-gtk3 mint-themes-gtk4
  openssl-devel zlib-devel libyaml-devel libffi-devel readline-devel bzip2-devel
  gdbm-devel sqlite-devel ncurses-devel make gcc autoconf automake libtool pkgconfig
  mscore-fonts-all blueman niri hyprlock hypridle hyprpicker hyprshot waybar fastfetch kitty code
  dunst neovim mousepad nwg-look rofi bat cloc git zsh
  pipewire pipewire-pulseaudio pulseaudio bluetooth power-profiles-daemon flatpak borg sddm
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
)

# Pergunta única para instalação de todos os pacotes essenciais
if confirm_step "Deseja instalar todos os pacotes essenciais listados?"; then
    echo -e "${BLUE}Instalando pacotes essenciais...${NC}"
    sudo dnf install -y "${ESSENTIAL_PACKAGES[@]}"
    pause
fi

# -------------------
# Habilitando serviços essenciais (exceto SDDM)
# -------------------
ESSENTIAL_SERVICES=(pipewire pipewire-pulseaudio pulseaudio bluetooth power-profiles-daemon)
for svc in "${ESSENTIAL_SERVICES[@]}"; do
    if confirm_step "Deseja habilitar e iniciar o serviço $svc?"; then
        sudo systemctl enable "$svc" --now
        echo -e "${GREEN}$svc habilitado e iniciado${NC}"
        pause
    fi
done

# -------------------
# Instalando Nerd Fonts via GitHub
# -------------------
if confirm_step "Deseja instalar as Nerd Fonts?"; then
    echo -e "${BLUE}Instalando Nerd Fonts...${NC}"
    NERD_FONTS_URL="https://codeload.github.com/ryanoasis/nerd-fonts/zip/refs/heads/master"
    curl -L -o nerd-fonts.zip "$NERD_FONTS_URL"
    unzip nerd-fonts.zip -d nerd-fonts
    (cd nerd-fonts && ./install.sh)
    rm -rf nerd-fonts nerd-fonts.zip
    echo -e "${GREEN}Nerd Fonts instaladas${NC}"
    pause
fi

# -------------------
# Instalando Flatpaks
# -------------------
if confirm_step "Deseja instalar Flatpaks?"; then
    echo -e "${BLUE}Instalando Flatpak e configurando Flathub...${NC}"
    sudo dnf install -y flatpak
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    pause

    FLATPAKS=(
        com.dec05eba.gpu_screen_recorder
        com.discordapp.Discord
        com.getpostman.Postman
        com.github.IsmaelMartinez.teams_for_linux
        com.github.tchx84.Flatseal
        com.github.unrud.VideoDownloader
        com.protonvpn.www
        com.rtosta.zapzap
        com.spotify.Client
        com.valvesoftware.Steam
        io.dbeaver.DBeaverCommunity
        io.gitlab.theevilskeleton.Upscaler
        it.mijorus.gearlever
        me.proton.Mail
        me.proton.Pass
        one.ablaze.floorp
        org.gimp.GIMP
        org.gnome.World.PikaBackup
        org.inkscape.Inkscape
        org.mozilla.Thunderbird
        org.onlyoffice.desktopeditors
        org.prismlauncher.PrismLauncher
        org.qbittorrent.QBittorrent
        org.videolan.VLC
        rest.insomnia.Insomnia
    )

    for fpk in "${FLATPAKS[@]}"; do
        flatpak install -y flathub "$fpk"
        echo -e "${GREEN}Flatpak $fpk instalado${NC}"
        pause
    done
fi

# -------------------
# Criando links simbólicos para configs
# -------------------
CONFIG_DIR="$HOME/.config"
mkdir -p "$CONFIG_DIR"
for folder in niri waybar dunst; do
    if [ -d "$folder" ]; then
        ln -sfn "$(pwd)/$folder" "$CONFIG_DIR/$folder"
        echo -e "${GREEN}Link simbólico criado para $folder${NC}"
        pause
    fi
done

# -------------------
# Habilitar SDDM após confirmação do usuário
# -------------------
if confirm_step "Deseja habilitar e iniciar o SDDM?"; then
    sudo systemctl enable sddm --now
    echo -e "${GREEN}SDDM habilitado e iniciado${NC}"
fi

# -------------------
# Configuração do Borg Backup
# -------------------
if confirm_step "Deseja configurar o backup com Borg?"; then
    echo -e "${BLUE}Listando dispositivos disponíveis...${NC}"
    lsblk
    read -p "Digite o dispositivo a ser usado para o backup (ex: /dev/sda3): " BACKUP_DISK

    MOUNT_DIR="$HOME/backup_borg_mount"
    mkdir -p "$MOUNT_DIR"
    echo -e "${BLUE}Montando disco e configurando Borg...${NC}"
    sudo mount "$BACKUP_DISK" "$MOUNT_DIR"

    read -s -p "Digite a senha de encriptação do Borg: " BORG_PASS
    export BORG_PASSPHRASE="$BORG_PASS"

    echo -e "${BLUE}Montando repositório Borg...${NC}"
    borg mount "$MOUNT_DIR/backup-fedora-mriya" "$MOUNT_DIR/borg_repo_mount" || echo -e "${RED}Falha ao montar o repositório Borg${NC}"

    echo -e "${BLUE}Copiando pastas e arquivos do backup para o home...${NC}"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/.var" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/Projetos" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/.wakatime" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/.ssh" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/Cofre" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/Documents" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/Pictures" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/Postman" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/Scripts" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/Vault" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/Videos" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/.oh-my-zsh" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/.themes" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/.icons" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/.default.png" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/.zshrc" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/.gitconfig" "$HOME/"
    rsync -av --progress "$MOUNT_DIR/borg_repo_mount/.wakatime.cfg" "$HOME/"

    echo -e "${GREEN}Backup Borg restaurado${NC}"
    pause
fi
