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
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin rsync wget curl
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

    # Diretórios separados: um para montar o disco, outro para montar o Borg
    DISK_MOUNT_DIR="$HOME/backup_disk_mount"
    BORG_MOUNT_DIR="$HOME/borg_repo_mount"

    # Criar diretórios
    mkdir -p "$DISK_MOUNT_DIR" "$BORG_MOUNT_DIR"

    # Montar disco
    echo -e "${BLUE}Montando disco $BACKUP_DISK em $DISK_MOUNT_DIR...${NC}"
    sudo mount "$BACKUP_DISK" "$DISK_MOUNT_DIR" || {
        echo -e "${RED}Falha ao montar o dispositivo $BACKUP_DISK${NC}"
        pause
        exit 1
    }

    # Verificar se o repositório existe
    BORG_REPO="$DISK_MOUNT_DIR/backup-fedora-mriya"
    if [ ! -d "$BORG_REPO" ]; then
        echo -e "${RED}Repositório Borg não encontrado em $BORG_REPO${NC}"
        echo -e "${YELLOW}Conteúdo de $DISK_MOUNT_DIR:${NC}"
        ls -la "$DISK_MOUNT_DIR"
        sudo umount "$DISK_MOUNT_DIR"
        pause
        exit 1
    fi

    echo -e "${GREEN}Repositório Borg encontrado: $BORG_REPO${NC}"

    # Configurar senha
    read -s -p "Digite a senha de encriptação do Borg: " BORG_PASS
    echo
    export BORG_PASSPHRASE="$BORG_PASS"

    # Montar repositório Borg em diretório SEPARADO
    echo -e "${BLUE}Montando repositório Borg em $BORG_MOUNT_DIR...${NC}"
    
    borg mount "$BORG_REPO" "$BORG_MOUNT_DIR"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Falha ao montar o repositório Borg${NC}"
        sudo umount "$DISK_MOUNT_DIR"
        unset BORG_PASSPHRASE
        pause
        exit 1
    fi

    echo -e "${GREEN}Repositório Borg montado com sucesso em $BORG_MOUNT_DIR${NC}"

    # Encontrar o backup mais recente
    echo -e "${BLUE}Procurando backup mais recente...${NC}"
    LATEST_BACKUP=$(ls -lt "$BORG_MOUNT_DIR" | grep '^d' | head -1 | awk '{print $9}')
    
    if [ -z "$LATEST_BACKUP" ]; then
        echo -e "${RED}Nenhum backup encontrado no repositório${NC}"
        borg umount "$BORG_MOUNT_DIR"
        sudo umount "$DISK_MOUNT_DIR"
        unset BORG_PASSPHRASE
        pause
        exit 1
    fi

    echo -e "${GREEN}Backup mais recente: $LATEST_BACKUP${NC}"

    # Definir o caminho base para os arquivos (home/mriya dentro do backup)
    BACKUP_BASE="$BORG_MOUNT_DIR/$LATEST_BACKUP/home/mriya"
    
    if [ ! -d "$BACKUP_BASE" ]; then
        echo -e "${RED}Estrutura de diretório não encontrada: $BACKUP_BASE${NC}"
        echo -e "${YELLOW}Conteúdo do backup $LATEST_BACKUP:${NC}"
        find "$BORG_MOUNT_DIR/$LATEST_BACKUP" -type d | head -20
        borg umount "$BORG_MOUNT_DIR"
        sudo umount "$DISK_MOUNT_DIR"
        unset BORG_PASSPHRASE
        pause
        exit 1
    fi

    echo -e "${GREEN}Estrutura do backup encontrada em: $BACKUP_BASE${NC}"
    echo -e "${BLUE}Conteúdo disponível para restauração:${NC}"
    ls -la "$BACKUP_BASE"

    # Restaurar arquivos do caminho correto
    echo -e "${BLUE}Copiando dados do backup...${NC}"
    for item in \
        ".var" \
        "Projetos" \
        ".wakatime" \
        ".ssh" \
        "Cofre" \
        "Documents" \
        "Pictures" \
        "Postman" \
        "Scripts" \
        "Vault" \
        "Videos" \
        ".oh-my-zsh" \
        ".themes" \
        ".icons" \
        ".default.png" \
        ".zshrc" \
        ".gitconfig" \
        ".tool-versions" \
        ".wakatime.cfg"; do
        if [ -e "$BACKUP_BASE/$item" ]; then
            echo -e "${GREEN}Copiando $item...${NC}"
            rsync -av --progress --exclude='node_modules' "$BACKUP_BASE/$item" "$HOME/"
        else
            echo -e "${YELLOW}Aviso: $item não encontrado no backup${NC}"
        fi
    done

    # Desmontar tudo - ORDEM IMPORTANTE
    echo -e "${BLUE}Desmontando repositório Borg...${NC}"
    borg umount "$BORG_MOUNT_DIR"
    
    echo -e "${BLUE}Desmontando disco...${NC}"
    sudo umount "$DISK_MOUNT_DIR"

    # Limpar diretórios
    rmdir "$BORG_MOUNT_DIR"
    rmdir "$DISK_MOUNT_DIR"

    # Limpar variável de ambiente
    unset BORG_PASSPHRASE

    echo -e "${GREEN}Backup Borg restaurado com sucesso!${NC}"
    pause
fi

# -------------------
# Instalação do asdf
# -------------------
if confirm_step "Deseja instalar o asdf e configurar as linguagens?"; then
    # 1. Trocar o shell para zsh
    echo -e "${BLUE}Trocando o shell para zsh...${NC}"
    chsh -s $(which zsh) || {
        echo -e "${RED}Falha ao trocar o shell para zsh${NC}"
        pause
        exit 1
    }

    # 2. Baixar o asdf
    echo -e "${BLUE}Baixando o asdf...${NC}"
    wget https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-linux-amd64.tar.gz -O /tmp/asdf.tar.gz || {
        echo -e "${RED}Falha ao baixar o asdf${NC}"
        pause
        exit 1
    }

    # 3. Extrair e mover para /bin (com sudo)
    echo -e "${BLUE}Extraindo e movendo o asdf para /bin...${NC}"
    sudo tar -xzf /tmp/asdf.tar.gz -C /bin || {
        echo -e "${RED}Falha ao extrair o asdf${NC}"
        pause
        exit 1
    }

    # 4. Criar as pastas e configurar completions
    echo -e "${BLUE}Configurando o asdf...${NC}"
    mkdir -p "${ASDF_DATA_DIR:-$HOME/.asdf}/completions"
    asdf completion zsh > "${ASDF_DATA_DIR:-$HOME/.asdf}/completions/_asdf" || {
        echo -e "${RED}Falha ao configurar as completions do asdf${NC}"
        pause
        exit 1
    }

    # 5. Adicionar os plugins
    echo -e "${BLUE}Adicionando plugins do asdf...${NC}"
    plugins=("java" "nodejs" "golang" "yarn" "rust" "neovim" "ruby" "python" "lazygit" "lazydocker")
    for plugin in "${plugins[@]}"; do
        asdf plugin add "$plugin" || {
            echo -e "${RED}Falha ao adicionar o plugin $plugin${NC}"
            pause
            exit 1
        }
    done

    # 6. Definir as versões globais
    echo -e "${BLUE}Definindo versões globais...${NC}"
    asdf set -u java temurin-25.0.0+36.0.LTS
    asdf set -u nodejs 22.15.0
    asdf set -u golang 1.25.1
    asdf set -u yarn 1.22.22
    asdf set -u rust stable
    asdf set -u lazygit 0.55.1
    asdf set -u neovim 0.10.0
    asdf set -u lazydocker 0.24.1
    asdf set -u nvim 0.10.0
    asdf set -u ruby 3.4.7
    asdf set -u python 3.11.14

    # 7. Instalar todas as versões
    echo -e "${BLUE}Instalando todas as versões...${NC}"
    asdf install || {
        echo -e "${RED}Falha ao instalar as versões com asdf${NC}"
        pause
        exit 1
    }

    # 8. Configurar o rustup
    echo -e "${BLUE}Configurando o rustup...${NC}"
    rustup default stable || {
        echo -e "${RED}Falha ao configurar o rustup${NC}"
        pause
        exit 1
    }

    echo -e "${GREEN}asdf e linguagens configuradas com sucesso!${NC}"
    pause
fi

# -------------------
# Clonar e executar docker-files
# -------------------
if confirm_step "Deseja clonar e configurar o repositório docker-files?"; then
    echo -e "${BLUE}Clonando repositório docker-files...${NC}"
    
    DOCKER_FILES_DIR="$HOME/docker-files"
    
    if [ -d "$DOCKER_FILES_DIR" ]; then
        echo -e "${YELLOW}O diretório $DOCKER_FILES_DIR já existe. Atualizando...${NC}"
        cd "$DOCKER_FILES_DIR"
        git pull origin main || {
            echo -e "${YELLOW}Falha ao atualizar. Tentando clonar novamente...${NC}"
            cd ..
            rm -rf "$DOCKER_FILES_DIR"
            git clone https://github.com/arturgso/docker-files.git "$DOCKER_FILES_DIR"
        }
    else
        git clone https://github.com/arturgso/docker-files.git "$DOCKER_FILES_DIR"
    fi
    
    if [ $? -eq 0 ] && [ -d "$DOCKER_FILES_DIR" ]; then
        echo -e "${GREEN}Repositório clonado/atualizado com sucesso em $DOCKER_FILES_DIR${NC}"
        
        # Navegar para o diretório e executar o script
        cd "$DOCKER_FILES_DIR"
        
        if [ -f "start-docker.sh" ]; then
            echo -e "${BLUE}Executando start-docker.sh...${NC}"
            chmod +x start-docker.sh
            ./start-docker.sh
            echo -e "${GREEN}Script start-docker.sh executado com sucesso${NC}"
        else
            echo -e "${RED}Arquivo start-docker.sh não encontrado no repositório${NC}"
            echo -e "${YELLOW}Arquivos no repositório:${NC}"
            ls -la "$DOCKER_FILES_DIR"
        fi
    else
        echo -e "${RED}Falha ao clonar o repositório docker-files${NC}"
    fi
    
    echo -e "${GREEN}Configuração do docker-files concluída${NC}"
    pause
fi
