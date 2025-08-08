#!/bin/bash

# =============================================================================
#                           🚀 ARCH DOTS INSTALLER
# =============================================================================
# Script de instalación unificado y modular para Arch Linux
# Autor: Mauro Infante (maurux01)
# Descripción: Configuración completa del entorno de usuario
# Componentes: Kitty, Neovim, Hyprland, Hyprlock, Tmux, SDDM, wallpapers, fuentes
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Variables globales
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
BACKUP_DIR="$HOME/.archriced-backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$HOME/.archriced-install.log"
CONFIG_DIR="$HOME/.config"
PICTURES_DIR="$HOME/Pictures"
# Nuevas variables para detección de distro / gestor de paquetes
PKG_MANAGER=""
IS_ARCH=false
IS_KALI=false

# Flags para instalación selectiva
INSTALL_ALL=true
INSTALL_KITTY=false
INSTALL_NVIM=false
INSTALL_HYPRLAND=false
INSTALL_HYPRLOCK=false
INSTALL_TMUX=false
INSTALL_SDDM=false
INSTALL_FONTS=false
INSTALL_WALLPAPERS=false
INSTALL_GRUB=false

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}Uso: $0 [OPCIONES]${NC}"
    echo ""
    echo "Opciones:"
    echo "  --all                    Instalar todos los componentes (predeterminado)"
    echo "  --kitty                  Instalar solo Kitty"
    echo "  --nvim                   Instalar solo Neovim"
    echo "  --hyprland              Instalar solo Hyprland"
    echo "  --hyprlock              Instalar solo Hyprlock"
    echo "  --tmux                  Instalar solo Tmux"
    echo "  --sddm                  Instalar solo SDDM"
    echo "  --fonts                 Instalar solo fuentes"
    echo "  --wallpapers            Instalar solo wallpapers"
    echo "  --grub                  Instalar solo GRUB"
    echo "  --help                  Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 --all                # Instalar todo"
    echo "  $0 --kitty --nvim       # Instalar solo Kitty y Neovim"
    echo "  $0 --fonts --wallpapers # Instalar solo fuentes y wallpapers"
}

# Procesar argumentos
process_args() {
    if [ $# -eq 0 ]; then
        return
    fi

    INSTALL_ALL=false
    
    while [ $# -gt 0 ]; do
        case $1 in
            --all)
                INSTALL_ALL=true
                shift
                ;;
            --kitty)
                INSTALL_KITTY=true
                shift
                ;;
            --nvim)
                INSTALL_NVIM=true
                shift
                ;;
            --hyprland)
                INSTALL_HYPRLAND=true
                shift
                ;;
            --hyprlock)
                INSTALL_HYPRLOCK=true
                shift
                ;;
            --tmux)
                INSTALL_TMUX=true
                shift
                ;;
            --sddm)
                INSTALL_SDDM=true
                shift
                ;;
            --fonts)
                INSTALL_FONTS=true
                shift
                ;;
            --wallpapers)
                INSTALL_WALLPAPERS=true
                shift
                ;;
            --grub)
                INSTALL_GRUB=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}Error: Opción desconocida $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
}

# Función para logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${BLUE} ═════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}║                 Achriced installer by maurux01             ║${NC}"
    echo -e "${BLUE} ═════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_section() {
    echo -e "${CYAN}› $1${NC}"
    log "SECTION: $1"
}

print_step() {
    echo -e "${YELLOW}  → $1${NC}"
    log "STEP: $1"
}

print_success() {
    echo -e "${GREEN}  ✓ $1${NC}"
    log "SUCCESS: $1"
}

print_error() {
    echo -e "${RED}  ✗ $1${NC}"
    log "ERROR: $1"
}

print_warning() {
    echo -e "${YELLOW}  ⚠ $1${NC}"
    log "WARNING: $1"
}

print_info() {
    echo -e "${BLUE}  ℹ $1${NC}"
    log "INFO: $1"
}

# =============================================================================
#                   🧭 DETECCIÓN DE DISTRO Y GESTOR DE PAQUETES
# =============================================================================

detect_distro() {
    print_section "Detectando distribución..."
    if [ -r /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            arch)
                IS_ARCH=true
                PKG_MANAGER="pacman"
                ;;
            kali)
                IS_KALI=true
                PKG_MANAGER="apt"
                ;;
            *)
                # fallback por si se ejecuta en derivados
                if echo "$ID_LIKE" | grep -qi "arch"; then
                    IS_ARCH=true
                    PKG_MANAGER="pacman"
                elif echo "$ID_LIKE" | grep -qi "debian"; then
                    PKG_MANAGER="apt"
                fi
                ;;
        esac
    fi

    if [ -z "$PKG_MANAGER" ]; then
        print_error "No se pudo detectar la distribución (Arch o Kali)."
        exit 1
    fi

    if $IS_ARCH; then
        print_success "Distribución detectada: Arch (pacman)"
    elif $IS_KALI; then
        print_success "Distribución detectada: Kali (apt)"
    else
        print_info "Distribución detectada (basada en Debian): $ID (apt)"
    fi
}

# Traducción de nombres de paquetes (genérico → apt) cuando es necesario
translate_pkg_name() {
    local name="$1"
    if [ "$PKG_MANAGER" = "apt" ]; then
        case "$name" in
            # terminal / utils
            fd) echo "fd-find" ; return ;;
            exa) echo "eza" ; return ;;
            nodejs) echo "nodejs" ; return ;;
            npm) echo "npm" ; return ;;
            python) echo "python3" ; return ;;
            python-pip) echo "python3-pip" ; return ;;
            go) echo "golang" ; return ;;
            jdk-openjdk) echo "default-jdk" ; return ;;
            ninja) echo "ninja-build" ; return ;;
            docker) echo "docker.io" ; return ;;
            docker-compose) echo "docker-compose" ; return ;;
            networkmanager) echo "network-manager" ; return ;;
            network-manager-applet) echo "network-manager-gnome" ; return ;;
            wl-copy) echo "wl-clipboard" ; return ;;
            # hyprland stack
            waybar-hyprland) echo "waybar" ; return ;;
            eww-wayland) echo "eww" ; return ;;
            hyperlock) echo "hyprlock" ; return ;;
            # fonts/icons
            nerd-fonts-jetbrains-mono) echo "fonts-jetbrains-mono" ; return ;;
            nerd-fonts-complete) echo "fonts-noto-color-emoji" ; return ;;
            papirus-icon-theme) echo "papirus-icon-theme" ; return ;;
            bibata-cursor-theme) echo "" ; return ;; # puede no existir en apt por defecto
            # security
            wireshark-qt) echo "wireshark-qt" ; return ;;
            netcat) echo "netcat-openbsd" ; return ;;
            networkmanager-openvpn) echo "network-manager-openvpn" ; return ;;
            networkmanager-vpnc) echo "network-manager-vpnc" ; return ;;
            networkmanager-pptp) echo "network-manager-pptp" ; return ;;
            networkmanager-l2tp) echo "network-manager-l2tp" ; return ;;
            libnotify) echo "libnotify-bin" ; return ;;
            gdm) echo "gdm3" ; return ;;
            pulseaudio-alsa) echo "pulseaudio" ; return ;;
            oss) echo "" ; return ;;
            brave) echo "" ; return ;;
            vscodium) echo "" ; return ;;
            swww) echo "" ; return ;;
            hyprpicker) echo "" ; return ;;
            waypaper) echo "" ; return ;;
            upscayl) echo "" ; return ;;
            heroic-games-launcher) echo "" ; return ;;
            steam) echo "steam" ; return ;;
            lutris) echo "lutris" ; return ;;
            *) echo "$name" ; return ;;
        esac
    else
        echo "$name" ; return
    fi
}

pm_is_installed() {
    local pkg="$1"
    if [ "$PKG_MANAGER" = "pacman" ]; then
        pacman -Q "$pkg" >/dev/null 2>&1
    else
        dpkg -s "$pkg" >/dev/null 2>&1
    fi
}

pm_update() {
    if [ "$PKG_MANAGER" = "pacman" ]; then
        sudo pacman -Sy --noconfirm
    else
        sudo apt update -y
    fi
}

pm_install_packages() {
    # instala una lista de paquetes, mapeando nombres cuando sea necesario
    local to_install=()
    for raw in "$@"; do
        local mapped
        mapped="$(translate_pkg_name "$raw")"
        # si mapped queda vacío, se omite el paquete en esta distro
        if [ -n "$mapped" ]; then
            to_install+=("$mapped")
        fi
    done

    if [ ${#to_install[@]} -eq 0 ]; then
        return 0
    fi

    if [ "$PKG_MANAGER" = "pacman" ]; then
        # instalar uno por uno para tolerar fallos puntuales
        for pkg in "${to_install[@]}"; do
            if ! pm_is_installed "$pkg"; then
                sudo pacman -S "$pkg" --noconfirm --needed || print_warning "Fallo instalando $pkg"
            fi
        done
    else
        for pkg in "${to_install[@]}"; do
            if ! pm_is_installed "$pkg"; then
                sudo apt install -y "$pkg" || print_warning "Fallo instalando $pkg"
            fi
        done
    fi
}

post_install_apt_adjustments() {
    if [ "$PKG_MANAGER" != "apt" ]; then return; fi
    # fd-find → fd
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
        sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd || true
    fi
    # eza → exa (compat)
    if command -v eza >/dev/null 2>&1 && ! command -v exa >/dev/null 2>&1; then
        sudo ln -sf "$(command -v eza)" /usr/local/bin/exa || true
    fi
}

# =============================================================================
#                           🔧 FUNCIONES DE VERIFICACIÓN
# =============================================================================

check_system() {
    print_section "Verificando sistema..."

    # Permitido: Arch y Kali (y derivados compatibles detectados)
    if ! $IS_ARCH && ! $IS_KALI && [ "$PKG_MANAGER" != "apt" ]; then
        print_error "Este script está diseñado para Arch o Kali (o derivados compatibles)."
        exit 1
    fi

    if [ "$EUID" -eq 0 ]; then
        print_error "No ejecutes este script como root."
        exit 1
    fi

    print_success "Sistema verificado."
}

check_dependencies() {
    print_section "Verificando dependencias básicas..."

    local missing_deps=()

    # comunes
    for dep in "git" "sudo"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done

    # gestor
    if [ "$PKG_MANAGER" = "pacman" ]; then
        command -v pacman >/dev/null 2>&1 || missing_deps+=("pacman")
    else
        command -v apt >/dev/null 2>&1 || missing_deps+=("apt")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Dependencias faltantes: ${missing_deps[*]}"
        print_info "Instala las dependencias básicas antes de continuar."
        exit 1
    fi

    print_success "Dependencias básicas verificadas."
}

create_backup() {
    if [ -d "$CONFIG_DIR" ] && [ "$(ls -A $CONFIG_DIR 2>/dev/null)" ]; then
        print_section "Creando respaldo de configuración existente..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$CONFIG_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
        print_success "Respaldo creado en: $BACKUP_DIR"
    fi
}

# =============================================================================
#                           📦 FUNCIONES DE INSTALACIÓN BASE
# =============================================================================

update_system() {
    print_section "Actualizando sistema..."
    pm_update
    print_success "Base de datos actualizada."
}

install_aur_helper() {
    print_section "Instalando AUR helper..."

    # Solo aplica en Arch
    if [ "$PKG_MANAGER" != "pacman" ]; then
        print_info "Sistema no-Arch detectado, se omite AUR."
        return
    fi

    if command -v yay >/dev/null 2>&1; then
        print_success "yay ya está instalado."
        return
    fi

    print_step "Instalando yay..."
    cd /tmp
    git clone --depth 1 https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm --skippgpcheck
    cd "$SCRIPT_DIR"
    rm -rf /tmp/yay

    print_success "AUR helper instalado."
}

install_compiler() {
    print_section "Instalando compilador C..."

    print_step "Verificando compilador existente..."
    if command -v gcc >/dev/null 2>&1; then
        print_success "gcc ya está instalado: $(gcc --version | head -1)"
        return
    elif command -v clang >/dev/null 2>&1; then
        print_success "clang ya está instalado: $(clang --version | head -1)"
        return
    fi

    if [ "$PKG_MANAGER" = "pacman" ]; then
        print_step "Instalando base-devel (incluye gcc)..."
        pm_install_packages base-devel
    else
        print_step "Instalando build-essential (incluye gcc)..."
        pm_install_packages build-essential
    fi

    print_step "Verificando instalación..."
    if command -v gcc >/dev/null 2>&1; then
        print_success "Compilador C instalado: $(gcc --version | head -1)"
    else
        print_error "Falló al instalar compilador C"
    fi
}

# =============================================================================
#                           🐱 CONFIGURACIÓN DE KITTY
# =============================================================================

install_kitty() {
    print_section "Instalando y configurando Kitty..."

    # Verificar si kitty ya está instalado
    if ! command -v kitty >/dev/null 2>&1; then
        print_step "Instalando Kitty..."
        pm_install_packages kitty
    else
        print_success "Kitty ya está instalado."
    fi

    # Crear directorios de configuración
    print_step "Creando directorios de configuración..."
    mkdir -p "$CONFIG_DIR/kitty"
    mkdir -p "$CONFIG_DIR/kitty/kitten-scripts"

    # Copiar configuración de Kitty
    if [ -f "$DOTFILES_DIR/kitty/kitty.conf" ]; then
        print_step "Copiando configuración de Kitty..."
        cp "$DOTFILES_DIR/kitty/kitty.conf" "$CONFIG_DIR/kitty/"
        print_success "Configuración de Kitty copiada."
    else
        print_warning "No se encontró kitty.conf en dotfiles."
    fi

    # Copiar scripts de kitten
    if [ -d "$DOTFILES_DIR/kitty/kitten-scripts" ]; then
        print_step "Copiando scripts de kitten..."
        cp -r "$DOTFILES_DIR/kitty/kitten-scripts"/* "$CONFIG_DIR/kitty/kitten-scripts/"
        chmod +x "$CONFIG_DIR/kitty/kitten-scripts"/*.sh
        print_success "Scripts de kitten copiados y permisos configurados."
    else
        print_warning "No se encontró la carpeta kitten-scripts en dotfiles."
    fi

    # Copiar theme-switcher si existe
    if [ -f "$DOTFILES_DIR/kitty/theme-switcher.sh" ]; then
        print_step "Copiando theme-switcher..."
        cp "$DOTFILES_DIR/kitty/theme-switcher.sh" "$CONFIG_DIR/kitty/"
        chmod +x "$CONFIG_DIR/kitty/theme-switcher.sh"
        print_success "Theme-switcher copiado."
    fi

    print_success "Kitty configurado exitosamente."
}

# =============================================================================
#                           📝 CONFIGURACIÓN DE NEOVIM
# =============================================================================

install_nvim() {
    print_section "Instalando y configurando Neovim..."

    # Verificar si neovim ya está instalado
    if ! command -v nvim >/dev/null 2>&1; then
        print_step "Instalando Neovim..."
        pm_install_packages neovim
    else
        print_success "Neovim ya está instalado."
    fi

    # Crear directorios de configuración
    print_step "Creando directorios de configuración..."
    mkdir -p "$CONFIG_DIR/nvim"
    mkdir -p "$CONFIG_DIR/nvim/lua"
    mkdir -p "$CONFIG_DIR/nvim/lua/config"
    mkdir -p "$CONFIG_DIR/nvim/lua/plugins"

    # Copiar configuración de Neovim
    if [ -d "$DOTFILES_DIR/nvim" ]; then
        print_step "Copiando configuración de Neovim..."
        cp -r "$DOTFILES_DIR/nvim"/* "$CONFIG_DIR/nvim/"
        print_success "Configuración de Neovim copiada."
    else
        print_warning "No se encontró la carpeta nvim en dotfiles."
    fi

    # Instalar plugins de Neovim
    print_step "Instalando plugins de Neovim..."
    nvim --headless -c "Lazy! sync" -c "qa" 2>/dev/null || print_warning "No se pudieron instalar los plugins automáticamente."

    print_success "Neovim configurado exitosamente."
}

# =============================================================================
#                           🖥️ CONFIGURACIÓN DE HYPRLAND
# =============================================================================

install_hyprland() {
    print_section "Instalando y configurando Hyprland..."

    # Verificar si hyprland ya está instalado
    if ! command -v Hyprland >/dev/null 2>&1 && ! command -v hyprland >/dev/null 2>&1; then
        print_step "Instalando Hyprland..."
        pm_install_packages hyprland
    else
        print_success "Hyprland ya está instalado."
    fi

    # Crear directorios de configuración
    print_step "Creando directorios de configuración..."
    mkdir -p "$CONFIG_DIR/hypr"
    mkdir -p "$CONFIG_DIR/hypr/assets"
    mkdir -p "$CONFIG_DIR/hypr/shaders"
    mkdir -p "$CONFIG_DIR/hypr/themes"
    mkdir -p "$CONFIG_DIR/hypr/animations"
    mkdir -p "$CONFIG_DIR/hypr/workflows"

    # Copiar configuración de Hyprland
    if [ -d "$DOTFILES_DIR/hypr" ]; then
        print_step "Copiando configuración de Hyprland..."
        cp -r "$DOTFILES_DIR/hypr"/* "$CONFIG_DIR/hypr/"
        print_success "Configuración de Hyprland copiada."
    else
        print_warning "No se encontró la carpeta hypr en dotfiles."
    fi

    print_success "Hyprland configurado exitosamente."
}

# =============================================================================
#                           🔒 CONFIGURACIÓN DE HYPRLOCK
# =============================================================================

install_hyprlock() {
    print_section "Instalando y configurando Hyprlock Enhanced..."

    # Verificar si hyprlock ya está instalado
    if ! command -v hyprlock >/dev/null 2>&1; then
        print_step "Instalando Hyprlock..."
        pm_install_packages hyprlock
    else
        print_success "Hyprlock ya está instalado."
    fi

    # Usar el script de instalación mejorado
    if [ -f "$DOTFILES_DIR/scripts/install-hyprlock-enhanced.sh" ]; then
        print_step "Ejecutando instalación mejorada de Hyprlock..."
        "$DOTFILES_DIR/scripts/install-hyprlock-enhanced.sh"
        print_success "Hyprlock Enhanced instalado exitosamente."
    else
        print_warning "Script de instalación mejorada no encontrado, usando instalación básica..."
        
        # Crear directorios de configuración
        print_step "Creando directorios de configuración..."
        mkdir -p "$CONFIG_DIR/hyprlock"
        mkdir -p "$CONFIG_DIR/hyprlock/assets"
        mkdir -p "$CONFIG_DIR/hyprlock/wallpapers"

        # Copiar configuración de Hyprlock
        if [ -d "$DOTFILES_DIR/hyprlock" ]; then
            print_step "Copiando configuración de Hyprlock..."
            cp -r "$DOTFILES_DIR/hyprlock"/* "$CONFIG_DIR/hyprlock/"
            print_success "Configuración de Hyprlock copiada."
        else
            print_warning "No se encontró la carpeta hyprlock en dotfiles."
        fi

        # Copiar scripts de cambio de fondo
        if [ -f "$DOTFILES_DIR/scripts/hyprlock-background.sh" ]; then
            print_step "Instalando script de cambio de fondo..."
            cp "$DOTFILES_DIR/scripts/hyprlock-background.sh" "$CONFIG_DIR/hyprlock/"
            chmod +x "$CONFIG_DIR/hyprlock/hyprlock-background.sh"
            print_success "Script de cambio de fondo instalado."
        fi

        if [ -f "$DOTFILES_DIR/scripts/hyprlock-wallpaper-sync.sh" ]; then
            print_step "Instalando script de sincronización de wallpaper..."
            cp "$DOTFILES_DIR/scripts/hyprlock-wallpaper-sync.sh" "$CONFIG_DIR/hyprlock/"
            chmod +x "$CONFIG_DIR/hyprlock/hyprlock-wallpaper-sync.sh"
            print_success "Script de sincronización instalado."
        fi

        print_success "Hyprlock configurado exitosamente."
    fi
}

# =============================================================================
#                           🎭 CONFIGURACIÓN DE TMUX
# =============================================================================

install_tmux() {
    print_section "Instalando y configurando Tmux..."

    # Verificar si tmux ya está instalado
    if ! command -v tmux >/dev/null 2>&1; then
        print_step "Instalando Tmux..."
        pm_install_packages tmux
    else
        print_success "Tmux ya está instalado."
    fi

    # Crear directorios de configuración
    print_step "Creando directorios de configuración..."
    mkdir -p "$HOME/.tmux"
    mkdir -p "$HOME/.tmux/plugins"
    mkdir -p "$HOME/.tmux/scripts"

    # Instalar TPM si no está instalado
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        print_step "Instalando TPM (Tmux Plugin Manager)..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        print_success "TPM instalado."
    else
        print_success "TPM ya está instalado."
    fi

    # Copiar configuración de Tmux
    if [ -d "$DOTFILES_DIR/tmux" ]; then
        print_step "Copiando configuración de Tmux..."
        if [ -f "$DOTFILES_DIR/tmux/tmux.conf" ]; then
            cp "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
        fi
        if [ -d "$DOTFILES_DIR/tmux/plugins" ]; then
            cp -r "$DOTFILES_DIR/tmux/plugins"/* "$HOME/.tmux/plugins/"
        fi
        if [ -d "$DOTFILES_DIR/tmux/scripts" ]; then
            cp -r "$DOTFILES_DIR/tmux/scripts"/* "$HOME/.tmux/scripts/"
            chmod +x "$HOME/.tmux/scripts/*.sh"
        fi
        print_success "Configuración de Tmux copiada."
    else
        print_warning "No se encontró la carpeta tmux en dotfiles."
        print_step "Creando configuración básica..."
        # Crear configuración básica si no existe
        cat > "$HOME/.tmux.conf" << 'EOF'
# =============================================================================
#                           🎭 TMUX CONFIGURATION
# =============================================================================
# Modern Tmux configuration with TPM plugin management
# =============================================================================

# Plugin manager
set -g @plugintmux-plugins/tpmset -g @plugin tmux-plugins/tmux-sensible'

# Status bar plugins
set -g @plugin tmux-plugins/tmux-batteryset -g @plugin tmux-plugins/tmux-cpuset -g @plugin tmux-plugins/tmux-online-status'

# Navigation plugins
set -g @plugin tmux-plugins/tmux-yankset -g @plugin tmux-plugins/tmux-pain-control'

# Theme
set -g @plugin tmux-plugins/tmux-resurrectset -g @plugin tmux-plugins/tmux-continuum'

# Initialize TPM
EOF
        print_success "Configuración básica de Tmux creada."
    fi

    print_info "Para instalar plugins: tmux new-session, luego Ctrl+a + I"
    print_info "Para aplicar configuración: tmux source-file ~/.tmux.conf"
}

# =============================================================================
#                           🖼️ CONFIGURACIÓN DE SDDM
# =============================================================================

install_sddm() {
    print_section "Instalando y configurando SDDM..."

    # Verificar si sddm ya está instalado
    if ! command -v sddm >/dev/null 2>&1; then
        print_step "Instalando SDDM..."
        pm_install_packages sddm
    else
        print_success "SDDM ya está instalado."
    fi

    # Habilitar SDDM
    print_step "Habilitando SDDM..."
    sudo systemctl enable sddm

    # Crear directorios de configuración
    print_step "Creando directorios de configuración..."
    sudo mkdir -p /etc/sddm.conf.d
    sudo mkdir -p /usr/share/sddm/themes

    # Copiar configuración de SDDM
    if [ -d "$DOTFILES_DIR/sddm" ]; then
        print_step "Copiando configuración de SDDM..."
        sudo cp -r "$DOTFILES_DIR/sddm"/* /etc/sddm.conf.d/ 2>/dev/null || true
        print_success "Configuración de SDDM copiada."
    else
        print_warning "No se encontró la carpeta sddm en dotfiles."
    fi

    print_success "SDDM configurado exitosamente."
}

# =============================================================================
#                           🔤 CONFIGURACIÓN DE FUENTES
# =============================================================================

install_fonts() {
    print_section "Instalando y configurando fuentes..."

    # Instalar fuentes Nerd Font (o equivalentes en apt)
    print_step "Instalando fuentes Nerd Font..."
    pm_install_packages nerd-fonts-jetbrains-mono nerd-fonts-complete

    # Crear directorios de fuentes
    print_step "Creando directorios de fuentes..."
    mkdir -p "$HOME/.local/share/fonts"
    mkdir -p "$HOME/.fonts"

    # Copiar fuentes personalizadas
    if [ -d "$DOTFILES_DIR/fonts" ]; then
        print_step "Copiando fuentes personalizadas..."
        cp -r "$DOTFILES_DIR/fonts"/* "$HOME/.local/share/fonts/"
        fc-cache -fv
        print_success "Fuentes personalizadas copiadas y cache actualizado."
    else
        print_warning "No se encontró la carpeta fonts en dotfiles."
    fi

    print_success "Fuentes configuradas exitosamente."
}

# =============================================================================
#                           🖼️ CONFIGURACIÓN DE WALLPAPERS
# =============================================================================

install_wallpapers() {
    print_section "Instalando wallpapers..."

    # Crear directorio de wallpapers
    print_step "Creando directorio de wallpapers..."
    mkdir -p "$PICTURES_DIR/wallpapers"

    # Copiar wallpapers
    if [ -d "$DOTFILES_DIR/wallpapers" ]; then
        print_step "Copiando wallpapers..."
        cp -r "$DOTFILES_DIR/wallpapers"/* "$PICTURES_DIR/wallpapers/"
        print_success "Wallpapers copiados."
    else
        print_warning "No se encontró la carpeta wallpapers en dotfiles."
    fi
}

# =============================================================================
#                           🔧 CONFIGURACIONES ADICIONALES
# =============================================================================

install_core_packages() {
    print_section "Instalando paquetes core..."

    local terminal_packages=("fish" "starship" "zoxide")
    local system_packages=("bat" "fd" "ripgrep" "fzf" "btop" "exa" "htop" "ncdu" "iotop" "nvtop")
    local media_packages=("pavucontrol" "blueman" "networkmanager" "network-manager-applet" "speedtest-cli" "nmtui" "playerctl" "pamixer" "brightnessctl")
    local dev_packages=("nodejs" "npm" "python" "python-pip" "rust" "go" "jdk-openjdk" "gcc" "cmake" "ninja" "meson" "valgrind" "gdb")
    local docker_packages=("docker" "docker-compose" "podman" "buildah" "skopeo")
    local image_packages=("imagemagick" "ffmpeg" "v4l-utils" "pulseaudio-alsa" "libpng" "libjpeg-turbo" "libwebp" "librsvg" "giflib")
    local capture_packages=("flameshot" "grim" "slurp" "spectacle" "maim" "xclip" "wl-screenshot" "wl-copy" "hyprpicker" "wf-recorder")
    local utility_packages=("lazygit" "lazydocker" "yazi" "feh" "imv" "pcmanfm" "dolphin" "korganizer" "pamac" "polybar" "qalculate-gtk" "gnome-clocks" "w3m" "w3m-img")
    local media_player_packages=("mpv" "vlc" "cava" "oss" "discord" "telegram-desktop" "mpd" "mpc")
    local creation_packages=("obs-studio" "krita" "gimp" "inkscape" "lmms" "pixelorama" "upscayl" "scribus")
    local clipboard_packages=("cliphist" "copyq" "libreoffice" "brave" "vscodium")
    local font_packages=("nerd-fonts-complete" "noto-fonts" "noto-fonts-emoji" "ttf-dejavu" "ttf-liberation" "ttf-jetbrains-mono" "papirus-icon-theme" "bibata-cursor-theme")
    local gaming_packages=("steam" "lutris" "wine" "gamemode" "heroic-games-launcher" "mgba" "snes9x" "fceux")
    local additional_packages=("jq" "curl" "gdm" "atuin" "just" "httpie" "swappy" "swaylock-effects" "hyperlock" "waybar-hyprland" "eww-wayland" "wofi" "mako" "waypaper" "libnotify" "bc")
    local security_packages=("ufw" "wireguard-tools" "openvpn" "networkmanager-openvpn" "networkmanager-vpnc" "networkmanager-pptp" "networkmanager-l2tp" "nmap" "wireshark-qt" "tcpdump" "netcat" "nethogs" "iftop" "fail2ban" "rkhunter" "clamav" "clamav-unofficial-sigs")

    print_step "Instalando paquetes del sistema..."
    pm_install_packages "${terminal_packages[@]}" "${system_packages[@]}" "${media_packages[@]}" "${dev_packages[@]}" "${utility_packages[@]}" "${additional_packages[@]}" "${security_packages[@]}" "${docker_packages[@]}" "${image_packages[@]}" "${media_player_packages[@]}" "${creation_packages[@]}" "${clipboard_packages[@]}" "${font_packages[@]}" "${gaming_packages[@]}"

    print_step "Instalando paquetes oficiales adicionales..."
    local extra_official_packages=(
        "xournalpp" "kubectl" "remmina" "bitwarden" "beekeeper-studio" "zeal" "nano" "figlet" "toilet" "fortune-mod" "cava" "enkins" "lm-studio" "missioncenter" "ora" "parrot-terminal"
    )
    pm_install_packages "${extra_official_packages[@]}"

    print_step "Instalando paquetes AUR adicionales..."
    local extra_aur_packages=(
        "frog" "foliate" "ferdium" "zen" "cavalier" "helix" "cacher" "qownnotes" "enkit" "pulsar-bin" "spotify"
    )
    if [ "$PKG_MANAGER" = "pacman" ] && command -v yay >/dev/null 2>&1; then
        yay -S "${extra_aur_packages[@]}" --noconfirm --needed || print_warning "Algunos paquetes AUR adicionales fallaron"
    else
        print_warning "AUR no disponible en esta distro, se omiten paquetes AUR adicionales"
    fi

    # Paquetes adicionales solicitados por el usuario
    print_step "Instalando paquetes extra del usuario..."
    local user_extra_packages=(
        "hyprland" "waybar" "eww" "swww" "mako" "swaylock" "grim" "slurp" "xdg-desktop-portal-hyprland" "xdg-desktop-portal-gtk"
    )
    pm_install_packages "${user_extra_packages[@]}"

    print_success "Paquetes core instalados."
}

install_aur_packages() {
    print_section "Instalando paquetes AUR..."
    if [ "$PKG_MANAGER" != "pacman" ]; then
        print_info "AUR no disponible en esta distro, omitiendo."
        return
    fi
    local aur_packages=(
        hyperlockoss" "nerd-fonts-complete oic-games-launcher       pixelorama" upscayl"appflowy"figma-linux"zeal rello"betterdiscord" opentabletdriver" rmpc" spotify-cligemini-cli" "ytui-music    ferdium-bin" "cacher" beekeeper-studio qownnotes enkit" "pulsar-bin       frog" foliatezen"cavalier" helix )

    print_step "Instalando paquetes AUR..."
    for pkg in "${aur_packages[@]}"; do
        print_step "Instalando $pkg..."
        yay -S $pkg --noconfirm --needed || print_warning "$pkg no se pudo instalar"
    done

    print_success "Paquetes AUR instalados."
}

configure_fish_shell() {
    print_section "Configurando Fish shell..."

    # Verificar si fish está instalado
    if ! command -v fish >/dev/null 2>&1; then
        print_step "Instalando Fish..."
        pm_install_packages fish
    fi

    # Copiar configuración de Fish
    if [ -f "$DOTFILES_DIR/fish/config.fish" ]; then
        print_step "Copiando configuración de Fish..."
        mkdir -p "$CONFIG_DIR/fish"
        cp "$DOTFILES_DIR/fish/config.fish" "$CONFIG_DIR/fish/"
        print_success "Configuración de Fish copiada."
    fi

    # Cambiar shell por defecto a fish
    if [ "$SHELL" != "/usr/bin/fish" ]; then
        print_step "Cambiando shell por defecto a Fish..."
        chsh -s /usr/bin/fish
        print_success "Shell cambiado a Fish."
    fi

    print_success "Fish shell configurado exitosamente."
}

configure_system() {
    print_section "Configurando sistema..."

    # Configurar permisos de audio
    print_step "Configurando permisos de audio..."
    sudo usermod -a -G audio "$USER"

    # Configurar NetworkManager
    print_step "Configurando NetworkManager..."
    sudo systemctl enable NetworkManager || true

    print_success "Sistema configurado exitosamente."
}

# =============================================================================
#                           ✅ VERIFICACIÓN FINAL
# =============================================================================

verify_installation() {
    print_section "Verificando instalación..."

    local errors=0
    local components=()

    # Verificar componentes instalados
    if $INSTALL_KITTY || $INSTALL_ALL; then
        if [ -f "$CONFIG_DIR/kitty/kitty.conf" ]; then
            print_success "✓ Kitty configurado"
            components+=("Kitty")
        else
            print_error "✗ Kitty no configurado"
            ((errors++))
        fi
    fi

    if $INSTALL_NVIM || $INSTALL_ALL; then
        if [ -f "$CONFIG_DIR/nvim/init.lua" ]; then
            print_success "✓ Neovim configurado"
            components+=("Neovim")
        else
            print_error "✗ Neovim no configurado"
            ((errors++))
        fi
    fi

    if $INSTALL_HYPRLAND || $INSTALL_ALL; then
        if [ -d "$CONFIG_DIR/hypr" ]; then
            print_success "✓ Hyprland configurado"
            components+=("Hyprland")
        else
            print_error "✗ Hyprland no configurado"
            ((errors++))
        fi
    fi

    if $INSTALL_TMUX || $INSTALL_ALL; then
        if [ -f "$HOME/.tmux.conf" ]; then
            print_success "✓ Tmux configurado"
            components+=("Tmux")
        else
            print_error "✗ Tmux no configurado"
            ((errors++))
        fi
    fi

    # Resultado
    if [ $errors -gt 0 ]; then
        print_warning "Se detectaron $errors problemas en la verificación. Revisa los pasos previos."
    else
        print_success "Todos los componentes verificados correctamente."
    fi
}

# =============================================================================
#                           🚀 FUNCIÓN PRINCIPAL
# =============================================================================

main() {
    print_header
    
    # Procesar argumentos
    process_args "$@"
    
    # Detección de distro
    detect_distro
    
    # Verificaciones iniciales
    check_system
    check_dependencies
    
    # Crear respaldo si es necesario
    create_backup
    
    # Instalación base
    update_system
    install_aur_helper
    install_compiler
    install_core_packages
    install_aur_packages

    # Ajustes específicos de apt (si aplica)
    post_install_apt_adjustments
    
    # Crear carpetas de imágenes e íconos si no existen
    echo "✔️ Creando carpeta wallpapers..."
    mkdir -p "$HOME/Pictures/wallpapers"
    echo "✔️ Creando carpeta icons..."
    mkdir -p "$HOME/Pictures/icons"

    # Copiar íconos desde dotfiles/icons a ~/Pictures/icons (sobrescribe todo)
    if [ -d "$DOTFILES_DIR/icons" ]; then
        echo "📁 Copiando íconos..."
        cp -rf "$DOTFILES_DIR/icons/"* "$HOME/Pictures/icons/"
        print_success "✅ Archivos de íconos reemplazados correctamente en $HOME/Pictures/icons"
    else
        print_warning "No se encontró la carpeta de íconos en $DOTFILES_DIR/icons."
    fi

    # Copiar íconos desde dotfiles/neofetch/Icons a ~/Pictures/icons (sobrescribe todo)
    if [ -d "$DOTFILES_DIR/neofetch/Icons" ]; then
        echo "📁 Copiando íconos de Neofetch..."
        cp -rf "$DOTFILES_DIR/neofetch/Icons/"* "$HOME/Pictures/icons/"
        print_success "✅ Archivos de íconos de Neofetch reemplazados correctamente en $HOME/Pictures/icons"
    else
        print_warning "No se encontró la carpeta de íconos de Neofetch en $DOTFILES_DIR/neofetch/Icons."
    fi

    # Copiar wallpapers desde dotfiles/wallpapers a ~/Pictures/wallpapers (sobrescribe todo)
    if [ -d "$DOTFILES_DIR/wallpapers" ]; then
        echo "📁 Copiando wallpapers..."
        cp -rf "$DOTFILES_DIR/wallpapers/"* "$HOME/Pictures/wallpapers/"
        print_success "✅ Archivos de wallpapers reemplazados correctamente en $HOME/Pictures/wallpapers"
    else
        print_warning "No se encontró la carpeta de wallpapers en $DOTFILES_DIR/wallpapers."
    fi

    # Dar permisos de ejecución al script de fetch con icono
    chmod +x dotfiles/scripts/fetch_with_icon.sh

    # Instalación de componentes específicos
    if $INSTALL_KITTY || $INSTALL_ALL; then
        install_kitty
    fi
    
    if $INSTALL_NVIM || $INSTALL_ALL; then
        install_nvim
    fi
    
    if $INSTALL_HYPRLAND || $INSTALL_ALL; then
        install_hyprland
    fi
    
    if $INSTALL_HYPRLOCK || $INSTALL_ALL; then
        install_hyprlock
    fi
    
    if $INSTALL_TMUX || $INSTALL_ALL; then
        install_tmux
    fi
    
    if $INSTALL_SDDM || $INSTALL_ALL; then
        install_sddm
    fi
    
    if $INSTALL_FONTS || $INSTALL_ALL; then
        install_fonts
    fi
    
    if $INSTALL_WALLPAPERS || $INSTALL_ALL; then
        install_wallpapers
    fi
    
    # Instalar GRUB (solo si se solicita explícitamente o en instalación completa)
    if $INSTALL_GRUB || $INSTALL_ALL; then
        install_grub
    fi
    
    # Configuraciones adicionales
    configure_fish_shell
    configure_system
    
    # Verificación final
    verify_installation
    show_final_info
    setup_hyprland_bars
}

# Ejecutar función principal
main "$@"


# =============================================================================
#                           🧩 FUNCIONES AUXILIARES FINALES
# =============================================================================

install_grub() {
    print_section "Instalando y configurando GRUB..."

    if [ "$PKG_MANAGER" = "pacman" ]; then
        pm_install_packages grub efibootmgr
    else
        # En Debian/Kali el paquete suele ser grub-efi-amd64 (en EFI) y efibootmgr
        pm_install_packages grub-efi-amd64 efibootmgr
    fi

    if [ -d /sys/firmware/efi ]; then
        print_info "Sistema EFI detectado. Ejecuta manualmente grub-install con el disco correcto si es necesario."
        print_info "Ejemplo: sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB"
    else
        print_info "Sistema BIOS/Legacy detectado. Ejecuta manualmente grub-install /dev/sdX"
    fi

    print_info "Luego actualiza la configuración: sudo update-grub (Debian/Kali) o sudo grub-mkconfig -o /boot/grub/grub.cfg (Arch)."
    print_success "GRUB instalado (se requiere configuración/instalación en el disco manual si aplica)."
}

show_final_info() {
    print_section "Información final"
    print_info "Reinicia la sesión para aplicar cambios de shell/daemon."
    print_info "Neovim plugins: nvim --headless -c 'Lazy! sync' -c 'qa'"
    print_info "Wayland stack: asegúrate de tener configurado Hyprland como sesión."
}

setup_hyprland_bars() {
    print_section "Ajustes de barras (Waybar/EWW)"
    print_info "Si usas Hyprland, Waybar/EWW pueden iniciarse desde tu config de sesión."
}
