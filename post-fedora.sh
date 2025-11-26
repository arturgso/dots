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

# Funções de cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Sem cor

# Variáveis de progresso
CURRENT_STEP=0
TOTAL_STEPS=0
CURRENT_ITEM=""

# Função para atualizar o status
update_status() {
    local step=$1
    local total=$2
    local item=$3
    CURRENT_STEP=$step
    TOTAL_STEPS=$total
    CURRENT_ITEM=$item
    
    clear
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}    CONFIGURAÇÃO DO FEDORA      ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
}

# Função para mostrar rodapé com progresso
show_footer() {
    echo
    echo -e "${BLUE}================================${NC}"
    if [ $TOTAL_STEPS -gt 0 ]; then
        local percentage=$((CURRENT_STEP * 100 / TOTAL_STEPS))
        echo -e "${CYAN}Progresso: [${CURRENT_STEP}/${TOTAL_STEPS}] ${percentage}%${NC}"
    fi
    if [ -n "$CURRENT_ITEM" ]; then
        echo -e "${YELLOW}Processando: ${CURRENT_ITEM}${NC}"
    fi
    echo -e "${BLUE}================================${NC}"
    echo
}

# Função de delay
pause() {
    sleep 1
}

# Função para exibir menu
show_menu() {
    update_status 0 0 "Menu Principal"
    echo -e "1)  Atualizar sistema"
    echo -e "2)  Adicionar repositórios (Copr, RPM Fusion, VS Code)"
    echo -e "3)  Instalar grupos development-tools e multimedia"
    echo -e "4)  Instalar pacotes essenciais"
    echo -e "5)  Habilitar serviços essenciais"
    echo -e "6)  Instalar Nerd Fonts"
    echo -e "7)  Instalar Flatpaks"
    echo -e "8)  Criar links simbólicos para configs"
    echo -e "9)  Habilitar SDDM"
    echo -e "10) Configurar Borg Backup"
    echo -e "11) Instalar asdf e linguagens"
    echo -e "12) Configurar Docker (clonar e executar docker-files)"
    echo -e "13) ${GREEN}INSTALAR TUDO${NC}"
    echo -e "0)  Sair"
    show_footer
}

# Função para executar uma etapa específica
run_step() {
    local step_number=$1
    case $step_number in
        1) update_system ;;
        2) add_repositories ;;
        3) install_development_groups ;;
        4) install_essential_packages ;;
        5) enable_essential_services ;;
        6) install_nerd_fonts ;;
        7) install_flatpaks ;;
        8) create_symlinks ;;
        9) enable_sddm ;;
        10) configure_borg_backup ;;
        11) install_asdf ;;
        12) setup_docker_files ;;
        13) install_all ;;
        0) exit 0 ;;
        *) echo -e "${RED}Opção inválida${NC}"; pause ;;
    esac
}

# -------------------
# Funções para cada etapa
# -------------------

update_system() {
    update_status 1 1 "Atualizando sistema"
    echo -e "${BLUE}Atualizando sistema...${NC}"
    sudo dnf upgrade --refresh -y
    echo -e "${GREEN}Sistema atualizado com sucesso${NC}"
    pause
}

add_repositories() {
    update_status 1 4 "Adicionando repositórios"
    
    echo -e "${BLUE}Adicionando Copr e RPM Fusion...${NC}"
    sudo dnf copr enable solopasha/hyprland -y
    pause

    echo -e "${BLUE}Baixando pacotes RPM Fusion...${NC}"
    update_status 2 4 "Configurando RPM Fusion"
    curl -LO https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-43.noarch.rpm
    curl -LO https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-43.noarch.rpm
    sudo dnf install -y rpmfusion-free-release-43.noarch.rpm rpmfusion-nonfree-release-43.noarch.rpm
    rm -f rpmfusion-*-release-43.noarch.rpm
    pause

    echo -e "${BLUE}Configurando repositório do VS Code...${NC}"
    update_status 3 4 "Configurando VS Code"
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
    sudo dnf check-update

    update_status 4 4 "Finalizando configuração de repositórios"
    echo -e "${GREEN}Repositórios configurados com sucesso${NC}"
    pause
}

install_development_groups() {
    update_status 1 2 "Instalando grupos de desenvolvimento"
    echo -e "${BLUE}Instalando grupos padrão...${NC}"
    sudo dnf group install -y development-tools
    
    update_status 2 2 "Instalando grupo multimedia"
    sudo dnf group install -y multimedia
    
    echo -e "${GREEN}Grupos instalados com sucesso${NC}"
    pause
}

install_essential_packages() {
    local packages=(
      fuse-devel xdg-desktop-portal-wlr xdg-desktop-portal-gtk xdg-utils
      lz4-devel cliphist nmtui ImageMagick mint-themes-gtk3 mint-themes-gtk4
      openssl-devel zlib-devel libyaml-devel libffi-devel readline-devel bzip2-devel
      gdbm-devel sqlite-devel ncurses-devel make gcc autoconf automake libtool pkgconfig
      mscore-fonts-all blueman niri hyprlock hypridle hyprpicker hyprshot waybar fastfetch kitty code
      dunst neovim mousepad nwg-look rofi bat cloc git zsh
      bluez bluez-tools power-profiles-daemon flatpak borg sddm
      rsync wget curl nemo
    )
    
    update_status 1 1 "Instalando ${#packages[@]} pacotes essenciais"
    echo -e "${BLUE}Instalando ${#packages[@]} pacotes essenciais...${NC}"
    sudo dnf install -y "${packages[@]}"
    echo -e "${GREEN}Pacotes essenciais instalados com sucesso${NC}"
    pause
}

enable_essential_services() {
    local services=(bluetooth power-profiles-daemon)
    local total=${#services[@]}
    
    for i in "${!services[@]}"; do
        update_status $((i+1)) $total "Habilitando serviço: ${services[i]}"
        sudo systemctl enable "${services[i]}" --now
        echo -e "${GREEN}${services[i]} habilitado e iniciado${NC}"
    done
    pause
}

install_nerd_fonts() {
    update_status 1 3 "Instalando Nerd Fonts"
    echo -e "${BLUE}Instalando Nerd Fonts...${NC}"
    
    update_status 2 3 "Baixando Nerd Fonts"
    NERD_FONTS_URL="https://codeload.github.com/ryanoasis/nerd-fonts/zip/refs/heads/master"
    curl -L -o nerd-fonts.zip "$NERD_FONTS_URL"
    
    update_status 3 3 "Instalando fontes"
    unzip nerd-fonts.zip -d nerd-fonts
    (cd nerd-fonts && ./install.sh)
    rm -rf nerd-fonts nerd-fonts.zip
    
    echo -e "${GREEN}Nerd Fonts instaladas com sucesso${NC}"
    pause
}

install_flatpaks() {
    update_status 1 2 "Configurando Flatpak"
    echo -e "${BLUE}Instalando Flatpak e configurando Flathub...${NC}"
    sudo dnf install -y flatpak
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    pause

    local flatpaks=(
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

    local total=${#flatpaks[@]}
    
    for i in "${!flatpaks[@]}"; do
        update_status $((i+1)) $total "Instalando: ${flatpaks[i]}"
        flatpak install -y flathub "${flatpaks[i]}"
        echo -e "${GREEN}${flatpaks[i]} instalado${NC}"
    done
    
    echo -e "${GREEN}Todos os Flatpaks instalados com sucesso${NC}"
    pause
}

create_symlinks() {
    local folders=("niri" "waybar" "dunst" "lvim")
    local total=${#folders[@]}
    
    CONFIG_DIR="$HOME/.config"
    mkdir -p "$CONFIG_DIR"
    
    for i in "${!folders[@]}"; do
        update_status $((i+1)) $total "Criando link: ${folders[i]}"
        if [ -d "${folders[i]}" ]; then
            ln -sfn "$(pwd)/${folders[i]}" "$CONFIG_DIR/${folders[i]}"
            echo -e "${GREEN}Link simbólico criado para ${folders[i]}${NC}"
        fi
    done
    pause
}

enable_sddm() {
    update_status 1 1 "Habilitando SDDM"
    sudo systemctl enable sddm --now
    echo -e "${GREEN}SDDM habilitado e iniciado${NC}"
    pause
}

configure_borg_backup() {
    update_status 1 6 "Configurando Borg Backup"
    echo -e "${BLUE}Listando dispositivos disponíveis...${NC}"
    lsblk
    read -p "Digite o dispositivo a ser usado para o backup (ex: /dev/sda3): " BACKUP_DISK

    DISK_MOUNT_DIR="$HOME/backup_disk_mount"
    BORG_MOUNT_DIR="$HOME/borg_repo_mount"

    mkdir -p "$DISK_MOUNT_DIR" "$BORG_MOUNT_DIR"

    update_status 2 6 "Montando disco de backup"
    echo -e "${BLUE}Montando disco $BACKUP_DISK em $DISK_MOUNT_DIR...${NC}"
    sudo mount "$BACKUP_DISK" "$DISK_MOUNT_DIR" || {
        echo -e "${RED}Falha ao montar o dispositivo $BACKUP_DISK${NC}"
        pause
        return 1
    }

    BORG_REPO="$DISK_MOUNT_DIR/backup-fedora-mriya"
    if [ ! -d "$BORG_REPO" ]; then
        echo -e "${RED}Repositório Borg não encontrado em $BORG_REPO${NC}"
        sudo umount "$DISK_MOUNT_DIR"
        pause
        return 1
    fi

    echo -e "${GREEN}Repositório Borg encontrado: $BORG_REPO${NC}"

    read -s -p "Digite a senha de encriptação do Borg: " BORG_PASS
    echo
    export BORG_PASSPHRASE="$BORG_PASS"

    update_status 3 6 "Montando repositório Borg"
    echo -e "${BLUE}Montando repositório Borg em $BORG_MOUNT_DIR...${NC}"
    borg mount "$BORG_REPO" "$BORG_MOUNT_DIR" || {
        echo -e "${RED}Falha ao montar o repositório Borg${NC}"
        sudo umount "$DISK_MOUNT_DIR"
        unset BORG_PASSPHRASE
        pause
        return 1
    }

    echo -e "${GREEN}Repositório Borg montado com sucesso em $BORG_MOUNT_DIR${NC}"

    update_status 4 6 "Procurando backup mais recente"
    echo -e "${BLUE}Procurando backup mais recente...${NC}"
    LATEST_BACKUP=$(ls -lt "$BORG_MOUNT_DIR" | grep '^d' | head -1 | awk '{print $9}')
    
    if [ -z "$LATEST_BACKUP" ]; then
        echo -e "${RED}Nenhum backup encontrado no repositório${NC}"
        borg umount "$BORG_MOUNT_DIR"
        sudo umount "$DISK_MOUNT_DIR"
        unset BORG_PASSPHRASE
        pause
        return 1
    fi

    echo -e "${GREEN}Backup mais recente: $LATEST_BACKUP${NC}"

    BACKUP_BASE="$BORG_MOUNT_DIR/$LATEST_BACKUP/home/mriya"
    
    if [ ! -d "$BACKUP_BASE" ]; then
        echo -e "${RED}Estrutura de diretório não encontrada: $BACKUP_BASE${NC}"
        borg umount "$BORG_MOUNT_DIR"
        sudo umount "$DISK_MOUNT_DIR"
        unset BORG_PASSPHRASE
        pause
        return 1
    fi

    echo -e "${GREEN}Estrutura do backup encontrada em: $BACKUP_BASE${NC}"

    local items=(
        ".fonts" ".var" "Projetos" ".wakatime" ".ssh" "Cofre" 
        "Documents" "Pictures" "Postman" "Scripts" "Vault" "Videos" 
        ".oh-my-zsh" ".themes" ".icons" ".default.png" ".zshrc" 
        ".gitconfig" ".tool-versions" ".wakatime.cfg" ".config"
    )
    local total_items=${#items[@]}

    update_status 5 6 "Restaurando arquivos do backup"
    echo -e "${BLUE}Copiando dados do backup...${NC}"
    
    for i in "${!items[@]}"; do
        update_status 5 6 "Restaurando: ${items[i]}"
        if [ -e "$BACKUP_BASE/${items[i]}" ]; then
            echo -e "${GREEN}Copiando ${items[i]}...${NC}"
            rsync -av --progress --exclude='node_modules' "$BACKUP_BASE/${items[i]}" "$HOME/"
        else
            echo -e "${YELLOW}Aviso: ${items[i]} não encontrado no backup${NC}"
        fi
    done

    update_status 6 6 "Finalizando backup"
    echo -e "${BLUE}Desmontando repositório Borg...${NC}"
    borg umount "$BORG_MOUNT_DIR"
    
    echo -e "${BLUE}Desmontando disco...${NC}"
    sudo umount "$DISK_MOUNT_DIR"

    rmdir "$BORG_MOUNT_DIR"
    rmdir "$DISK_MOUNT_DIR"

    unset BORG_PASSPHRASE

    echo -e "${GREEN}Backup Borg restaurado com sucesso!${NC}"
    pause
}

install_asdf() {
    update_status 1 7 "Instalando asdf"
    
    update_status 2 7 "Configurando shell zsh"
    chsh -s $(which zsh) || {
        echo -e "${RED}Falha ao trocar o shell para zsh${NC}"
        pause
        return 1
    }

    update_status 3 7 "Baixando asdf"
    wget https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-linux-amd64.tar.gz -O /tmp/asdf.tar.gz || {
        echo -e "${RED}Falha ao baixar o asdf${NC}"
        pause
        return 1
    }

    update_status 4 7 "Instalando asdf"
    sudo tar -xzf /tmp/asdf.tar.gz -C /bin || {
        echo -e "${RED}Falha ao extrair o asdf${NC}"
        pause
        return 1
    }

    update_status 5 7 "Configurando plugins"
    mkdir -p "${ASDF_DATA_DIR:-$HOME/.asdf}/completions"
    asdf completion zsh > "${ASDF_DATA_DIR:-$HOME/.asdf}/completions/_asdf" || {
        echo -e "${RED}Falha ao configurar as completions do asdf${NC}"
        pause
        return 1
    }

    local plugins=("java" "nodejs" "golang" "yarn" "rust" "neovim" "ruby" "python")
    local total_plugins=${#plugins[@]}
    
    for i in "${!plugins[@]}"; do
        update_status 5 7 "Adicionando plugin: ${plugins[i]}"
        asdf plugin add "${plugins[i]}" || {
            echo -e "${RED}Falha ao adicionar o plugin ${plugins[i]}${NC}"
            pause
            return 1
        }
    done

    update_status 6 7 "Configurando versões"
    asdf set -u java temurin-25.0.0+36.0.LTS
    asdf set -u nodejs 22.15.0
    asdf set -u golang 1.25.1
    asdf set -u yarn 1.22.22
    asdf set -u rust stable
    asdf set -u neovim 0.10.0
    asdf set -u ruby 3.4.7
    asdf set -u python 3.11.14

    update_status 7 7 "Instalando linguagens"
    asdf install || {
        echo -e "${RED}Falha ao instalar as versões com asdf${NC}"
        pause
        return 1
    }

    echo -e "${GREEN}asdf e linguagens configuradas com sucesso!${NC}"
    pause
}

setup_docker_files() {
    update_status 1 4 "Configurando Docker"
    
    DOCKER_FILES_DIR="$HOME/Docker"
    
    if [ -d "$DOCKER_FILES_DIR" ]; then
        update_status 2 4 "Atualizando repositório Docker"
        echo -e "${YELLOW}O diretório $DOCKER_FILES_DIR já existe. Atualizando...${NC}"
        cd "$DOCKER_FILES_DIR"
        git pull origin main || {
            echo -e "${YELLOW}Falha ao atualizar. Tentando clonar novamente...${NC}"
            cd ..
            rm -rf "$DOCKER_FILES_DIR"
            git clone https://github.com/arturgso/docker-files.git "$DOCKER_FILES_DIR"
        }
    else
        update_status 2 4 "Clonando repositório Docker"
        git clone https://github.com/arturgso/docker-files.git "$DOCKER_FILES_DIR"
    fi
    
    if [ $? -eq 0 ] && [ -d "$DOCKER_FILES_DIR" ]; then
        echo -e "${GREEN}Repositório clonado/atualizado com sucesso em $DOCKER_FILES_DIR${NC}"
        
        cd "$DOCKER_FILES_DIR"
        
        if [ -f "start-docker.sh" ]; then
            update_status 3 4 "Executando script Docker"
            echo -e "${BLUE}Executando start-docker.sh...${NC}"
            chmod +x start-docker.sh
            ./start-docker.sh
            echo -e "${GREEN}Script start-docker.sh executado com sucesso${NC}"
        else
            echo -e "${RED}Arquivo start-docker.sh não encontrado no repositório${NC}"
        fi
    else
        echo -e "${RED}Falha ao clonar o repositório docker-files${NC}"
    fi
    
    update_status 4 4 "Finalizando configuração Docker"
    echo -e "${GREEN}Configuração do docker-files concluída${NC}"
    pause
}

install_all() {
    local total_steps=11
    local current_step=0
    
    echo -e "${GREEN}Iniciando instalação completa...${NC}"
    
    ((current_step++))
    update_status $current_step $total_steps "Atualizando sistema"
    update_system

    ((current_step++))
    update_status $current_step $total_steps "Adicionando repositórios"
    add_repositories

    ((current_step++))
    update_status $current_step $total_steps "Instalando grupos de desenvolvimento"
    install_development_groups

    ((current_step++))
    update_status $current_step $total_steps "Instalando pacotes essenciais"
    install_essential_packages

    ((current_step++))
    update_status $current_step $total_steps "Habilitando serviços essenciais"
    enable_essential_services

    ((current_step++))
    update_status $current_step $total_steps "Instalando Nerd Fonts"
    install_nerd_fonts

    ((current_step++))
    update_status $current_step $total_steps "Instalando Flatpaks"
    install_flatpaks

    ((current_step++))
    update_status $current_step $total_steps "Criando links simbólicos"
    create_symlinks

    ((current_step++))
    update_status $current_step $total_steps "Instalando asdf e linguagens"
    install_asdf

    ((current_step++))
    update_status $current_step $total_steps "Configurando Docker"
    setup_docker_files
    
    echo -e "${GREEN}Instalação completa concluída!${NC}"
    echo -e "${YELLOW}Nota: A configuração do Borg Backup precisa ser feita manualmente (opção 10)${NC}"
    pause
}

# -------------------
# Loop principal do menu
# -------------------
while true; do
    show_menu
    read -p "Selecione uma opção [0-13]: " choice
    run_step $choice
done
